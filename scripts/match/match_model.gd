class_name ZooMatchModel
extends RefCounted
## State and rules for one local hotseat match. No scene or wall-clock dependencies.

const Catalog = preload("res://scripts/data/catalog.gd")

const STARTING_LIVES := 5
const MAX_ACTIVE := 6
const MAX_OWNED := 9

var rng := RandomNumberGenerator.new()
var lives: Array[int] = [STARTING_LIVES, STARTING_LIVES]
var teams: Array = [[], []] # Each entry is {"id": String, "active": bool, "token": int}.
var offers: Array[String] = []
var actions_left: Array[int] = [0, 0]
var comeback_used: Array = [[], []] # Life thresholds already awarded, per player.
var passed: Array[bool] = [false, false]
var turn_player := 0
var priority_player := 0
var round_number := 1
var phase := ""
var initial_order: Array[int] = []
var initial_pick_index := 0
var next_token := 1
var last_result := ""
var match_winner := -1

func begin_match(seed_value: int = -1) -> void:
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	lives = [STARTING_LIVES, STARTING_LIVES]
	teams = [[], []]
	comeback_used = [[], []]
	priority_player = rng.randi_range(0, 1)
	round_number = 1
	next_token = 1
	last_result = ""
	match_winner = -1
	_begin_draft(true)

func _begin_draft(initial: bool) -> void:
	phase = "initial_draft" if initial else "draft"
	passed = [false, false]
	if initial:
		actions_left = [2, 2]
		initial_order = [priority_player, 1 - priority_player, 1 - priority_player, priority_player]
		initial_pick_index = 0
	else:
		actions_left = [_actions_for_player(0), _actions_for_player(1)]
	turn_player = priority_player
	offers.assign(Catalog.ids())
	if not initial:
		_advance_to_actionable_player()

func _actions_for_lives(remaining_lives: int) -> int:
	if remaining_lives <= 0:
		return 0
	return 2

func _actions_for_player(player: int) -> int:
	var count := _actions_for_lives(lives[player])
	if lives[player] in [1, 2] and not comeback_used[player].has(lives[player]):
		comeback_used[player].append(lives[player])
		count += 1
	return count

func active_count(player: int) -> int:
	var count := 0
	for unit in teams[player]:
		if unit.active: count += 1
	return count

func owned_count(player: int) -> int:
	return teams[player].size()

func bench_count(player: int) -> int:
	return owned_count(player) - active_count(player)

func has_pick(player: int = -1) -> bool:
	var owner := turn_player if player < 0 else player
	# Offers keep the player actionable at a full roster so they can discard for free first.
	return offers.size() > 0

func compatible_pair(first_id: String, second_id: String) -> String:
	if first_id == second_id:
		return ""
	return str(Catalog.fusion(first_id, second_id))

func can_fuse(player: int = -1) -> bool:
	if phase == "initial_draft" or phase != "draft":
		return false
	var owner := turn_player if player < 0 else player
	var owned: Array = teams[owner]
	for left in range(owned.size()):
		for right in range(left + 1, owned.size()):
			if not compatible_pair(str(owned[left].id), str(owned[right].id)).is_empty():
				return true
	return false

func can_act(player: int = -1) -> bool:
	var owner := turn_player if player < 0 else player
	return has_pick(owner) or can_fuse(owner)

func pick(offer_index: int) -> bool:
	if phase not in ["initial_draft", "draft"] or not has_pick(turn_player): return false
	if actions_left[turn_player] <= 0: return false
	if owned_count(turn_player) >= MAX_OWNED: return false
	if offer_index < 0 or offer_index >= offers.size(): return false
	if active_count(turn_player) >= MAX_ACTIVE and bench_count(turn_player) >= 3: return false
	var id: String = offers[offer_index]
	_add_unit(turn_player, id, active_count(turn_player) < MAX_ACTIVE)
	offers.remove_at(offer_index)
	_consume_action(turn_player)
	return true

func fuse(first_token: int, second_token: int) -> bool:
	if actions_left[turn_player] <= 0 or not can_fuse(turn_player) or first_token == second_token: return false
	var left_index := _team_index_for_token(turn_player, first_token)
	var right_index := _team_index_for_token(turn_player, second_token)
	if left_index < 0 or right_index < 0: return false
	var owned: Array = teams[turn_player]
	var left: Dictionary = owned[left_index]
	var right: Dictionary = owned[right_index]
	var hybrid := compatible_pair(str(left.id), str(right.id))
	if hybrid.is_empty(): return false
	var keep_active := bool(left.active) or bool(right.active)
	var high := maxi(left_index, right_index)
	var low := mini(left_index, right_index)
	owned.remove_at(high)
	owned.remove_at(low)
	_add_unit(turn_player, hybrid, keep_active)
	_consume_action(turn_player)
	return true

func discard(player: int, token: int) -> bool:
	if player < 0 or player > 1 or phase not in ["draft", "prep"]: return false
	if phase == "draft" and player != turn_player: return false
	var index := _team_index_for_token(player, token)
	if index < 0: return false
	var unit: Dictionary = teams[player][index]
	if unit.active and active_count(player) <= 1: return false
	teams[player].remove_at(index)
	return true

func toggle_active(player: int, token: int) -> bool:
	if phase != "prep" or player < 0 or player > 1: return false
	var index := _team_index_for_token(player, token)
	if index < 0: return false
	var unit: Dictionary = teams[player][index]
	if unit.active:
		if active_count(player) <= 1: return false
		if bench_count(player) >= 3: return false
		unit.active = false
	else:
		if active_count(player) >= MAX_ACTIVE: return false
		unit.active = true
	return true

func swap_active(player: int, first_token: int, second_token: int) -> bool:
	if phase != "prep" or player < 0 or player > 1 or first_token == second_token: return false
	var first_index := _team_index_for_token(player, first_token)
	var second_index := _team_index_for_token(player, second_token)
	if first_index < 0 or second_index < 0: return false
	var first: Dictionary = teams[player][first_index]
	var second: Dictionary = teams[player][second_index]
	if bool(first.active) == bool(second.active): return false
	first.active = not first.active
	second.active = not second.active
	return true

func move_unit(player: int, from_index: int, to_index: int) -> bool:
	if phase != "prep" or player < 0 or player > 1: return false
	if from_index < 0 or to_index < 0 or from_index >= teams[player].size() or to_index >= teams[player].size(): return false
	var item: Variant = teams[player].pop_at(from_index)
	teams[player].insert(to_index, item)
	return true

func pass_turn() -> bool:
	if phase != "draft" or can_act(turn_player): return false
	passed[turn_player] = true
	actions_left[turn_player] = 0
	_advance_to_actionable_player()
	return true

func _add_unit(player: int, id: String, active: bool) -> void:
	teams[player].append({"id": id, "active": active, "token": next_token})
	next_token += 1

func _consume_action(player: int) -> void:
	if phase == "initial_draft":
		actions_left[player] = maxi(0, actions_left[player] - 1)
		initial_pick_index += 1
		if initial_pick_index >= initial_order.size():
			phase = "prep"
			return
		turn_player = initial_order[initial_pick_index]
		return
	actions_left[player] = maxi(0, actions_left[player] - 1)
	_advance_to_actionable_player(player)

func _advance_to_actionable_player(previous: int = -1) -> void:
	if phase != "draft": return
	for player in range(2):
		if actions_left[player] > 0 and not can_act(player):
			passed[player] = true
			actions_left[player] = 0
	if actions_left[0] == 0 and actions_left[1] == 0:
		phase = "prep"
		return
	var preferred := 1 - previous if previous >= 0 else turn_player
	if actions_left[preferred] > 0 and can_act(preferred):
		turn_player = preferred
	elif actions_left[1 - preferred] > 0 and can_act(1 - preferred):
		turn_player = 1 - preferred
	else:
		phase = "prep"

func start_battle() -> bool:
	if phase != "prep" or active_count(0) == 0 or active_count(1) == 0: return false
	phase = "battle"
	return true

func finish_battle(result: String) -> bool:
	if phase != "battle" or result not in ["A", "B", "draw"]: return false
	last_result = result
	if result == "A":
		lives[1] -= 1
		priority_player = 1
	elif result == "B":
		lives[0] -= 1
		priority_player = 0
	if lives[0] <= 0: match_winner = 1
	if lives[1] <= 0: match_winner = 0
	if match_winner >= 0:
		phase = "match_over"
	else:
		round_number += 1
		phase = "result"
	return true

func next_round() -> void:
	if phase != "result": return
	_begin_draft(false)

func _team_index_for_token(player: int, token: int) -> int:
	for index in range(teams[player].size()):
		if int(teams[player][index].token) == token: return index
	return -1

func _is_hybrid(id: String) -> bool:
	return Catalog.hybrid_ids().has(id)

func active_ids(player: int) -> Array[String]:
	var ids: Array[String] = []
	for unit in teams[player]:
		if unit.active: ids.append(str(unit.id))
	return ids
