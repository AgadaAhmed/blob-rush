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
