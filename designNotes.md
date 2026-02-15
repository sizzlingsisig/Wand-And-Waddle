# Wand and Waddle: Official Design Notes

## 1. High-Level Architecture

Wand and Waddle uses a **Decoupled Component Architecture** with systems communicating via a central **Signal Bus**.

### Core Design Patterns

- **Finite State Machine (FSM)**: Controls game flow (Grounded → Flying → Game Over)
- **Observer Pattern (Signals)**: Connects Arcane Charge to Physics without direct dependencies
- **Data-Driven Design**: All values (gravity, charge rates, mass) stored in editable Custom Resource
- **Singleton (Autoload)**: Manages global events and score persistence

## 2. Finite State Machine (FSM)

| State | What Happens | Transition Trigger |
|-------|--------------|-------------------|
| **GROUNDED** | Kitchen phase with run/crouch controls | Charge reaches 50% |
| **FLYING** | Flight physics with charge management | Collision with obstacle |
| **GAMEOVER** | Game stops, shows retry screen | Press retry |

## 3. The Arcane Charge System

The **Arcane Charge** is a 0-100% meter that controls physics and visuals:

- **Gain Charge**: Collect Enchanted Rolls
- **Lose Charge**: Natural decay + casting spells
- **Current Charge %**: Determines which physics profile is active

### The Five Charge States:

| State | Range | Physics | Visuals |
|-------|-------|---------|---------|
| **Depleted** | 0-15% | Heavy (2.5x mass), input lag | Black & white, dim |
| **Charging** | 16-40% | Still heavy (1.5x mass) | Colors returning, sparks |
| **Sweet Spot** | 41-65% | Perfect control (1.0x mass) | Vivid, golden glow |
| **Overcharged** | 66-85% | Drifty (0.8x mass), random tilt | Screen sway, crackling |
| **Mana Burn** | 86-100% | Very light (0.5x mass), swapped inputs | Tunnel vision, arcs |

## 4. Physics Modes

### Ground Physics (Grounded State):
- Run animation for movement
- Crouch to reduce hitbox
- Standard platformer jump
- Dodge rolling pins

### Flight Physics (Flying State):
- Double Jump animation = flap
- Gravity modified by current mass multiplier
- Rotation based on velocity
- Control drift when Overcharged
- Input chaos when Mana Burned

### Spellcasting:
- **Spell Orb** (Attack): Fires projectile, drains 10% charge
- **Spell Burst** (Dash): Forward dash, resets charge to 0%

## 5. Scene Structure

- **Main.tscn**: FSM coordinator
- **Player.tscn**: Physics, animations, collision
- **ArcaneChargeManager.tscn**: Charge calculations and state logic
- **Obstacles.tscn**: Rolling pins (ground) / Pipes (air)
- **Collectible.tscn**: Enchanted Rolls
- **SpellOrb.tscn**: Fired projectiles
- **HUD.tscn**: Charge meter, score, state indicator

## 6. Implementation Phases

### Phase 1: Core Setup
- Create Signal Bus (`GameEvents.gd`) with signals: `charge_changed`, `wizard_died`, `score_changed`, `phase_transitioned`
- Create Custom Resource (`ArcaneStats.gd`) for all tunable values
- Import and set up all sprite animations

### Phase 2: Charge System
- Build `ArcaneChargeManager` with passive decay and signal emissions
- Create 5 `ChargeStateProfile` resources (one per state)
- Implement state detection based on current charge %

### Phase 3: Player Physics
- Implement ground movement (run, crouch, jump)
- Implement flight movement (flap, rotation, mass-based gravity)
- Connect physics to current charge state profile
- Add spellcasting (Orb and Burst)

### Phase 4: Obstacles & Phase Transition
- Create ground obstacles (rolling pins)
- Create flight obstacles (pipe pairs)
- Build spawner that switches obstacle types based on game phase
- Implement 50% charge trigger for Grounded → Flying transition
- Add collectibles that increase charge

### Phase 5: Environmental Interactions
- **Arcane Vents**: Rapidly increase charge when overlapped
- **Water Buckets**: Reduce charge and apply downward force on hit

### Phase 6: Visual & Audio Polish
- Create shaders for each charge state (desaturation, sway, tunnel vision)
- Add particle effects (glow, sparks, electricity) based on state
- Build HUD with charge meter and state indicator
- Add sound effects and background music

### Phase 7: Game Over Flow
- Detect collisions and trigger death
- Build Game Over screen with score and retry
- Implement score tracking and persistence

### Phase 8: Balance & Testing
- Tune charge rates for engaging gameplay
- Calibrate physics profiles to feel distinct
- Adjust obstacle difficulty and spawn rates
- Playtest for 30-60 second average runs

### Phase 9: Documentation
- Comment all major systems
- Create README explaining architecture and design patterns
- Record demo video showing FSM transitions and charge states
- Final checklist: no hardcoded values, runs without errors

## 7. Key Solutions

- **Smooth State Transitions**: Interpolate physics values over 0.2s when changing states
- **Mana Burn Warning**: 0.5s visual cue before inputs swap
- **Transition Buffer**: 3 seconds obstacle-free after reaching flight mode
- **Visual Clarity**: Particle density scales with charge intensity