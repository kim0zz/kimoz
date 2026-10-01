extends SceneTree

const MatchScene = preload("res://scenes/match/match.tscn")
var failure_count := 0

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func() -> void: push_error("Match UI smoke timed out"); quit(1))
	call_deferred("_run")

func _run() -> void:
	var screen: Node = MatchScene.instantiate()
	root.add_child(screen)
	await process_frame
	_assert(screen.model.phase == "initial_draft", "match screen opens in initial draft")
	_assert(screen.model.offers.size() == 4, "initial draft has visible shared offers")
	screen.call("_enter_lab")
	_assert(screen.arena.visible and screen.arena.get("hud").visible, "Combat Lab remains accessible")
	screen.call("_exit_lab")
	_assert(not screen.arena.visible and not screen.arena.get("hud").visible, "return from Combat Lab restores match screen")
	for _pick in range(4):
		_assert(screen.model.pick(0), "offer selection succeeds")
	screen.call("_refresh")
	_assert(screen.model.phase == "prep", "initial picks open preparation")
	screen.call("_start_battle")
	await process_frame
	_assert(screen.model.phase == "battle", "preparation launches a match battle")
	_assert(screen.arena.visible and not screen.arena.get("hud").visible, "battle shows arena without Combat Lab controls")
	_assert(screen.arena.get("sim").result == "running", "battle starts a fresh live simulation")
	_assert(is_zero_approx(screen.backdrop.color.a), "battle arena is not covered by the match backdrop")
	var lab_button: Button = screen.lab_button
	_assert(lab_button.disabled, "Combat Lab cannot be entered during a match battle")
	if failure_count > 0:
		quit(1)
		return
	print("MATCH_UI_SMOKE_OK")
	quit(0)

func _assert(condition: bool, description: String) -> void:
	if not condition:
		failure_count += 1
		push_error("Match UI smoke failed: " + description)
