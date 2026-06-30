# Blob Rush — Neon Glow-Up — Design Spec

**Date:** 2026-06-30
**Status:** Approved (design), pending implementation plan
**Depends on:** M1 Core Run Loop (complete on branch `m1-core-run-loop`)

## Problem

M1 produced a fully working, tested run loop, but it renders as flat colored
rectangles ("ridiculously plain"). This spec adds a visual/feel layer — a
**Neon Synthwave** glow-up with a **Neon Tunnel** backdrop and maximum "juice"
— without changing any gameplay logic.

## Decisions (locked during brainstorming)

| Decision | Choice |
|----------|--------|
| Art direction | Neon Synthwave |
| Backdrop | Neon Tunnel (rings + light-spokes rushing from a vanishing point) |
| Juice level | Max (restyle + bloom + particles + shake + squash/stretch + trail + speed-lines + beat-pulse + animated HUD) |
| Glow tech | Switch to **Mobile renderer** for true bloom/glow post-processing |
| Blob personality | Eyeless glowing gel orb (no face) |
| Beat source | 120 BPM timer (not music-synced; built to sync to a track later) |

## Principles

- **Gameplay logic unchanged.** This is purely additive visual/scene/shader/feel
  work over the working M1 loop. `LaneManager`, `DifficultyCurve`, `RunState`,
  `Spawner` are untouched.
- **Project testing pattern preserved.** Pure logic lives in tested `RefCounted`
  units; visual behavior is verified by running the game. The full GUT suite must
  stay green (currently 19 tests).
- **Overbright + bloom.** Neon elements use HDR colors with channel values > 1 so
  the `WorldEnvironment` glow blooms them automatically — the primary "neon" lever.

## Foundation Change: Renderer + Environment

- `project.godot`: `rendering/renderer/rendering_method = "mobile"` (was
  `gl_compatibility`). Enable 2D HDR (`rendering/viewport/hdr_2d = true`).
- Add a `WorldEnvironment` node to `run.tscn` with an `Environment` resource:
  `glow_enabled = true`, tuned `glow_intensity`/`glow_bloom`/`glow_strength`,
  glow blend mode additive/screen. This is what makes overbright colors bloom.
- **Constraint accepted:** the Mobile renderer drops the very oldest/cheapest
  Android devices (roughly pre-2017). Acceptable for the look.

## Components

### 1. Neon Tunnel backdrop
- `scenes/neon_tunnel.tscn` — a full-screen `ColorRect` (behind gameplay, drawn
  in screen space) running `shaders/neon_tunnel.gdshader`.
- Shader draws concentric rings + radial light-spokes converging on a vanishing
  point near the player's horizon. Uniforms:
  - `speed` — drives ring/spoke rush rate and spoke length/brightness (this *is*
    the "speed-lines" effect, scaling with velocity).
  - `pulse` — 0..1 beat value driving overall brightness/scale throb.
- `scripts/fx/neon_tunnel.gd` exposes setters that `run_scene.gd` feeds each frame.

### 2. The blob (`player.tscn` + `player.gd` upgrade)
- Replace the flat `ColorRect` with a glowing gel orb (radial neon gradient,
  overbright core) — e.g. a `Sprite2D`/`Polygon2D` with gradient texture, or a
  small shader.
- **Squash & stretch** on lane-change, jump, roll, and landing (tween-driven,
  layered on the existing `_set_state` scale changes).
- Subtle **idle jelly-wobble**.
- **Glowing motion-trail**: fading afterimages (Line2D with width/alpha curve, or
  a trailing `GPUParticles2D`) that lengthens with speed.
- Gameplay-facing API (`current_lane()`, `is_jumping()`, `is_rolling()`,
  lane/jump/roll inputs) stays identical.

### 3. Obstacles & coins
- `obstacle.tscn`: dark core with an overbright **magenta** neon outline.
- `coin.tscn`: bright overbright orb that **spins + shimmers** (pulsing
  scale/alpha). Collision shapes unchanged.

### 4. Particles
- `scenes/fx/coin_burst.tscn` — one-shot glow-sparkle pop on pickup.
- `scenes/fx/crash_burst.tscn` — one-shot neon explosion (blob + obstacle colors)
  on death.
- Both auto-free after emitting.

### 5. Screen feedback
- Add a `Camera2D` to `run.tscn` for **screen shake** on crash.
- Full-screen **flash** overlay (ColorRect) that fades out on crash.
- Shake driven by a trauma value (see `ScreenShake` below).

### 6. Animated neon HUD (`hud.tscn` + `hud.gd` upgrade)
- Restyled glowing distance/coin readouts (neon palette, glow).
- Coin counter **bumps** (scale-pop) when coins increase.
- Subtle **beat-pulse** on HUD elements.
- Game-over panel: neon restyle, animated tween entrance, glowing "Play Again".
- Existing signals/methods (`restart_pressed`, `update_stats`, `show_death`) keep
  their contracts.

### 7. Beat-pulse
- Steady tempo clock (default 120 BPM, timer-driven) producing a `pulse` value
  consumed by the tunnel and HUD. Built so a music track can drive it later.

## Tested Logic Units (new)

These are pure `RefCounted` units with GUT tests (the only non-visual additions):

- `scripts/fx/screen_shake.gd` — `ScreenShake`
  - Holds `trauma` (0..1). `add_trauma(amount)` accumulates and clamps to 1.
  - `update(delta)` decays trauma toward 0 at a fixed rate; never goes below 0.
  - `get_offset()` returns a shake offset scaled by `trauma` (squared for falloff).
  - Tests: clamps at 1; decays to 0 over time; offset is zero at zero trauma;
    offset magnitude bounded by the configured max.
- `scripts/fx/beat_clock.gd` — `BeatClock`
  - Constructed with BPM. `pulse_at(time)` returns a 0..1 value following the beat
    phase (e.g. a shaped sawtooth/cosine per beat).
  - Tests: pulse stays within 0..1; phase repeats every beat period; BPM changes
    the period correctly.

## Data Flow

`run_scene._process(delta)` (gameplay already computes `speed`):
- Advance `BeatClock`; feed `speed` and `pulse` to the tunnel shader and HUD.
- On coin hit → spawn `coin_burst` at coin position; HUD coin-bump.
- On obstacle hit → spawn `crash_burst`; `ScreenShake.add_trauma(...)`; trigger
  flash; then existing death/game-over path runs.
- `ScreenShake.update(delta)` each frame → apply `get_offset()` to the `Camera2D`.

## Error Handling

- Effects are decoupled and guarded — a missing fx node must never break the run
  loop. One-shot particles self-free. Game-over/restart path is unchanged.

## Testing

- New GUT tests for `ScreenShake` and `BeatClock`; full suite stays green
  (19 existing + new).
- All visual work verified by running `godot scenes/run.tscn` and observing, plus
  a headless boot (`godot --headless scenes/run.tscn --quit-after N`) to confirm
  no script/scene errors under the Mobile renderer.

## File Structure (added/modified)

```
project.godot                      # MOD: mobile renderer + 2D HDR
shaders/neon_tunnel.gdshader       # NEW
scenes/neon_tunnel.tscn            # NEW
scripts/fx/neon_tunnel.gd          # NEW
scripts/fx/screen_shake.gd         # NEW (tested)
scripts/fx/beat_clock.gd           # NEW (tested)
scenes/fx/coin_burst.tscn          # NEW
scenes/fx/crash_burst.tscn         # NEW
scenes/player.tscn                 # MOD: gel orb + trail
scripts/entities/player.gd         # MOD: squash/stretch, wobble, trail
scenes/obstacle.tscn               # MOD: neon outline
scenes/coin.tscn                   # MOD: spin/shimmer orb
scenes/hud.tscn                    # MOD: neon restyle + animated
scripts/ui/hud.gd                  # MOD: coin-bump, beat-pulse, game-over anim
scenes/run.tscn                    # MOD: WorldEnvironment, Camera2D, tunnel, flash
scripts/run/run_scene.gd           # MOD: wire shake/flash/particles/tunnel/beat
test/test_screen_shake.gd          # NEW
test/test_beat_clock.gd            # NEW
```

## Out of Scope

- Music/SFX (beat is a timer for now).
- Real art assets / sprites (all in-engine shapes, gradients, shaders).
- New gameplay mechanics (this is M1 polish, not M2 terrain morph).
```
