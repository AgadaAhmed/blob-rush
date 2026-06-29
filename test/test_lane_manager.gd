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
