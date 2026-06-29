# Blob Rush — Milestone 1: Core Run Loop — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A playable vertical slice — a blob auto-runs down a 3-lane track, the world scrolls and speeds up, the player swipes to change lanes / jump / roll, obstacles and coins spawn ahead, hitting an obstacle ends the run, and the player can restart. Programmer art only.

**Architecture:** Pure-logic units (lane math, difficulty curve, run state, spawn decisions) live in plain GDScript `RefCounted` classes with `class_name`, unit-tested headlessly with GUT. Visual/scene behavior (player node, world scroll, collisions, HUD) is wired in `.tscn` scenes and verified by running the game. Logic is deterministic and decoupled from rendering so M2–M5 build on it as content, not rewrites.

**Tech Stack:** Godot 4.3+ (GDScript), GUT 9.x (Godot Unit Test) for headless tests. Developed on Windows; Godot editor + `godot` CLI on PATH.

---

## File Structure (created across this milestone)

```
project.godot                      # Godot project config
addons/gut/...                     # GUT testing addon (downloaded)
scripts/run/lane_manager.gd        # Lane index <-> x-position + lane switching
scripts/run/difficulty_curve.gd    # distance -> scroll speed
scripts/run/run_state.gd           # distance, coins, alive/dead, signals
scripts/run/spawner.gd             # deterministic decisions: what spawns, which lanes
scripts/entities/player.gd         # player node: input -> lane/jump/roll, exposes lane
scripts/entities/obstacle.gd       # obstacle node: kills player on contact
scripts/entities/coin.gd           # coin node: adds coin on contact, despawns
scripts/ui/hud.gd                  # shows distance + coin count, restart button
scenes/player.tscn                 # player visual + collision
scenes/obstacle.tscn               # obstacle visual + collision
scenes/coin.tscn                   # coin visual + collision
scenes/hud.tscn                    # HUD canvas layer
scenes/run.tscn                    # main scene: wires everything, scroll + spawn loop
test/test_lane_manager.gd
test/test_difficulty_curve.gd
test/test_run_state.gd
test/test_spawner.gd
.gitignore
```

**Conventions for this plan:**
- Godot uses a Y-down 2D world. "Forward" = world scrolls upward past a fixed-Y player; the player only moves on the X axis (lanes), plus a short jump/roll state.
- Run all GUT tests with:
  `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gexit`
- Run the game with: `godot scenes/run.tscn`

---

## Task 0: Project setup + first green test

**Files:**
- Create: `project.godot`
- Create: `.gitignore`
- Create: `addons/gut/` (downloaded)
- Create: `test/test_smoke.gd`

- [ ] **Step 1: Create `.gitignore`**

```gitignore
# Godot 4
.godot/
.import/
export.cfg
export_presets.cfg
*.translation
.DS_Store
```

- [ ] **Step 2: Create minimal `project.godot`**

```ini
config_version=5

[application]
config/name="Blob Rush"
run/main_scene="res://scenes/run.tscn"
config/features=PackedStringArray("4.3", "GL Compatibility")

[display]
window/size/viewport_width=720
window/size/viewport_height=1280
window/stretch/mode="canvas_items"

[rendering]
renderer/rendering_method="gl_compatibility"

[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

- [ ] **Step 3: Install GUT**

Download GUT 9.x (Godot 4 branch) into `addons/gut`:

```bash
git clone --depth 1 --branch v9.3.0 https://github.com/bitwes/Gut.git /tmp/gut \
  && mkdir -p addons \
  && cp -r /tmp/gut/addons/gut addons/gut
```

(If `godot` isn't on PATH yet, install Godot 4.3+ from https://godotengine.org/download and add it to PATH. On Windows the binary is `Godot_v4.3-stable_win64.exe` — rename/alias to `godot`.)

- [ ] **Step 4: Write a smoke test**

`test/test_smoke.gd`:

```gdscript
extends GutTest

func test_environment_runs():
    assert_eq(1 + 1, 2, "GUT can execute a test")
```

- [ ] **Step 5: Run the test suite, verify it passes**

Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gexit`
Expected: output shows `1 passing` (or similar), exit code 0.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore(m1): scaffold Godot project + GUT, green smoke test"
```

---

## Task 1: LaneManager (lane math + switching)

**Files:**
- Create: `scripts/run/lane_manager.gd`
- Test: `test/test_lane_manager.gd`

- [ ] **Step 1: Write the failing test**

`test/test_lane_manager.gd`:

```gdscript
extends GutTest

func test_center_lane_is_x_zero():
    var lm := LaneManager.new(3, 200.0, 1)
    assert_eq(lm.lane_to_x(1), 0.0)

func test_outer_lanes_are_symmetric():
    var lm := LaneManager.new(3, 200.0, 1)
    assert_eq(lm.lane_to_x(0), -200.0)
    assert_eq(lm.lane_to_x(2), 200.0)

func test_move_left_decrements_and_clamps_at_zero():
    var lm := LaneManager.new(3, 200.0, 1)
    assert_eq(lm.move_left(), 0)
    assert_eq(lm.move_left(), 0)

func test_move_right_increments_and_clamps_at_max():
    var lm := LaneManager.new(3, 200.0, 1)
    assert_eq(lm.move_right(), 2)
    assert_eq(lm.move_right(), 2)

func test_current_x_tracks_current_lane():
    var lm := LaneManager.new(3, 200.0, 1)
    lm.move_left()
    assert_eq(lm.current_x(), -200.0)
```

- [ ] **Step 2: Run test, verify it fails**

Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gselect=test_lane_manager -gexit`
Expected: FAIL — `LaneManager` is an unknown identifier.

- [ ] **Step 3: Write minimal implementation**

`scripts/run/lane_manager.gd`:

```gdscript
class_name LaneManager
extends RefCounted

var num_lanes: int
var spacing: float
var current_lane: int

func _init(p_num_lanes: int = 3, p_spacing: float = 200.0, p_start_lane: int = 1) -> void:
	num_lanes = p_num_lanes
	spacing = p_spacing
	current_lane = clamp(p_start_lane, 0, num_lanes - 1)

func lane_to_x(lane: int) -> float:
	var center := (num_lanes - 1) / 2.0
	return (lane - center) * spacing

func move_left() -> int:
	current_lane = max(0, current_lane - 1)
	return current_lane

func move_right() -> int:
	current_lane = min(num_lanes - 1, current_lane + 1)
	return current_lane

func current_x() -> float:
	return lane_to_x(current_lane)
```

- [ ] **Step 4: Run test, verify it passes**

Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gselect=test_lane_manager -gexit`
Expected: PASS — 5 passing.

- [ ] **Step 5: Commit**

```bash
git add scripts/run/lane_manager.gd test/test_lane_manager.gd
git commit -m "feat(m1): LaneManager lane math + clamped switching"
```

---

## Task 2: DifficultyCurve (distance → speed)

**Files:**
- Create: `scripts/run/difficulty_curve.gd`
- Test: `test/test_difficulty_curve.gd`

- [ ] **Step 1: Write the failing test**

`test/test_difficulty_curve.gd`:

```gdscript
extends GutTest

func test_speed_starts_at_base():
	var dc := DifficultyCurve.new(400.0, 1000.0, 2000.0)
	assert_eq(dc.speed_at(0.0), 400.0)

func test_speed_reaches_max_at_ramp_distance():
	var dc := DifficultyCurve.new(400.0, 1000.0, 2000.0)
	assert_eq(dc.speed_at(2000.0), 1000.0)

func test_speed_clamps_at_max_beyond_ramp():
	var dc := DifficultyCurve.new(400.0, 1000.0, 2000.0)
	assert_eq(dc.speed_at(5000.0), 1000.0)

func test_speed_interpolates_linearly_at_midpoint():
	var dc := DifficultyCurve.new(400.0, 1000.0, 2000.0)
	assert_eq(dc.speed_at(1000.0), 700.0)
```

- [ ] **Step 2: Run test, verify it fails**

Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gselect=test_difficulty_curve -gexit`
Expected: FAIL — `DifficultyCurve` unknown identifier.

- [ ] **Step 3: Write minimal implementation**

`scripts/run/difficulty_curve.gd`:

```gdscript
class_name DifficultyCurve
extends RefCounted

var base_speed: float
var max_speed: float
var ramp_distance: float

func _init(p_base: float = 400.0, p_max: float = 1000.0, p_ramp: float = 2000.0) -> void:
	base_speed = p_base
	max_speed = p_max
	ramp_distance = p_ramp

func speed_at(distance: float) -> float:
	var t: float = clamp(distance / ramp_distance, 0.0, 1.0)
	return lerp(base_speed, max_speed, t)
```

- [ ] **Step 4: Run test, verify it passes**

Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gselect=test_difficulty_curve -gexit`
Expected: PASS — 4 passing.

- [ ] **Step 5: Commit**

```bash
git add scripts/run/difficulty_curve.gd test/test_difficulty_curve.gd
git commit -m "feat(m1): DifficultyCurve linear distance->speed ramp"
```

---

## Task 3: RunState (distance, coins, alive/dead)

**Files:**
- Create: `scripts/run/run_state.gd`
- Test: `test/test_run_state.gd`

- [ ] **Step 1: Write the failing test**

`test/test_run_state.gd`:

```gdscript
extends GutTest

func test_starts_alive_zeroed():
	var rs := RunState.new()
	assert_true(rs.alive)
	assert_eq(rs.distance, 0.0)
	assert_eq(rs.coins, 0)

func test_advance_increases_distance_by_speed_times_delta():
	var rs := RunState.new()
	rs.advance(500.0, 0.1)
	assert_almost_eq(rs.distance, 50.0, 0.0001)

func test_advance_does_nothing_when_dead():
	var rs := RunState.new()
	rs.kill()
	rs.advance(500.0, 0.1)
	assert_eq(rs.distance, 0.0)

func test_add_coin_increments():
	var rs := RunState.new()
	rs.add_coin()
	rs.add_coin(3)
	assert_eq(rs.coins, 4)

func test_kill_sets_dead_and_emits_once():
	var rs := RunState.new()
	watch_signals(rs)
	rs.kill()
	rs.kill()
	assert_false(rs.alive)
	assert_signal_emit_count(rs, "died", 1)
```

- [ ] **Step 2: Run test, verify it fails**

Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gselect=test_run_state -gexit`
Expected: FAIL — `RunState` unknown identifier.

- [ ] **Step 3: Write minimal implementation**

`scripts/run/run_state.gd`:

```gdscript
class_name RunState
extends RefCounted

signal died

var distance: float = 0.0
var coins: int = 0
var alive: bool = true

func advance(speed: float, delta: float) -> void:
	if not alive:
		return
	distance += speed * delta

func add_coin(amount: int = 1) -> void:
	coins += amount

func kill() -> void:
	if alive:
		alive = false
		died.emit()
```

- [ ] **Step 4: Run test, verify it passes**

Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gselect=test_run_state -gexit`
Expected: PASS — 5 passing.

- [ ] **Step 5: Commit**

```bash
git add scripts/run/run_state.gd test/test_run_state.gd
git commit -m "feat(m1): RunState distance/coins/alive with died signal"
```

---

## Task 4: Spawner (deterministic, always-solvable rows)

**Files:**
- Create: `scripts/run/spawner.gd`
- Test: `test/test_spawner.gd`

- [ ] **Step 1: Write the failing test**

`test/test_spawner.gd`:

```gdscript
extends GutTest

func test_same_seed_produces_same_lane_sequence():
	var a := Spawner.new(42, 3)
	var b := Spawner.new(42, 3)
	for i in range(20):
		assert_eq(a.next_obstacle_lanes(), b.next_obstacle_lanes())

func test_row_always_leaves_at_least_one_lane_open():
	var s := Spawner.new(7, 3)
	for i in range(100):
		var blocked: Array = s.next_obstacle_lanes()
		assert_lt(blocked.size(), 3, "row must never block all lanes")

func test_blocked_lanes_are_valid_indices():
	var s := Spawner.new(7, 3)
	for i in range(100):
		for lane in s.next_obstacle_lanes():
			assert_between(lane, 0, 2)

func test_next_kind_is_coin_or_obstacle():
	var s := Spawner.new(1, 3)
	for i in range(50):
		var kind := s.next_spawn_kind()
		assert_true(kind == "coin" or kind == "obstacle")
```

- [ ] **Step 2: Run test, verify it fails**

Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gselect=test_spawner -gexit`
Expected: FAIL — `Spawner` unknown identifier.

- [ ] **Step 3: Write minimal implementation**

`scripts/run/spawner.gd`:

```gdscript
class_name Spawner
extends RefCounted

var rng := RandomNumberGenerator.new()
var num_lanes: int

func _init(p_seed: int = 0, p_num_lanes: int = 3) -> void:
	rng.seed = p_seed
	num_lanes = p_num_lanes

# Returns the lanes blocked by an obstacle row. One lane is always
# guaranteed open so every row is solvable.
func next_obstacle_lanes() -> Array:
	var free_lane := rng.randi_range(0, num_lanes - 1)
	var blocked: Array = []
	for lane in range(num_lanes):
		if lane == free_lane:
			continue
		if rng.randf() < 0.6:
			blocked.append(lane)
	return blocked

func next_spawn_kind() -> String:
	return "coin" if rng.randf() < 0.3 else "obstacle"
```

- [ ] **Step 4: Run test, verify it passes**

Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gselect=test_spawner -gexit`
Expected: PASS — 4 passing.

- [ ] **Step 5: Commit**

```bash
git add scripts/run/spawner.gd test/test_spawner.gd
git commit -m "feat(m1): Spawner deterministic, always-solvable obstacle rows"
```

---

## Task 5: Player scene — input → lane movement + jump/roll

**Files:**
- Create: `scenes/player.tscn`
- Create: `scripts/entities/player.gd`

This task is visual; verify by running the scene and observing behavior.

- [ ] **Step 1: Create `scripts/entities/player.gd`**

```gdscript
class_name Player
extends Area2D

@export var lane_spacing: float = 200.0
@export var num_lanes: int = 3
@export var move_speed: float = 2000.0   # x lerp speed toward target lane
@export var jump_time: float = 0.45
@export var roll_time: float = 0.45

var _lanes: LaneManager
var _state: String = "run"   # run | jump | roll
var _state_timer: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
	_lanes = LaneManager.new(num_lanes, lane_spacing, num_lanes / 2)
	position.x = _lanes.current_x()
	_base_y = position.y

func _process(delta: float) -> void:
	position.x = move_toward(position.x, _lanes.current_x(), move_speed * delta)
	if _state != "run":
		_state_timer -= delta
		if _state_timer <= 0.0:
			_set_state("run")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var d: Vector2 = event.relative
		if abs(d.x) > abs(d.y):
			if d.x < -8.0:
				_lanes.move_left()
			elif d.x > 8.0:
				_lanes.move_right()
		else:
			if d.y < -8.0:
				_set_state("jump")
			elif d.y > 8.0:
				_set_state("roll")

func _set_state(new_state: String) -> void:
	_state = new_state
	if new_state == "jump":
		_state_timer = jump_time
		scale = Vector2(0.8, 1.2)
		position.y = _base_y - 60.0
	elif new_state == "roll":
		_state_timer = roll_time
		scale = Vector2(1.2, 0.6)
	else:
		scale = Vector2.ONE
		position.y = _base_y

func current_lane() -> int:
	return _lanes.current_lane

func is_rolling() -> bool:
	return _state == "roll"

func is_jumping() -> bool:
	return _state == "jump"
```

- [ ] **Step 2: Build `scenes/player.tscn`**

In the Godot editor:
- Root node `Area2D`, attach `scripts/entities/player.gd`.
- Child `ColorRect` (or `Polygon2D`), size ~80×80, a bright color (the blob), centered on origin.
- Child `CollisionShape2D` with a `RectangleShape2D` ~70×70.
- Set the Area2D `collision_layer = 1` (player), `collision_mask = 2` (obstacles/coins).
- Save as `scenes/player.tscn`.

- [ ] **Step 3: Verify by running the player scene**

Run: `godot scenes/player.tscn`
Expected (use mouse-drag to emulate touch): dragging left/right snaps the blob between 3 lanes and clamps at the edges; dragging up squishes tall + lifts (jump) and returns after ~0.45s; dragging down squishes flat (roll) and returns.

- [ ] **Step 4: Commit**

```bash
git add scenes/player.tscn scripts/entities/player.gd
git commit -m "feat(m1): player scene with lane swipe + jump/roll states"
```

---

## Task 6: World scroll + obstacle/coin scenes + spawn loop

**Files:**
- Create: `scenes/obstacle.tscn`
- Create: `scripts/entities/obstacle.gd`
- Create: `scenes/coin.tscn`
- Create: `scripts/entities/coin.gd`
- Create: `scenes/run.tscn`
- Create: `scripts/run/run_scene.gd` (attached to `run.tscn` root)

- [ ] **Step 1: Create `scripts/entities/obstacle.gd`**

```gdscript
class_name Obstacle
extends Area2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
```

- [ ] **Step 2: Build `scenes/obstacle.tscn`**

- Root `Area2D` + `scripts/entities/obstacle.gd`.
- Child `ColorRect` ~80×80, a dark/warning color.
- Child `CollisionShape2D` `RectangleShape2D` ~70×70.
- Add it to group `"obstacle"` (Node → Groups tab).
- Save as `scenes/obstacle.tscn`.

- [ ] **Step 3: Create `scripts/entities/coin.gd`**

```gdscript
class_name Coin
extends Area2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
```

- [ ] **Step 4: Build `scenes/coin.tscn`**

- Root `Area2D` + `scripts/entities/coin.gd`.
- Child `ColorRect` ~40×40, gold color (or a yellow `Polygon2D` circle).
- Child `CollisionShape2D` `CircleShape2D` radius ~24.
- Add it to group `"coin"`.
- Save as `scenes/coin.tscn`.

- [ ] **Step 5: Create `scripts/run/run_scene.gd`**

```gdscript
extends Node2D

const OBSTACLE := preload("res://scenes/obstacle.tscn")
const COIN := preload("res://scenes/coin.tscn")

@export var lane_spacing: float = 200.0
@export var num_lanes: int = 3
@export var spawn_y: float = -200.0       # above the visible top
@export var despawn_y: float = 1400.0     # below the visible bottom
@export var spawn_interval_distance: float = 350.0

var run_state := RunState.new()
var curve := DifficultyCurve.new(400.0, 1000.0, 2000.0)
var spawner := Spawner.new()
var lanes := LaneManager.new()
var _player: Player
var _distance_since_spawn: float = 0.0

func _ready() -> void:
	spawner = Spawner.new(randi(), num_lanes)
	lanes = LaneManager.new(num_lanes, lane_spacing, 1)
	_player = $Player
	run_state.died.connect(_on_died)

func _process(delta: float) -> void:
	if not run_state.alive:
		return
	var speed := curve.speed_at(run_state.distance)
	run_state.advance(speed, delta)
	_scroll_world(speed, delta)
	_distance_since_spawn += speed * delta
	if _distance_since_spawn >= spawn_interval_distance:
		_distance_since_spawn -= spawn_interval_distance
		_spawn_row()

func _scroll_world(speed: float, delta: float) -> void:
	for child in get_children():
		if child.is_in_group("obstacle") or child.is_in_group("coin"):
			child.position.y += speed * delta
			if child.position.y > despawn_y:
				child.queue_free()

func _lane_x(lane: int) -> float:
	return lanes.lane_to_x(lane)

func _spawn_row() -> void:
	if spawner.next_spawn_kind() == "coin":
		var lane := randi() % num_lanes
		var c := COIN.instantiate()
		c.position = Vector2(_lane_x(lane), spawn_y)
		c.area_entered.connect(_on_coin_hit.bind(c))
		add_child(c)
	else:
		for lane in spawner.next_obstacle_lanes():
			var o := OBSTACLE.instantiate()
			o.position = Vector2(_lane_x(lane), spawn_y)
			o.area_entered.connect(_on_obstacle_hit)
			add_child(o)

func _on_coin_hit(_other: Area2D, coin: Node) -> void:
	run_state.add_coin()
	coin.queue_free()

func _on_obstacle_hit(_other: Area2D) -> void:
	run_state.kill()

func _on_died() -> void:
	pass  # HUD handles the death screen in Task 7
```

- [ ] **Step 6: Build `scenes/run.tscn`**

- Root `Node2D` named `Run` + `scripts/run/run_scene.gd`.
- Add a child instance of `scenes/player.tscn` named `Player`, positioned near the bottom-center (e.g. y ≈ 1000, x = 0). Set the Player's `num_lanes`/`lane_spacing` exports to match (3 / 200).
- Optional: a full-screen `ColorRect` background behind everything (light color) so motion is visible.
- Confirm `project.godot` `run/main_scene` points at `res://scenes/run.tscn`.
- Save.

- [ ] **Step 7: Verify by running the game**

Run: `godot scenes/run.tscn`
Expected: obstacle rows and coins scroll down from the top and speed up over time; at least one lane in every obstacle row is always passable; dragging the blob into a coin makes it disappear; dragging into an obstacle freezes spawning/scrolling (run dead). Objects past the bottom despawn (watch the node count stay bounded in the remote scene tree).

- [ ] **Step 8: Run the full unit suite (no regressions)**

Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gexit`
Expected: all logic tests still pass (18 passing).

- [ ] **Step 9: Commit**

```bash
git add scenes/ scripts/entities/ scripts/run/run_scene.gd
git commit -m "feat(m1): scrolling world, spawn loop, coin/obstacle collisions"
```

---

## Task 7: HUD — distance + coins, death screen, restart

**Files:**
- Create: `scenes/hud.tscn`
- Create: `scripts/ui/hud.gd`
- Modify: `scenes/run.tscn` (add HUD instance)
- Modify: `scripts/run/run_scene.gd:_ready, _process, _on_died`

- [ ] **Step 1: Create `scripts/ui/hud.gd`**

```gdscript
class_name Hud
extends CanvasLayer

signal restart_pressed

@onready var _distance_label: Label = $Margin/VBox/DistanceLabel
@onready var _coin_label: Label = $Margin/VBox/CoinLabel
@onready var _death_panel: Control = $DeathPanel
@onready var _restart_button: Button = $DeathPanel/RestartButton

func _ready() -> void:
	_death_panel.visible = false
	_restart_button.pressed.connect(func(): restart_pressed.emit())

func update_stats(distance: float, coins: int) -> void:
	_distance_label.text = "%d m" % int(distance / 100.0)
	_coin_label.text = "Coins: %d" % coins

func show_death(distance: float, coins: int) -> void:
	update_stats(distance, coins)
	_death_panel.visible = true
```

- [ ] **Step 2: Build `scenes/hud.tscn`**

- Root `CanvasLayer` named `Hud` + `scripts/ui/hud.gd`.
- `MarginContainer` `Margin` (top-left, ~24px margins) → `VBoxContainer` `VBox` → two `Label`s named `DistanceLabel` and `CoinLabel`.
- `Control` `DeathPanel` (full-rect, dim background `ColorRect` + a centered `VBoxContainer` with a "Game Over" `Label` and a `Button` named `RestartButton` reading "Play Again").
- Save as `scenes/hud.tscn`.

- [ ] **Step 3: Wire HUD into `scripts/run/run_scene.gd`**

Add a `_hud` reference and update it each frame. Replace the noted sections:

In `_ready()`, append after `_player = $Player`:

```gdscript
	_hud = $Hud
	_hud.restart_pressed.connect(_on_restart)
```

Add the field near the top with the other vars:

```gdscript
var _hud: Hud
```

At the end of `_process(delta)` (still inside the `alive` path), append:

```gdscript
	_hud.update_stats(run_state.distance, run_state.coins)
```

Replace `_on_died()` with:

```gdscript
func _on_died() -> void:
	_hud.show_death(run_state.distance, run_state.coins)

func _on_restart() -> void:
	get_tree().reload_current_scene()
```

- [ ] **Step 4: Add HUD to `scenes/run.tscn`**

- Add a child instance of `scenes/hud.tscn` named `Hud` to the `Run` root.
- Save.

- [ ] **Step 5: Verify by running the game**

Run: `godot scenes/run.tscn`
Expected: distance (in meters) and coin count climb live during the run; collecting coins bumps the counter; crashing shows the "Game Over" panel with final stats; "Play Again" reloads a fresh run from zero.

- [ ] **Step 6: Run the full unit suite (no regressions)**

Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gexit`
Expected: 18 passing.

- [ ] **Step 7: Commit**

```bash
git add scenes/hud.tscn scripts/ui/hud.gd scenes/run.tscn scripts/run/run_scene.gd
git commit -m "feat(m1): HUD stats, game-over panel, restart"
```

---

## Milestone 1 Done — Definition of Complete

- `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -gprefix=test_ -gexit` → all green (18 tests).
- `godot scenes/run.tscn` is playable end to end: lane-swap + jump/roll, scrolling+accelerating world, always-solvable obstacle rows, coin collection with live counter, distance counter, crash → game over → restart.
- All logic lives in tested `RefCounted` units; scenes only wire them. This is the foundation M2 (terrain morph) builds on by swapping the player's visual/form based on the active stretch.

## Notes for Later Milestones (not in scope now)
- **M2** introduces a `StretchManager` (sequences road/water/ramp zones) and form-swapping on the player; the lane/spawn/scroll logic here is reused unchanged.
- **M4** replaces "restart loses coins" with banking `run_state.coins` into a saved profile; keep `RunState` the single source of per-run coins so the save layer reads one place.
- Keep `Spawner` and `DifficultyCurve` seedable/parameterized — per-world tuning in M5 depends on it.
