extends SceneTree
const Model = preload("res://scripts/match/match_model.gd")
const Wire = preload("res://scripts/network/match_wire.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)
func next_result(model: RefCounted, result: String) -> void:
	# Only bypass the choices, not life loss or draft allocation.
	model.phase = "prep"
	check(model.start_battle(), "Start battle")
	check(model.finish_battle(result), "Accept result")
	model.next_round()
func run() -> void:
	var model := Model.new()
	model.begin_match(42)
	while model.phase == "initial_draft": model.pick(0)
	for i in range(2):
		next_result(model, "B")
		check(model.actions_left == [2, 2], "No bonus above two HP")
	next_result(model, "B")
	check(model.lives[0] == 2 and model.actions_left == [3, 2], "First two-HP bonus")
	next_result(model, "draw")
	check(model.actions_left == [2, 2], "Draw at two HP cannot renew bonus")
	next_result(model, "A")
	check(model.actions_left == [2, 2], "Win at two HP cannot renew bonus")
	next_result(model, "B")
	check(model.lives[0] == 1 and model.actions_left == [3, 2], "Separate one-HP bonus")
	# Second side earns its two-HP bonus while first side remains on one HP.
	next_result(model, "A")
	next_result(model, "A")
	check(model.actions_left == [2, 3], "Player bonuses independent")
	var guest := Model.new()
	Wire.apply(guest, bytes_to_var(var_to_bytes(Wire.capture(model))))
	next_result(guest, "draw")
	check(guest.actions_left == [2, 2], "Network snapshot retains spent thresholds")
	next_result(model, "draw")
	check(model.actions_left == [2, 2], "Repeated low-HP round is normal")
	next_result(model, "A")
	check(model.actions_left == [2, 3], "Other player's independent one-HP bonus")
	next_result(model, "draw")
	check(model.actions_left == [2, 2], "No recurring one-HP bonuses")
	model.begin_match(42)
	check(model.comeback_used == [[], []] and model.actions_left == [2, 2], "Rematch resets bonuses")
	while model.phase == "initial_draft": model.pick(0)
	for i in range(3): next_result(model, "B")
	check(model.actions_left == [3, 2], "New match can award bonus again")
	print("COMEBACK TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
