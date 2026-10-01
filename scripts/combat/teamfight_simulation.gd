class_name TeamfightSimulation
extends CombatSimulation
## Combat Lab teamfight mode. All roster edits live on cloned definitions.

const TeamfightData = preload("res://scripts/data/teamfight_definitions.gd")

const PLAN_TICKS: int = 150 # Utility intent is reconsidered every 2.5 seconds.
const RETREAT_THRESHOLD: float = 0.36
const RETREAT_RELEASE_TICKS: int = 36
const SHIELD_CAP: float = 52.0

var healing_total: float = 0.0
var shield_total: float = 0.0
var interrupt_total: int = 0
var retreat_total: int = 0
var _collect_effects := false
var _support_effects: Array[Dictionary] = []
var _observed_pressure: Dictionary = {}
var _observed_targets: Dictionary = {}

func setup(a: Array, b: Array, seed: int = 1, options: Dictionary = {}) -> bool:
	_collect_effects = false
	_support_effects.clear()
	_observed_pressure.clear()
	_observed_targets.clear()
	healing_total = 0.0
	shield_total = 0.0
	interrupt_total = 0
	retreat_total = 0
	var setup_options: Dictionary = options.duplicate(true)
	var mode_definitions: Dictionary = TeamfightData.definitions()
	mode_definitions.merge(options.get("definitions", {}), true)
	setup_options["definitions"] = mode_definitions
	if not super.setup(a, b, seed, setup_options):
		return false
	for u: Dictionary in units:
		u["teamfight_role"] = TeamfightData.role(str(u.id))
		u["teamfight_plan"] = {"target": -1, "until": 0, "reason": "spawn", "kind": "spawn"}
		u["shield_hp"] = 0.0
		u["healing_done"] = 0.0
		u["shield_absorbed"] = 0.0
		u["interrupts"] = 0
		u["retreats"] = 0
		u["target_reasons"] = {}
		u["shield_sources"] = {}
		u["taunt_target"] = -1
		u["taunt_end"] = 0
		u["teamfight_retreating"] = false
		u["retreat_anchor"] = -1
		u["retreat_last_pressure"] = 0
		u["retreat_ready"] = 0
		u["evasion_pending"] = -1
		u["evasion_threat"] = -1
		u["evasion_destination"] = u.pos
	return true

func step() -> void:
	# Everyone reads the same visible intentions for this simulation tick.
	_observed_pressure.clear()
	_observed_targets.clear()
	for unit: Dictionary in units:
		if not unit.alive: continue
		_observed_targets[unit.uid] = int(unit.target)
		var targets: Array[int] = [int(unit.target)]
		if not unit.action.is_empty() and int(unit.action.get("target", -1)) not in targets:
			targets.append(int(unit.action.get("target", -1)))
		for target in targets:
			if _living_target(target) and units[target].team != unit.team:
				if not _observed_pressure.has(target): _observed_pressure[target] = []
				_observed_pressure[target].append(unit.uid)
	_collect_effects = true
	super.step()
	_collect_effects = false

func resolve_hits(hits: Array) -> void:
	# Apply support after all units have advanced their actions, before damage.
	# This prevents the first team in the array from cancelling same-tick casts
	# on the other team while its own same-tick hits have already been queued.
	_collect_effects = false
	for effect: Dictionary in _support_effects:
		var source: Dictionary = units[effect.source]
		var target: Dictionary = units[effect.target] if _living_target(effect.target) else {}
		match str(effect.kind):
			"heal": _apply_heal(source, target, effect.skill)
			"shield": _grant_shield(source, target, effect.skill, effect.amount, effect.event_kind)
			"taunt": _apply_taunt(source, target, effect.skill)
			"interrupt":
				if not target.is_empty(): _interrupt_target(source, target, effect.skill, effect.duration)
	_support_effects.clear()
	super.resolve_hits(hits)
	_collect_effects = true

func _observed_target(unit: Dictionary) -> int:
	return int(_observed_targets.get(unit.uid, unit.target)) if _collect_effects else int(unit.target)

func _set_target(u: Dictionary, target: int, reason: String) -> void:
	var previous: int = int(u.target)
	if reason == "blocked_by_enemy" and _living_target(target):
		u.teamfight_plan = {"target":target, "until":tick + PLAN_TICKS, "reason":reason, "kind":"engage"}
	super._set_target(u, target, reason)
	if previous != target and not reason.is_empty():
		u.target_reasons[reason] = int(u.target_reasons.get(reason, 0)) + 1

func _choose_target(u: Dictionary) -> int:
	var taunt_target: int = int(u.get("taunt_target", -1))
	if tick < int(u.get("taunt_end", 0)) and _living_target(taunt_target) and units[taunt_target].team != u.team:
		return taunt_target
	var plan: Dictionary = u.get("teamfight_plan", {})
	var planned: int = int(plan.get("target", -1))
	var candidates: Array = _target_candidates(u)
	if tick < int(plan.get("until", 0)) and _living_target(planned) and units[planned] in candidates:
		return planned
	if candidates.is_empty():
		return -1
	var best: int = -1
	var best_score: float = -INF
	var reason := "role_priority"
	for enemy: Dictionary in candidates:
		var gap: float = edge_distance(u, enemy)
		var score: float = -gap
		# A retreat is not an aggro wipe. Only reconsider at the normal plan boundary,
		# and only abandon pursuit when another opponent remains available.
		if bool(enemy.get("teamfight_retreating", false)) and candidates.size() > 1 and gap > float(u.definition.attack_range) + 35.0:
			score -= 20.0 if str(u.teamfight_role) == "eagle_assassin" else 160.0
		if int(u.target) == int(enemy.uid): score += 20.0
		match str(u.teamfight_role):
			"cheetah_dps":
				if float(enemy.hp) / float(enemy.definition.max_hp) < 0.42: score += 115.0
				if _incoming_count(enemy) > 0: score += 14.0
			"eagle_assassin":
				score += 0.35 * gap
				if enemy.definition.role == "ranged": score += 48.0
			"skunk_controller":
				for other: Dictionary in candidates:
					if Vector2(enemy.pos).distance_to(other.pos) <= 115.0: score += 13.0
			"hippo_tank":
				var victim: int = _observed_target(enemy)
				if _living_target(victim) and units[victim].team == u.team and victim != u.uid:
					score += 110.0
		if score > best_score + TARGET_TIE_EPSILON or (absf(score - best_score) <= TARGET_TIE_EPSILON and (best < 0 or _tie(enemy, u) < _tie(units[best], u))):
			best = enemy.uid
			best_score = score
	if best >= 0:
		u.teamfight_plan = {"target": best, "until": tick + PLAN_TICKS, "reason": reason, "kind": "retreat" if bool(u.teamfight_retreating) else "engage"}
		_emit({"kind": "decision", "source": u.uid, "target": best, "plan_target": best,
			"pos": u.pos, "reason": reason, "state": "engage", "teamfight_role": u.teamfight_role})
	return best

func _incoming_count(target: Dictionary) -> int:
	if _collect_effects: return _observed_pressure.get(target.uid, []).size()
	var count := 0
	for enemy: Dictionary in units:
		if not enemy.alive or enemy.team == target.team: continue
		if int(enemy.target) == int(target.uid) or (not enemy.action.is_empty() and int(enemy.action.get("target", -1)) == int(target.uid)):
			count += 1
	return count

func _override_movement(u: Dictionary, _target: Dictionary, _distance: float) -> Variant:
	var role := str(u.teamfight_role)
	var pressured: Array = _current_attackers(u)
	var anchor_uid := _protected_anchor(u)
	var fragile := role in ["monkey_healer", "skunk_controller", "eagle_assassin", "cheetah_dps"]
	if fragile and tick >= int(u.retreat_ready) and float(u.hp) / float(u.definition.max_hp) <= RETREAT_THRESHOLD and not pressured.is_empty() and anchor_uid >= 0:
		if not bool(u.teamfight_retreating):
			u.teamfight_retreating = true
			u.retreats += 1
			retreat_total += 1
			u.retreat_anchor = anchor_uid
			_emit({"kind":"retreat_start", "source":u.uid, "target":anchor_uid, "pos":u.pos})
	if bool(u.teamfight_retreating):
		if not pressured.is_empty(): u.retreat_last_pressure = tick
		if anchor_uid < 0 or (pressured.is_empty() and tick - int(u.retreat_last_pressure) >= RETREAT_RELEASE_TICKS):
			u.teamfight_retreating = false
			u.retreat_ready = tick + PLAN_TICKS
			u.teamfight_plan.kind = "engage"
			_emit({"kind":"retreat_end", "source":u.uid, "target":u.retreat_anchor, "pos":u.pos})
		else:
			u.teamfight_plan.kind = "retreat"
			var anchor: Dictionary = units[anchor_uid]
			var threat_pos: Vector2 = Vector2(anchor.pos) + (Vector2.RIGHT if u.team == 0 else Vector2.LEFT)
			var threat_gap := INF
			for enemy: Dictionary in _enemies(u):
				var gap := Vector2(anchor.pos).distance_to(enemy.pos)
				if gap < threat_gap:
					threat_gap = gap
					threat_pos = enemy.pos
			var away := (Vector2(anchor.pos) - threat_pos).normalized()
			var destination: Vector2 = Motion.clamp_position(Vector2(anchor.pos) + away * 90.0, u.definition.radius, ARENA_SIZE)
			return (destination - Vector2(u.pos)).normalized() if Vector2(u.pos).distance_to(destination) > 12.0 else Vector2.ZERO
	# Keep the support line distinct from the front. A caught support still fights;
	# this is positioning, not permanent kiting or an automatic aggro break.
	if role == "monkey_healer":
		var injured := _most_injured_ally(u, INF)
		if injured >= 0 and edge_distance(u, units[injured]) > 220.0:
			u.teamfight_plan.kind = "support"
			return (Vector2(units[injured].pos) - Vector2(u.pos)).normalized()
		if anchor_uid >= 0: return _support_position(u, units[anchor_uid], 155.0)
	elif role == "hedgehog_shield":
		var allies: Array = units.filter(func(ally: Dictionary) -> bool: return ally.alive and ally.team == u.team and ally.uid != u.uid)
		var protected := _most_pressured_ally(u, allies, false)
		if protected < 0: protected = anchor_uid
		if protected >= 0: return _support_position(u, units[protected], 90.0)
	return null

func _support_position(u: Dictionary, ally: Dictionary, spacing: float) -> Variant:
	var closest := _nearest(u)
	if closest >= 0 and edge_distance(u, units[closest]) <= 16.0: return null
	var threat: int = int(ally.target)
	if not _living_target(threat) or units[threat].team == ally.team: threat = _nearest(ally)
	if threat < 0: return null
	var away := (Vector2(ally.pos) - Vector2(units[threat].pos)).normalized()
	var lateral := away.orthogonal() * float((int(u.slot) % 3) - 1) * 42.0
	var destination: Vector2 = Motion.clamp_position(Vector2(ally.pos) + away * spacing + lateral, u.definition.radius, ARENA_SIZE)
	u.teamfight_plan.kind = "support" if u.id == "monkey" else "protect"
	return (destination - Vector2(u.pos)).normalized() if Vector2(u.pos).distance_to(destination) > 22.0 else Vector2.ZERO

func _current_attackers(u: Dictionary) -> Array:
	var attackers: Array = []
	for enemy: Dictionary in units:
		if not enemy.alive or enemy.team == u.team: continue
		if (_collect_effects and enemy.uid in _observed_pressure.get(u.uid, [])) or (not _collect_effects and (int(enemy.target) == int(u.uid) or (not enemy.action.is_empty() and int(enemy.action.get("target", -1)) == int(u.uid)))):
			attackers.append(enemy)
	var recent: Dictionary = u.recent_attackers
	for attacker_uid in recent:
		if _living_target(int(attacker_uid)) and units[int(attacker_uid)].team != u.team and tick - int(recent[attacker_uid]) <= ticks(1.2):
			if units[int(attacker_uid)] not in attackers: attackers.append(units[int(attacker_uid)])
	return attackers

func _protected_anchor(u: Dictionary) -> int:
	var best := -1
	var best_distance := INF
	for ally: Dictionary in units:
		if not ally.alive or ally.team != u.team or ally.uid == u.uid: continue
		if ally.teamfight_role not in ["hippo_tank", "hedgehog_shield"]: continue
		var gap := Vector2(u.pos).distance_to(ally.pos)
		if gap < best_distance:
			best = ally.uid
			best_distance = gap
	return best

func _try_skill(u: Dictionary) -> bool:
	if skills_disabled: return false
	if str(u.teamfight_role) == "eagle_assassin" and _try_evasion(u):
		return true
	if str(u.teamfight_role) == "eagle_assassin":
		for skill: Resource in u.definition.skills:
			if str(skill.id) == "tf_eagle_dive" and tick >= int(u.cooldowns.get(skill.id, 0)):
				_set_target(u, _farthest(u), "dive_farthest")
				if _living_target(u.target):
					_start_skill(u, skill)
					return true
	for skill: Resource in u.definition.skills:
		var spec: Dictionary = TeamfightData.skill_spec(str(skill.id))
		if spec.is_empty() or str(spec.kind) in ["dive", "evade"]: continue
		if tick < int(u.cooldowns.get(skill.id, 0)): continue
		var selected: int = _select_skill_target(u, skill, spec)
		if selected < 0: continue
		if selected >= 0 and edge_distance(u, units[selected]) > float(skill.range) + 0.05: continue
		u["teamfight_cast_target"] = selected
		_start_skill(u, skill)
		return true
	return false

func _select_skill_target(u: Dictionary, skill: Resource, spec: Dictionary) -> int:
	var kind := str(spec.kind)
	var allies: Array = []
	var enemies: Array = []
	for other: Dictionary in units:
		if not other.alive: continue
		var gap := Vector2(u.pos).distance_to(other.pos)
		if other.team == u.team and other.uid != u.uid and gap <= float(skill.range) + u.definition.radius:
			allies.append(other)
		elif other.team != u.team and gap <= maxf(float(skill.range), u.definition.attack_range) + u.definition.radius:
			enemies.append(other)
	match kind:
		"taunt":
			var pressured_ally := -1
			var pressure_score := 0
			for ally: Dictionary in units:
				if not ally.alive or ally.team != u.team or ally.uid == u.uid: continue
				if Vector2(u.pos).distance_to(ally.pos) > 185.0: continue
				var pressure := _incoming_count(ally)
				if pressure > pressure_score:
					pressured_ally = ally.uid
					pressure_score = pressure
			return pressured_ally if pressure_score > 0 else -2
		"guard":
			var ally := _most_pressured_ally(u, allies, false)
			return ally if ally >= 0 else -2
		"heal":
			var ally := _most_injured_ally(u, float(skill.range))
			return ally if ally >= 0 else -2
		"interrupt":
			var target := _nearest_action_enemy_in_range(u, float(skill.range))
			return target if target >= 0 else -2
		"shield":
			var ally := _most_pressured_ally(u, allies, false)
			return ally if ally >= 0 else -2
		"peel":
			var target := _nearest_attacker_to_allies(u, float(skill.range))
			return target if target >= 0 else -2
		"flurry":
			return _nearest_in_range(u, float(skill.range), false)
		"finisher":
			var enemy := _nearest_in_range(u, float(skill.range), false)
			return enemy if enemy >= 0 and float(units[enemy].hp) / float(units[enemy].definition.max_hp) <= 0.7 else -2
		"trail":
			return _nearest_in_range(u, float(skill.range), true)
		"area_stun":
			var in_area: Array = _enemies(u).filter(func(enemy: Dictionary) -> bool: return edge_distance(u, enemy) <= skill.range)
			if in_area.size() >= 2: return int(in_area[0].uid)
			for enemy: Dictionary in in_area:
				var victim: int = _observed_target(enemy)
				if _living_target(victim) and units[victim].team == u.team and float(units[victim].hp) / float(units[victim].definition.max_hp) < 0.5:
					return int(enemy.uid)
			return -2
	return -2

func _most_injured_ally(u: Dictionary, range_value: float = 260.0) -> int:
	var best := -1
	var score := -INF
	for ally: Dictionary in units:
		if not ally.alive or ally.team != u.team or ally.uid == u.uid: continue
		var missing: float = float(ally.definition.max_hp) - float(ally.hp)
		if missing < 12.0 or edge_distance(u, ally) > range_value: continue
		var ratio: float = float(ally.hp) / float(ally.definition.max_hp)
		var pressure := _incoming_count(ally)
		var candidate := missing + float(pressure) * 17.0 + (1.0 - ratio) * 22.0
		if candidate > score:
			best = ally.uid
			score = candidate
	return best

func _most_pressured_ally(u: Dictionary, allies: Array, allow_self: bool) -> int:
	var best: int = int(u.uid) if allow_self else -1
	var best_score := -INF
	if allow_self:
		best_score = (1.0 - float(u.hp) / float(u.definition.max_hp)) * 65.0 + _incoming_count(u) * 23.0
	for ally: Dictionary in allies:
		if float(ally.shield_hp) >= 40.0 or _current_attackers(ally).is_empty(): continue
		var candidate := (1.0 - float(ally.hp) / float(ally.definition.max_hp)) * 65.0 + _incoming_count(ally) * 23.0
		if candidate > best_score:
			best = ally.uid
			best_score = candidate
	return best if best_score >= 16.0 else -1

func _nearest_action_enemy_in_range(u: Dictionary, range_value: float) -> int:
	var best := -1
	var gap := INF
	for enemy: Dictionary in _enemies(u):
		if enemy.action.is_empty(): continue
		var candidate := edge_distance(u, enemy)
		if candidate <= range_value and candidate < gap:
			best = enemy.uid
			gap = candidate
	return best

func _nearest_attacker_to_allies(u: Dictionary, range_value: float) -> int:
	var best := -1
	var best_gap := INF
	for enemy: Dictionary in _enemies(u):
		var gap := edge_distance(u, enemy)
		if gap > range_value: continue
		for ally: Dictionary in units:
			if ally.alive and ally.team == u.team and ally.uid != u.uid and (int(enemy.target) == int(ally.uid) or (not enemy.action.is_empty() and int(enemy.action.get("target", -1)) == int(ally.uid))):
				if gap < best_gap:
					best = enemy.uid
					best_gap = gap
	return best

func _nearest_in_range(u: Dictionary, range_value: float, include_cluster: bool) -> int:
	var best := -1
	var best_score := -INF
	for enemy: Dictionary in _enemies(u):
		var gap := edge_distance(u, enemy)
		if gap > range_value: continue
		var score := -gap
		if include_cluster:
			for other: Dictionary in _enemies(u):
				if Vector2(enemy.pos).distance_to(other.pos) <= 90.0: score += 20.0
		if score > best_score:
			best = enemy.uid
			best_score = score
	return best

func _start_skill(u: Dictionary, skill: Resource) -> void:
	var spec := TeamfightData.skill_spec(str(skill.id))
	var custom_target: int = int(u.get("teamfight_cast_target", -1))
	super._start_skill(u, skill)
	if events.size() > 0 and str(events.back().get("kind", "")) == "skill_start":
		events.back()["teamfight_role"] = u.teamfight_role
		events.back()["skill_label"] = str(spec.get("label", skill.id))
		events.back()["prep_target"] = custom_target if custom_target >= 0 else int(u.target)
		if custom_target >= 0: events.back()["target"] = custom_target
		if trace_enabled and not trace.is_empty(): trace[-1] = events.back().duplicate(true)
	if not spec.is_empty() and str(spec.kind) not in ["dive", "evade", "trail"]:
		u.action["teamfight_kind"] = str(spec.kind)
		u.action["impact_target"] = custom_target
		u.action["teamfight_label"] = str(spec.label)
		if custom_target >= 0: u.action.target = custom_target
	if str(skill.id) == "tf_eagle_evade":
		u.action["teamfight_kind"] = "evade"
	u.erase("teamfight_cast_target")

func _process_action(u: Dictionary, hits: Array, desired: Array[Vector2]) -> void:
	if u.action.is_empty(): return
	var kind := str(u.action.get("teamfight_kind", ""))
	if kind.is_empty():
		super._process_action(u, hits, desired)
		return
	var action: Dictionary = u.action
	var skill: Resource = action.skill
	if kind == "evade":
		var progress := clampf(float(tick - int(action.start)) / maxf(1.0, float(int(action.end) - int(action.start))), 0.0, 1.0)
		desired[u.uid] = Motion.interpolated(action.origin, action.evade_destination, progress, ARENA_SIZE)
		u.state = "dash"
		if tick >= int(action.end):
			_emit({"kind": "decision", "source": u.uid, "target": action.get("threat", -1), "plan_target": u.target,
				"pos": u.pos, "reason": "side_hop_complete", "state": "evade", "teamfight_role": u.teamfight_role})
			_finish_action(u)
		return
	if tick >= int(action.next) and int(action.remaining) > 0:
		var target_uid: int = int(action.get("impact_target", action.target))
		var target: Dictionary = units[target_uid] if _living_target(target_uid) else {}
		match kind:
			"heal": _apply_heal(u, target, skill)
			"taunt": _apply_taunt(u, target, skill)
			"guard": _apply_guard(u, target, skill)
			"shield": _grant_shield(u, target, skill, TeamfightData.strength(skill.id, "shield"), "shield")
			"peel": _apply_peel(u, target_uid, skill)
			"interrupt": _apply_area_interrupt(u, skill)
			"area_stun": _apply_area_stun(u, skill)
			"flurry":
				if _living_target(target_uid): hits.append(_hit(u, target_uid, TeamfightData.strength(skill.id, "damage"), "skill", true, skill.id, 32.0))
			"finisher":
				if _living_target(target_uid):
					var bonus := TeamfightData.strength(skill.id, "bonus") if float(target.hp) / float(target.definition.max_hp) <= 0.4 else 0.0
					hits.append(_hit(u, target_uid, TeamfightData.strength(skill.id, "damage") + bonus, "skill", true, skill.id, 36.0))
		action.remaining -= 1
		action.next += ticks(skill.hit_interval)
	if int(action.remaining) <= 0 and tick >= int(action.end):
		_finish_action(u)

func _apply_heal(caster: Dictionary, target: Dictionary, skill: Resource) -> void:
	if _collect_effects and not target.is_empty():
		_support_effects.append({"kind":"heal", "source":caster.uid, "target":target.uid, "skill":skill})
		return
	if target.is_empty() or target.team != caster.team or target.uid == caster.uid: return
	var amount := minf(float(target.definition.max_hp) - float(target.hp), TeamfightData.strength(skill.id, "heal"))
	if amount <= 0.0: return
	target.hp += amount
	caster.healing_done += amount
	healing_total += amount
	_emit({"kind": "heal", "source": caster.uid, "target": target.uid, "pos": target.pos,
		"amount": amount, "skill": skill.id, "teamfight_role": caster.teamfight_role})

func _apply_taunt(caster: Dictionary, protected: Dictionary, skill: Resource) -> void:
	if _collect_effects and not protected.is_empty():
		_support_effects.append({"kind":"taunt", "source":caster.uid, "target":protected.uid, "skill":skill})
		return
	if protected.is_empty() or protected.team != caster.team or protected.uid == caster.uid: return
	_grant_shield(caster, protected, skill, TeamfightData.strength(skill.id, "shield"), "guard")
	for enemy: Dictionary in _enemies(caster):
		var commits_to_ally: bool = int(enemy.target) == int(protected.uid) or (not enemy.action.is_empty() and int(enemy.action.get("target", -1)) == int(protected.uid))
		if not commits_to_ally or Vector2(caster.pos).distance_to(enemy.pos) > 185.0: continue
		enemy.taunt_target = caster.uid
		enemy.taunt_end = tick + ticks(TeamfightData.strength(skill.id, "duration"))
		_emit({"kind": "taunt", "source": caster.uid, "target": enemy.uid, "pos": enemy.pos,
			"amount": TeamfightData.strength(skill.id, "duration"), "skill": skill.id, "teamfight_role": caster.teamfight_role})

func _apply_guard(caster: Dictionary, target: Dictionary, skill: Resource) -> void:
	_grant_shield(caster, caster, skill, TeamfightData.strength(skill.id, "self_shield"), "guard")
	if not target.is_empty() and target.uid != caster.uid:
		_grant_shield(caster, target, skill, TeamfightData.strength(skill.id, "shield"), "guard")

func _grant_shield(caster: Dictionary, target: Dictionary, skill: Resource, amount: float, event_kind: String) -> void:
	if _collect_effects and not target.is_empty():
		_support_effects.append({"kind":"shield", "source":caster.uid, "target":target.uid, "skill":skill, "amount":amount, "event_kind":event_kind})
		return
	if target.is_empty() or not target.alive: return
	var granted := minf(amount, maxf(0.0, SHIELD_CAP - float(target.shield_hp)))
	if granted <= 0.0: return
	target.shield_hp += granted
	target.shield_sources[caster.uid] = float(target.shield_sources.get(caster.uid, 0.0)) + granted
	caster.shield_granted = float(caster.get("shield_granted", 0.0)) + granted
	shield_total += granted
	_emit({"kind": event_kind, "source": caster.uid, "target": target.uid, "pos": target.pos,
		"amount": granted, "skill": skill.id, "teamfight_role": caster.teamfight_role})

func _apply_peel(caster: Dictionary, selected: int, skill: Resource) -> void:
	if _living_target(selected): _interrupt_target(caster, units[selected], skill, TeamfightData.strength(skill.id, "stun"))

func _apply_area_interrupt(caster: Dictionary, skill: Resource) -> void:
	for enemy: Dictionary in _enemies(caster):
		if edge_distance(caster, enemy) <= skill.range:
			_interrupt_target(caster, enemy, skill, TeamfightData.strength(skill.id, "stun"))

func _apply_area_stun(caster: Dictionary, skill: Resource) -> void:
	for enemy: Dictionary in _enemies(caster):
		if edge_distance(caster, enemy) <= skill.range:
			_interrupt_target(caster, enemy, skill, TeamfightData.strength(skill.id, "stun"))

func _interrupt_target(caster: Dictionary, target: Dictionary, skill: Resource, duration: float) -> void:
	if _collect_effects:
		_support_effects.append({"kind":"interrupt", "source":caster.uid, "target":target.uid, "skill":skill, "duration":duration})
		return
	var interrupted: bool = not target.action.is_empty() and (int(target.action.get("remaining", 1)) > 0 or bool(target.action.get("flying", false)) or target.action.skill.behavior == "trail")
	if interrupted:
		caster.interrupts += 1
		interrupt_total += 1
		target.action = {}
		target.basic_clock = 0
		_emit({"kind": "interrupt", "source": caster.uid, "target": target.uid, "pos": target.pos,
			"amount": 1.0, "skill": skill.id, "teamfight_role": caster.teamfight_role})
	_apply_stun(target, duration)
	Motion.correct_landings(units, [int(target.uid)], ARENA_SIZE)

func _try_evasion(u: Dictionary) -> bool:
	var skill: Resource = null
	for candidate: Resource in u.definition.skills:
		if candidate.id == "tf_eagle_evade": skill = candidate
	if skill == null or tick < int(u.cooldowns.get(skill.id, 0)) or not u.action.is_empty(): return false
	var threat: int = _visible_threat(u)
	if threat < 0:
		u.evasion_pending = -1
		u.evasion_threat = -1
		return false
	var threat_start: int = int(units[threat].action.get("start", -1))
	if int(u.evasion_threat) != threat or int(u.get("evasion_threat_start", -2)) != threat_start:
		u.evasion_threat = threat
		u.evasion_threat_start = threat_start
		u.evasion_pending = tick + ticks(0.45)
		_emit({"kind": "decision", "source": u.uid, "target": threat, "plan_target": u.target,
			"pos": u.pos, "reason": "visible_threat_notice", "state": "watch", "teamfight_role": u.teamfight_role})
		return false
	if tick < int(u.evasion_pending): return false
	var source_pos: Vector2 = units[threat].pos
	var lateral := (Vector2(u.pos) - source_pos).normalized().orthogonal()
	if lateral.length_squared() < 0.001: lateral = Vector2.UP
	var destination: Vector2 = _side_landing(u, lateral, 82.0)
	if destination.distance_to(u.pos) < 24.0:
		u.evasion_pending = tick + ticks(0.2)
		return false
	u.teamfight_cast_target = threat
	_start_skill(u, skill)
	u.action.teamfight_kind = "evade"
	u.action.evade_destination = destination
	u.action.threat = threat
	u.action.origin = u.pos
	u.action.start = tick
	u.action.end = tick + ticks(0.28)
	u.action.remaining = 0
	u.evasion_pending = -1
	u.evasion_threat = -1
	return true

func _visible_threat(u: Dictionary) -> int:
	for enemy: Dictionary in _enemies(u):
		if enemy.action.is_empty(): continue
		if int(enemy.action.get("remaining", 1)) <= 0 and not bool(enemy.action.get("flying", false)): continue
		if int(enemy.action.get("target", -1)) == int(u.uid): return enemy.uid
		var skill: Resource = enemy.action.get("skill")
		if skill != null and str(skill.behavior) == "cone":
			var cone := {"origin": enemy.action.get("origin", enemy.pos), "direction": enemy.action.get("direction", enemy.facing),
				"radius": enemy.definition.radius + skill.range, "angle": skill.cone_angle}
			if _inside_cone(u.pos, cone): return enemy.uid
	for cloud: Dictionary in clouds:
		if int(cloud.team) == int(u.team): continue
		if Vector2(u.pos).distance_to(cloud.pos) <= float(cloud.radius): return int(cloud.source)
	return -1

func _apply_damage_batch(hits: Array) -> void:
	for hit: Dictionary in hits:
		if not _living_target(int(hit.target)): continue
		var defender: Dictionary = units[hit.target]
		var raw := maxf(0.0, float(hit.damage))
		var absorbed := minf(float(defender.shield_hp), raw)
		if absorbed <= 0.0: continue
		defender.shield_hp = maxf(0.0, float(defender.shield_hp) - absorbed)
		hit.damage = raw - absorbed
		var to_absorb := absorbed
		var shield_sources: Dictionary = defender.shield_sources
		var source_ids: Array = shield_sources.keys()
		source_ids.sort()
		for shield_owner_variant in source_ids:
			var protector_uid := int(shield_owner_variant)
			var from_owner := minf(to_absorb, float(shield_sources[shield_owner_variant]))
			if from_owner <= 0.0: continue
			shield_sources[shield_owner_variant] = float(shield_sources[shield_owner_variant]) - from_owner
			to_absorb -= from_owner
			if protector_uid >= 0 and protector_uid < units.size():
				units[protector_uid].shield_absorbed = float(units[protector_uid].get("shield_absorbed", 0.0)) + from_owner
			_emit({"kind": "shield_absorb", "source": protector_uid, "target": defender.uid, "pos": defender.pos,
				"amount": from_owner, "skill": "", "teamfight_role": units[protector_uid].teamfight_role if protector_uid >= 0 and protector_uid < units.size() else ""})
		defender.shield_sources = shield_sources
		for owner in defender.shield_sources.keys():
			if float(defender.shield_sources[owner]) <= 0.001:
				defender.shield_sources.erase(owner)
	super._apply_damage_batch(hits)

func summary() -> Dictionary:
	var snapshot: Dictionary = super.summary()
	var rows: Array = snapshot.get("units", [])
	for i in rows.size():
		var unit: Dictionary = units[i]
		rows[i]["teamfight_role"] = unit.teamfight_role
		rows[i]["healing_done"] = unit.healing_done
		rows[i]["shield_absorbed"] = unit.shield_absorbed
		rows[i]["shield_granted"] = float(unit.get("shield_granted", 0.0))
		rows[i]["interrupts"] = unit.interrupts
		rows[i]["retreats"] = unit.retreats
		rows[i]["target_reasons"] = unit.target_reasons.duplicate()
		rows[i]["shield_hp"] = unit.shield_hp
		rows[i]["teamfight_plan"] = unit.teamfight_plan.duplicate(true)
	snapshot["rules_version"] = "teamfight-lab-v0.1"
	snapshot["units"] = rows
	snapshot["teamfight"] = {"healing_done": healing_total, "shield_granted": shield_total,
		"interrupts": interrupt_total, "retreats": retreat_total}
	return snapshot
