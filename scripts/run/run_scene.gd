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
var _hud: Hud
var _distance_since_spawn: float = 0.0

func _ready() -> void:
	spawner = Spawner.new(randi(), num_lanes)
	lanes = LaneManager.new(num_lanes, lane_spacing, 1)
	_player = $Player
	_hud = $Hud
	_hud.restart_pressed.connect(_on_restart)
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
	_hud.update_stats(run_state.distance, run_state.coins)

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
	_hud.show_death(run_state.distance, run_state.coins)

func _on_restart() -> void:
	get_tree().reload_current_scene()
