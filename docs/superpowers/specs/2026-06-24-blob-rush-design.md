# Blob Rush — Design Spec

**Date:** 2026-06-24
**Status:** Approved design, pre-implementation
**Working title:** Blob Rush *(placeholder)*

## 1. Concept

A free, all-ages endless runner for mobile (iOS + Android). The player guides a
squishy blob through a never-ending world. The blob **auto-morphs based on the
terrain it enters** — road → car, water → boat, ramp → rocket. Controls are
one-finger and forgiving, so a 5-year-old can play instantly while a 12-year-old
finds a real skill ceiling. The player collects coins while running and spends
them unlocking **cosmetic-only** styles for the blob and its forms. Difficulty
ramps forever; the player chases their best distance.

**North star:** "Would a parent happily pay for this?" The buyer is the parent;
the player is the kid. We win on quality and goodwill, never on manipulation.

## 2. Audience & positioning

- **Audience:** All-ages / families. Designed for kids, purchased by parents.
- **Tone:** Bright, friendly, funny. No violence, no scary content, no chat with
  strangers, no behavioral ads.
- **Compliance targets:** Apple Kids Category rules and Google Play Families
  policy (no third-party ads, no manipulative IAP), COPPA-safe (no personal data
  collection in v1).

## 3. Camera & controls

- **Camera:** Behind-the-blob 3-lane view (Subway Surfers style).
- **Controls:**
  - Swipe **left / right** — switch lanes (3 lanes).
  - Swipe **up** — jump.
  - Swipe **down** — roll / duck.
- One finger, forgiving input windows.

## 4. Core run loop (moment to moment)

1. Blob auto-runs forward; the world scrolls; speed slowly increases over distance.
2. The track runs through **themed stretches** that morph the whole blob on entry:
   - 🛣️ **Road stretch** → **car** (grounded dodging).
   - 🌊 **Water stretch** → **boat** (bobs over waves).
   - 🚀 **Launch ramp** → **rocket** (brief flight, then drops back to track).
   Morph = the stretch you are in. Skill = dodging obstacles *within* the stretch
   by lane-switching, jumping, and rolling.
3. **Collect along the way:**
   - **Coins** — soft currency.
   - **Power-ups (temporary):**
     - **Magnet** — pulls in nearby coins.
     - **Shield** — absorbs one crash.
     - **Boost** — speed burst + invincible sprint.
4. **Crash** (hit an obstacle) → run ends → tally coins earned → results screen →
   "one more run."

## 5. Progression & unlockables (the heart)

All unlockables are **cosmetic only — never power.**

- **Form styles** — skins per form, mix-and-match loadout:
  - Car: race car, banana car, tank, …
  - Boat: pirate ship, rubber duck, surfboard, …
  - Rocket: UFO, dragon, paper plane, …
- **Blob skins** — base blob look: marble, lava, galaxy, googly-eyes, …
- **Trails** — sparkle, rainbow, bubbles, …

Earned with coins through normal play, **or** bought directly with real money.
Equipping is a loadout choice; it changes looks, not stats.

## 6. Monetization

- **Free download.** Cosmetic IAP only. **No ads** (kids-policy safe).
- **Revenue sources:**
  - Coin packs (convenience — skip the grind for cosmetics).
  - Direct cosmetic purchases.
  - Optional one-time "starter bundle."
- **Future (not v1):** paid **world expansions** (e.g. Candy Coast, Space Harbor)
  as the big-ticket parent purchase. Architected so a world drops in as content
  with no rewrite.
- **Explicitly rejected:** loot boxes / randomized paid rewards, pay-to-win,
  third-party ads, dark-pattern nags. These violate store kids-policies and
  parent trust.

## 7. Tech

- **Engine:** Godot 4 (GDScript). Free, no revenue cut, strong 2D mobile support.
- **Targets:** iOS + Android. Developed on Windows.
- **Architecture intent:**
  - Data-driven content: stretches, obstacles, and cosmetics defined as resources
    so adding more is content, not code.
  - Separation of run simulation, rendering, and economy/save so each is testable
    in isolation.
  - IAP and worlds behind clean interfaces with no-op/local stubs in v1.

## 8. Art & asset pipeline

- **Asset type needed:** 2D sprites / sprite sheets with transparent backgrounds,
  consistent style across all frames and cosmetics; tileable obstacle and
  background tiles.
- **Higgsfield is not used.** It targets cinematic AI *video* (image-to-video),
  which produces frame-to-frame drift and no transparency — wrong tool for
  game-ready 2D sprites.
- **Candidate pipelines (decided during implementation):**
  - Concept + individual sprites via image-gen (Midjourney / DALL·E / Stable
    Diffusion) with background cleanup.
  - Game-asset-focused tools (Layer.ai, Scenario.gg) for style-consistent sprite
    sets.
  - Or start from a purchased sprite pack, generate variations later.
- **v1 placeholder strategy:** ship with simple programmer-art / primitive shapes
  so gameplay is testable before final art lands. Art is swappable via the
  data-driven asset references.

## 9. v1 scope (ship-first)

**In:**
- One endless world / single biome.
- The 3 forms (car, boat, rocket) and their terrain stretches.
- 3 power-ups (Magnet, Shield, Boost).
- Coin economy + cosmetic unlocking via coins.
- ~8–12 starter cosmetics across blob skins / form styles / trails.
- Local save (high score, coins, owned/equipped cosmetics).
- Results screen, main menu, cosmetics/loadout screen, pause.

**Deliberately later (coded to bolt on):**
- Real IAP store integration (v1 uses local-only cosmetic unlocks).
- Themed paid world expansions.
- Cloud save, leaderboards, daily challenges/missions.
- Final art (v1 uses placeholders).

## 10. Success criteria

- Smooth 60fps on mid-range phones.
- A new player understands controls within the first run, no tutorial wall.
- "One more run" pull comes from skill + collection, not manipulation.
- A parent reviewing the IAP screen sees only optional cosmetics and feels safe.
- Adding a new cosmetic or obstacle is a content edit, not an engine change.
