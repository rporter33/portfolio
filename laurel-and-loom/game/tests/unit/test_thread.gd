extends TestCase


func test_same_seed_same_thread() -> void:
	var a := FateThread.new(42)
	var b := FateThread.new(42)
	for i in 50:
		eq(a.draw(), b.draw())


func test_beads_in_range() -> void:
	var t := FateThread.new(7)
	var lo := 100
	var hi := 1
	for i in 2000:
		var v := t.draw()
		lo = mini(lo, v)
		hi = maxi(hi, v)
	check(lo >= 1 and hi <= 100, "beads stay in 1..100")
	check(lo <= 2 and hi >= 99, "and cover the range")


func test_peek_does_not_draw() -> void:
	var t := FateThread.new(3)
	var first := t.peek(0)
	var third := t.peek(2)
	eq(t.drawn, 0)
	eq(t.draw(), first)
	t.draw()
	eq(t.draw(), third)


func test_clone_continues_identically() -> void:
	var t := FateThread.new(99)
	for i in 5:
		t.draw()
	t.peek(4)
	var c := t.clone()
	for i in 20:
		eq(c.draw(), t.draw())


func test_cut_and_turn() -> void:
	var t := FateThread.new(11)
	var b0 := t.peek(0)
	var b1 := t.peek(1)
	t.cut()
	eq(t.peek(0), b1, "cut drops the front bead")
	eq(t.drawn, 0, "cutting isn't drawing")
	t.turn()
	eq(t.peek(0), 101 - b1, "turn inverts the front bead")
	check(b0 >= 1)


func test_windows() -> void:
	var t := FateThread.new(1)
	check(t.is_exact(2) and not t.is_exact(3))
	check(t.is_visible(5) and not t.is_visible(6))
	t.measured = true
	check(t.is_exact(5), "measure shows the omens exactly")
	check(not t.is_visible(6), "but no further")


func test_omens() -> void:
	eq(FateThread.omen_of(1), FateThread.Omen.FAIR)
	eq(FateThread.omen_of(33), FateThread.Omen.FAIR)
	eq(FateThread.omen_of(34), FateThread.Omen.MIDDLING)
	eq(FateThread.omen_of(66), FateThread.Omen.MIDDLING)
	eq(FateThread.omen_of(67), FateThread.Omen.ILL)
	eq(FateThread.omen_of(100), FateThread.Omen.ILL)
