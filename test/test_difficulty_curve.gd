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
