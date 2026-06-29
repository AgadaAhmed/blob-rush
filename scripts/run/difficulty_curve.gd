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
