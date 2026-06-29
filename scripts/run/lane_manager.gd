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
