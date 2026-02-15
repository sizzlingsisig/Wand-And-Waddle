# Flappy Bai: Official Design Notes

## 1. High-Level Architecture

Flappy Bai is built using a **Decoupled Component Architecture**. To avoid "Spaghetti Code" (and secure a 1.0 grade), the game logic is split into independent systems that communicate via a central **Signal Bus**.

### Core Design Patterns

- **Finite State Machine (FSM)**: Orchestrates game flow (Calibration → Playing → Game Over).
- **Observer Pattern (Signals)**: Connects the Voice Engine to the Physics Engine without direct dependencies.
- **Data-Driven Design (Custom Resources)**: Stores all "magic numbers" (gravity, jump strength, voice sensitivity) in an editable file.
- **Singleton (Autoload)**: Manages global events and score persistence.

## 2. Finite State Machine (FSM)

The game exists in one of four distinct states. This prevents input from being processed at the wrong time.

| State | Responsibility | Trigger to Next State |
|-------|----------------|----------------------|
| **CALIBRATE** | Displays mic meter; sets voice threshold. | Successful "Yawa" detection. |
| **START** | Bird is idle; background is moving. | Player vocal trigger. |
| **PLAYING** | Active physics; pipes spawning. | Collision with pipe/ground. |
| **GAMEOVER** | Stops movement; displays "Pildi" screen. | Press "Retry" button. |

## 3. The "Yawa" Voice Engine

Instead of checking for a specific word meaning (which is CPU heavy), we use **Peak Amplitude Detection** combined with a **Syllable Cooldown**.

### Implementation Logic:

1. **Audio Capture**: Samples the Voice audio bus via `AudioEffectCapture`.
2. **Thresholding**: Compares the current peak decibels (dB) against the `threshold_db` stored in the Custom Resource.
3. **Signal Emission**: If dB > threshold, the `VoiceProcessor` emits a `yawa_detected` signal to the `SignalBus`.
4. **Anti-Spam**: A 0.2s timer prevents a single long shout from triggering multiple jumps.

## 4. Physics & "Feel"

The Bird (`CharacterBody2D`) is purely reactive. It does not look for input; it only listens for signals.

- **Upward Impulse**: On `yawa_detected`, `velocity.y` is set to `-jump_impulse`.
- **Dynamic Tilt**: The sprite's rotation is calculated by remapping the `velocity.y` range to a -45° to 90° angle range.
- **Strong Typing**: All physics calculations use explicit `float` typing to ensure consistency and prevent performance drops.

## 5. Scene Composition

To maintain "Separation of Concerns," the project is split into these scenes:

- **Main.tscn**: Holds the FSM and coordinates the other scenes.
- **Player.tscn**: Physics, Sprite, and Animation logic.
- **VoiceProcessor.tscn**: Dedicated node for microphone sampling.
- **PipePair.tscn**: Obstacle logic and Area2D for scoring.
- **HUD.tscn**: CanvasLayer containing the mic meter and score labels.

## 6. Implementation Phases

### Phase 1: Structural Setup

**Goal**: Establish the project's communication backbone and data storage.

#### 1.1 Create the Signal Bus
- File: `res://autoload/GameEvents.gd`
- Add to Project Settings → Autoload as `GameEvents`
- Define signals: `yawa_detected()`, `bird_died()`, `score_changed(new_score: int)`, `game_state_changed(new_state: String)`
- Test: Emit signal from test script, verify console output

#### 1.2 Define the Custom Resource
- File: `res://resources/VocalStats.gd` (extends `Resource`)
- Add exports: `threshold_db`, `jump_impulse`, `gravity`, `cooldown_time`
- Create instance: `res://resources/default_vocal_stats.tres`
- Test: Load resource and print values

#### 1.3 Setup Audio Bus
- Create "Voice" bus in Project → Audio
- Mute by default
- Add `AudioEffectCapture` effect (buffer length: 0.1s)
- Test: Play sound on Voice bus, verify it's muted

---

### Phase 2: Input & Feedback

**Goal**: Capture microphone input and provide real-time visual feedback.

#### 2.1 Build the VoiceProcessor
- Scene: `res://scenes/VoiceProcessor.tscn`
- Add `AudioStreamPlayer` node (bus: "Voice", stream: `AudioStreamMicrophone`, autoplay: true)
- Script: `res://scripts/VoiceProcessor.gd`
- In `_process()`: Get AudioEffectCapture → Calculate RMS → Convert to dB → Compare against threshold → Emit `yawa_detected` signal
- Add `Timer` node for 0.2s cooldown
- Test: Print dB values while speaking

#### 2.2 Create Microphone Meter UI
- Scene: `res://scenes/HUD.tscn` (root: `CanvasLayer`)
- Add `ProgressBar` (min: -60, max: 0, top-center position)
- Script: `res://scripts/HUD.gd`
- Connect to VoiceProcessor's `mic_level_updated(db: float)` signal
- Update ProgressBar value in real-time
- Add "YAWA!" label with brief appearance on threshold cross
- Test: Verify bar turns red and label appears on shout

#### 2.3 Add Debug Overlay
- Add numerical dB display label
- Add threshold visualization toggle
- Test: Verify dB values are reasonable across whisper/talk/shout

---

### Phase 3: Gameplay Loop

**Goal**: Implement physics, obstacles, and state management.

#### 3.1 Create the Bird
- Scene: `res://scenes/Player.tscn` (root: `CharacterBody2D`)
- Add `Sprite2D` and `CollisionShape2D` (CircleShape2D)
- Script: `res://scripts/Player.gd`
- In `_physics_process()`: Apply gravity, clamp velocity, `move_and_slide()`, update rotation
- In `_on_yawa_detected()`: Set `velocity.y = -jump_impulse`
- Test: Manually emit yawa signal, verify bird jumps

#### 3.2 Build Pipe Obstacles
- Scene: `res://scenes/PipePair.tscn` (root: `Node2D`)
- Add two `StaticBody2D` nodes with sprites and collision shapes
- Add `Area2D` in gap for score detection
- Script: `res://scripts/PipePair.gd`
- In `_process()`: Move left, `queue_free()` when off-screen
- Connect Area2D signal to emit `score_changed`
- Test: Instance pipe, verify movement and despawn

#### 3.3 Implement Pipe Spawner
- Script: `res://scripts/PipeSpawner.gd` (attach to Main.tscn node)
- Add `Timer` (2.0s, looping)
- On timeout: Instance pipe at random y-position
- Test: Verify continuous spawning

#### 3.4 Add Collision Detection
- In `Player.gd` after `move_and_slide()`: Check collisions, emit `bird_died`
- Test: Hit pipe, verify signal fires

#### 3.5 Build FSM
- Script: `res://scripts/GameStateMachine.gd`
- Define enum: `CALIBRATE, START, PLAYING, GAMEOVER`
- Implement state transitions via signals
- Enable/disable nodes based on state
- Test: Trace state changes in console

#### 3.6 Implement Score Tracking
- In `HUD.gd`: Add score label, connect to `score_changed`
- Store high score in GameEvents
- Test: Score increases when passing pipes

---

### Phase 4: Branding & Polish

**Goal**: Apply the Bisaya "Bai" theme and improve game feel.

#### 4.1 Implement Calibration Screen
- Scene: `res://scenes/CalibrationScreen.tscn`
- Add UI: Title, instruction, mic meter, noise floor indicator
- Script: `res://scripts/CalibrationScreen.gd`
- Sample ambient noise for 2s, set `threshold_db = ambient_db + 15`
- Show only in CALIBRATE state
- Test: Verify threshold adjusts in different environments

#### 4.2 Add "YAWA!" Popup Effect
- Scene: `res://scenes/YawaPopup.tscn`
- Add large "YAWA!" label with scale/opacity animation (0.5s)
- Trigger on `yawa_detected` signal
- Test: Verify popup appears with animation

#### 4.3 Apply Bisaya Typography
- Add custom font (Noto Sans/Poppins)
- Update labels: "Score"→"Puntos", "Game Over"→"Pildi Ka Bai!", "Retry"→"Usab"
- Replace placeholder sprites
- Add parallax background layers
- Test: Review all screens for readability

#### 4.4 Implement Game Over Screen
- Scene: `res://scenes/GameOverScreen.tscn`
- Add title, final score, high score, retry button
- Show only in GAMEOVER state
- Retry button reloads scene
- Test: Die, verify screen shows correct scores

#### 4.5 Add Audio Feedback
- Add sound effects: flap, score, death
- Add background music (looping, muted during calibration)
- Test: Verify audio balance

#### 4.6 Add Visual Polish
- Bird wing animation (2-3 frames)
- Particle effects on yawa detection
- Screen shake on collision
- Smooth state transitions with fades
- Test: Playtest for game feel

---

### Phase 5: Testing & Optimization

**Goal**: Ensure stability and performance.

#### 5.1 Performance Testing
- Profile with Godot's profiler
- Check for memory leaks (pipes not freed)
- Verify 60+ FPS
- Test: Run for 5 minutes, monitor metrics

#### 5.2 Edge Case Testing
- Test without microphone
- Test with loud background noise
- Test rapid yawa spam
- Test pause/minimize
- Test: Document crashes/bugs

#### 5.3 Accessibility Pass
- Add visual indicators for deaf/hard-of-hearing
- Ensure color contrast
- Add in-game sensitivity adjustment
- Test: Have unfamiliar user try without instructions

---

### Phase 6: Documentation & Submission

**Goal**: Prepare for grading.

#### 6.1 Code Documentation
- Add comments to major functions
- Comment FSM logic and signal architecture
- Deliverable: Well-commented codebase

#### 6.2 Create README
- Explain game concept
- List design patterns used and why
- Include "How to Play" section
- Document voice detection system
- Deliverable: README.md

#### 6.3 Record Demo Video
- Show calibration, gameplay, FSM transitions
- Highlight decoupled architecture
- Deliverable: 2-3 minute video

#### 6.4 Final Checklist
- Proper scene organization
- No hardcoded values (all in VocalStats)
- No debug print statements
- Runs without errors/warnings
- Asset attribution if needed

## 7. Known Challenges & Solutions

- **Microphone Latency**: Solved by adding a small "Mercy Window" (Coyote Time) to collision detection.
- **Background Noise**: Solved by the Calibration State which samples noise floors before the game starts.
