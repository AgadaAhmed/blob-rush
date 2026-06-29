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
