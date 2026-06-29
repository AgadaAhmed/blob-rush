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
