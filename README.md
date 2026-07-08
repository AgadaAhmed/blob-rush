# Blob Rush

A free, all-ages endless runner for mobile (iOS + Android), built in **Godot 4.3**. The player guides a squishy blob through a never-ending world; the blob **auto-morphs based on the terrain it enters** (road → car, water → boat, ramp → rocket). One-finger controls, forgiving input windows, and a difficulty curve that ramps forever.

> **North star:** "Would a parent happily pay for this?" The buyer is the parent, the player is the kid. All monetization is **cosmetic-only** with no third-party ads and no manipulative IAP, targeting Apple Kids Category and Google Play Families / COPPA-safe compliance.

## Gameplay

- Behind-the-blob **3-lane** view (Subway Surfers style).
- Swipe left/right to switch lanes, up to jump, down to roll.
- Themed stretches morph the blob on entry; skill comes from dodging obstacles *within* each stretch.
- Collect coins and temporary power-ups (magnet, shield, boost); crash ends the run.
- Coins unlock **cosmetic-only** form styles, blob skins, and trails.

## Engineering approach

Built test-first with the [GUT](https://github.com/bitwes/Gut) testing framework. Milestone **M1 (core run loop)** covers the lane math, difficulty curve, run state, and spawner, each with its own unit test suite.

```
scripts/
  run/        lane_manager, difficulty_curve, run_state, spawner, run_scene
  entities/   player, obstacle, coin
  ui/         hud
test/         GUT suites (lane_manager, difficulty_curve, run_state, spawner, smoke)
docs/         design spec + milestone plans
```

## Status

M1 core run loop implemented with a green test suite. Design and milestone specs live in `docs/`.

## Tech

Godot 4.3 (GL Compatibility renderer) · GDScript · GUT 9.7.0 · portrait 720×1280.

---

*Designed and built by Agada Ahmed, with development assisted by Claude.*
