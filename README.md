# Wand and Waddle

## Game Description + Mechanical Twist
Wand and Waddle is a 2D arcade dodger inspired by Flappy-style movement, built in Godot 4.

You guide a wizard goose through moving pipe obstacles while collecting enchanted rolls for score pacing and momentum.

### Mechanical twist: Arcane Charge phases
Instead of a single static movement mode, gameplay is driven by an **Arcane Charge** meter (`0–100`) managed globally:
- Charge increases from collectibles and decreases over time.
- Charge state changes (`Depleted`, `Charging`, `Sweet Spot`, `Overcharged`, `Mana Burn`) modify how the goose feels.
- Reaching the flight threshold transitions the game from `GROUNDED` to `FLYING` phase.
- High-charge states can add control drift or input inversion timing, creating risk/reward around resource management.

## Controls
Current default controls in this project:

- **Flap / Jump**: `Space`

## Known Issues / Limitations
- Game-over currently reloads the scene after a short delay (no dedicated game-over menu/UI flow yet).
- Debug text is still shown in-game (phase + charge info), which is useful for tuning but not final UX.
- Arcane systems are still in active tuning (decay rates, thresholds, and profile feel may change).
- High score storage variable exists, but full persistence and game-over presentation are still incomplete.
- Background music is currently set to `MXZI, Deno - FAVELA [NCS Release].ogg`; verify redistribution rights before any public release.

## Asset Credits and Licenses

### Wizard Goose Character Sprites
- Source: `assets/Wizardgooseassets/`
- Author: Axolotl Jim / Craftpix
- Source page: https://axolotl-jim.itch.io/wizard-goose-sp
- License: Craftpix Free License — https://craftpix.net/file-licenses/
- Contains: Idle, Run, Jump, Fall, Dash, Dashup, Lay animations + EggBlast, EggBomb, Turd projectile sprites (64x64 / 32x32)

### Pixel Art Food Pack (Collectibles)
- Source: `assets/Pixel Art Food Pack/`
- Author: Craftpix
- Source page: https://craftpix.net/freebies/
- License: Craftpix Free License — https://craftpix.net/file-licenses/
- Contains: 24 unique food item sprites (toast variations, croissants, stews, doughnuts, and more)

### Cloud / Parallax Backgrounds
- Source: `assets/Clouds/` (8 cloud layer sets)
- Author: Craftpix
- Source page: https://craftpix.net/freebies/
- License: Craftpix Free License — https://craftpix.net/file-licenses/

### Pipes / Flappy-style Environment Pack
- Source: `assets/pipes/`
- Credits (from included readme): Inspired by Flappy Bird, sprites by **Megacrash**, palette **Endesga64**
- License: Creative Commons Zero v1.0 Universal (CC0)

### Flappy Bird Assets (Audio SFX + Sprites)
- Source: `assets/flappy-bird-assets-master/`
- Author: Samuel Custodio
- Repository: https://github.com/samuelcust/flappy-bird-assets
- License: **MIT** — Copyright (c) 2019 Samuel Custodio
- SFX actively used: `wing.ogg`, `point.ogg`, `hit.ogg`, `die.ogg`

### Background Music
- File: `MXZI, Deno - FAVELA [NCS Release].ogg`
- Label: NCS (NoCopyrightSounds)
- Note: NCS tracks require attribution in public distributions. Verify terms at https://ncs.io/usage-policy before any public release.