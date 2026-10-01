extends SceneTree

const MatchModel = preload("res://scripts/match/match_model.gd")
var failure_count := 0

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func() -> void: push_error("Match model test timed out"); quit(1))
	call_deferred("_run")

func _run() -> void:
	var model = MatchModel.new()
	model.begin_match(20260925)
	_assert(model.offers.size() == 8, "initial draft presents eight offers")
	var unique_offers: Dictionary = {}
	for id in model.offers: unique_offers[id] = true
	_assert(unique_offers.size() == 8, "initial offers are distinct")
	var initial_order: Array = model.initial_order.duplicate()
	for _pick in range(4):
		_assert(model.turn_player == initial_order[model.initial_pick_index], "initial ABBA pick order")
		_assert(model.pick(0), "initial offer can be selected")
		if model.initial_pick_index == 1:
			_assert(not model.fuse(101, 102), "initial draft does not allow fusion")
			_assert(not model.discard(initial_order[0], int(model.teams[initial_order[0]][0].token)), "initial draft cannot discard a required starting pick")
	_assert(model.phase == "prep", "four initial picks enter preparation")
	_assert(model.owned_count(0) == 2 and model.owned_count(1) == 2, "initial draft gives two units each")
	var priority_before_draw: int = model.priority_player
	_assert(model.start_battle(), "both teams can enter combat")
	_assert(model.finish_battle("draw"), "combat draw is accepted")
	_assert(model.lives == [5, 5], "draw preserves lives")
	_assert(model.priority_player == priority_before_draw, "draw preserves draft priority")
	model.next_round()
	_assert(model.phase == "draft", "next round opens a fresh draft")
	_assert(model.actions_left == [2, 2], "players with three or more lives get two actions")
	var round_unique: Dictionary = {}
	for id in model.offers: round_unique[id] = true
	_assert(round_unique.size() == 8, "later offers are distinct within the round")
	var first_actor: int = model.turn_player
	_assert(model.pick(0), "normal round pick succeeds")
	_assert(model.turn_player == 1 - first_actor, "draft alternates while both players have actions")
	model.lives[0] = 1
	model.lives[1] = 2
	model.priority_player = 0
	model.teams[0] = [
		{"id": "bear", "active": true, "token": 101},
		{"id": "cheetah", "active": true, "token": 102},
	]
	model.teams[1] = [
		{"id": "monkey", "active": true, "token": 201},
	]
	model._begin_draft(false)
	_assert(model.actions_left == [3, 3], "one-life comeback grants three actions; two lives grants three")
	_assert(model.turn_player == 0, "losing side receives next draft priority")
	_assert(model.fuse(101, 102), "compatible owned level-one units can fuse")
	_assert(model.owned_count(0) == 1 and model.active_count(0) == 1, "fusion consumes both parents and preserves one active slot")
	_assert(model.teams[0][0].id == "bear_cheetah", "fusion creates the expected hybrid")
	_assert(model.actions_left[0] == 2, "fusion consumes exactly one action")
	model.teams[0].append({"id": "monkey", "active": false, "token": 199})
	model.turn_player = 0
	_assert(model.discard(0, 199), "discard is free and removes an owned unit")
	_assert(model.active_count(0) == 1, "discard cannot remove the last active unit")
	_assert(not model.start_battle(), "empty combat rosters cannot start")
	model.teams[0] = [
		{"id": "bear", "active": true, "token": 301},
		{"id": "cheetah", "active": true, "token": 302},
		{"id": "monkey", "active": true, "token": 303},
	]
	model.lives[0] = 2
	model.lives[1] = 5
	model._begin_draft(false)
	_assert(model.actions_left[0] == 3, "two lives grants three actions")
	model.offers.clear()
	model.teams[0] = [{"id": "bear", "active": true, "token": 401}]
	model.turn_player = 0
	_assert(not model.can_act(0), "player with no offer or fusion has no legal action")
	_assert(model.pass_turn(), "pass works when no pick or fusion is legal")
	_assert(model.actions_left[0] == 0, "passing expires remaining actions")
	_assert(model.lives[0] == 2, "draft pass costs no life")
	_assert(model.passed[0], "forced pass is recorded")
	model.phase = "prep"
	model.teams[0].clear()
	for index in range(9):
		model.teams[0].append({"id": "bear", "active": index < 6, "token": 500 + index})
	_assert(model.active_count(0) == 6 and model.bench_count(0) == 3, "roster limit is six active plus three reserve")
	_assert(not model.toggle_active(0, 500), "an active unit cannot be benched while three reserve slots are full")
	_assert(model.swap_active(0, 500, 506), "an active unit can exchange places with a reserve")
	_assert(model.active_count(0) == 6 and model.bench_count(0) == 3, "active/reserve exchange preserves both limits")
	model.teams[0].clear()
	for index in range(8):
		model.teams[0].append({"id": "bear", "active": index < 5, "token": 550 + index})
	_assert(model.toggle_active(0, 557), "five active units can promote a reserve while three are benched")
	_assert(model.active_count(0) == 6 and model.bench_count(0) == 2, "promotion frees one of three reserve slots")
	model.phase = "draft"
	model.teams[0].append({"id": "bear", "active": false, "token": 599})
	model.offers.clear()
	model.offers.append("rabbit")
	model.turn_player = 0
	model.actions_left[0] = 1
	model.actions_left[1] = 0
	_assert(model.can_act(0), "a full roster can discard before selecting a still-open offer")
	_assert(not model.pick(0), "a full roster must free a slot before picking")
	_assert(model.discard(0, 557), "bench unit can be discarded to free a roster slot")
	_assert(model.pick(0), "pick succeeds after free discard")
	_assert(model.owned_count(0) == 9, "discard then pick keeps the roster cap")
	model.phase = "battle"
	model.lives[0] = 1
	_assert(model.finish_battle("B"), "final life loss ends the match")
	_assert(model.phase == "match_over" and model.match_winner == 1, "zero lives immediately declares the match winner")
	if failure_count > 0:
		quit(1)
		return
	var match_flow = MatchModel.new()
	match_flow.begin_match(88)
	for _pick in range(4): match_flow.pick(0)
	for defeat in range(5):
		_assert(match_flow.start_battle(), "full match starts every next battle")
		_assert(match_flow.finish_battle("A"), "winner removes one opposing life")
		if defeat == 4: break
		_assert(match_flow.lives[1] == 4 - defeat, "loss removes exactly one life")
		match_flow.next_round()
		var expected_actions := 2 if match_flow.lives[1] >= 3 else 3
		_assert(match_flow.actions_left[1] == expected_actions, "comeback action count rises at two and one life")
		match_flow.phase = "prep" # Draft actions are covered by the detailed turn tests above.
	_assert(match_flow.phase == "match_over" and match_flow.match_winner == 0, "five losses complete a full match")
	if failure_count > 0:
		quit(1)
		return
	print("MATCH_MODEL_TESTS_OK")
	quit(0)

func _assert(condition: bool, description: String) -> void:
	if not condition:
		failure_count += 1
		push_error("Match model test failed: " + description)
