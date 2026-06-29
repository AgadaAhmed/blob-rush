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
