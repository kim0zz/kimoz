class_name CombatSimulation
extends RefCounted
## Authoritative fixed-step combat. No renderer, wall-clock timers or editor dependencies.

const Catalog = preload("res://scripts/data/catalog.gd")
const Motion = preload("res://scripts/combat/combat_movement.gd")
const DT: float = 1.0 / 60.0
const ARENA_SIZE := Vector2(1120, 500)
const RULES_VERSION := "combat-v0.9-rabbit-shield"
const STARTUP_SKILL_DELAY: float = 2.0
const TARGET_TIE_EPSILON: float = 0.05 # Subpixel differences must not choose a different enemy.
const RANGE_EPSILON: float = 0.05

var units: Array = []
var projectiles: Array = []
var clouds: Array = []
var cloud_damage_ready: Dictionary = {}
var events: Array = []
var trace: Array = []
var tick: int = 0
var time: float = 0.0
var result: String = "running"
var first_hit_time: float = -1.0
var seed_value: int = 1
var definitions: Dictionary = {}
var trace_enabled: bool = false
var skills_disabled: bool = false
var startup_ready_tick: int = 120
var validation_errors: Array[String] = []
var ending_1v1_time: float = 0.0
var ending_1v1: bool = false
var _pending_status: Array = []
var _next_projectile: int = 0

func setup(a: Array, b: Array, seed: int = 1, options: Dictionary = {}) -> bool:
	units.clear()
	projectiles.clear()
	clouds.clear()
	cloud_damage_ready.clear()
	events.clear()
	trace.clear()
	_pending_status.clear()
	validation_errors.clear()
	tick = 0
	time = 0.0
	result = "running"
	first_hit_time = -1.0
	ending_1v1 = false
	ending_1v1_time = 0.0
	_next_projectile = 0
	seed_value = seed
	trace_enabled = bool(options.get("trace", false))
	skills_disabled = bool(options.get("disable_skills", false))
	var startup_override: bool = options.has("startup_skill_delay")
	startup_ready_tick = maxi(0, ceili(float(options.get("startup_skill_delay", STARTUP_SKILL_DELAY)) / DT))
	definitions = Catalog.load_units().duplicate()
	definitions.merge(options.get("definitions", {}), true)
	if a.is_empty() or b.is_empty() or a.size() > 6 or b.size() > 6:
		validation_errors.append("Each team must contain 1–6 units.")
	for id in a + b:
		if not definitions.has(id):
			validation_errors.append("Unknown unit: " + str(id))
	if not validation_errors.is_empty():
		result = "invalid"
		return false
	for team in range(2):
		var roster: Array = a if team == 0 else b
		for slot in range(roster.size()):
			var definition: Resource = definitions[roster[slot]]
			var x: float = 300.0 if definition.role in ["front", "melee", "mobile"] else 180.0
			if team == 1:
				x = ARENA_SIZE.x - x
			var pos := Vector2(x, ARENA_SIZE.y * (slot + 1.0) / (roster.size() + 1.0))
			var uid: int = units.size()
			if options.has("positions") and uid < options.positions.size():
				pos = options.positions[uid]
			var cooldowns: Dictionary = {}
			for skill in definition.skills:
				var initial_delay: float = float(options.startup_skill_delay) if startup_override else float(skill.initial_cooldown)
				cooldowns[skill.id] = 0 if skill.behavior == "thorns" else maxi(0, ceili(initial_delay / DT))
			units.append({"uid": uid, "team": team, "slot": slot, "id": definition.id,
				"definition": definition, "pos": Motion.clamp_position(pos, definition.radius, ARENA_SIZE),
				"shield_hp": 0.0, "rabbit_shield_end": 0, "rabbit_shield_sources": {}, "shield_granted": 0.0, "shield_absorbed": 0.0,
				"velocity": Vector2.ZERO, "hp": definition.max_hp, "alive": true,
				"facing": Vector2.RIGHT if team == 0 else Vector2.LEFT,
				"stun_end": 0, "stun_remaining": 0.0, "stun_uptime": 0.0, "ignored_targets": {},
				"stagger_end": 0, "stagger_remaining": 0.0, "stagger_uptime": 0.0, "stagger_ready": 0, "slow_multiplier": 1.0, "slow_uptime": 0.0,
				"target": -1, "state": "idle", "action": {}, "cooldowns": cooldowns,
				"basic_clock": 0, "dive_used": false, "retreating": false, "close_target": -1,
				"flash": 0.0, "status_remaining": 0.0, "status_end": 0,
				"status_multiplier": 1.0, "status_source": -1, "status_uptime": 0.0,
				"skills_used": {}, "skill_opportunities": {}, "opportunity_ready": {}, "first_skill_start_time": -1.0, "damage_dealt": 0.0,
				"damage_taken": 0.0, "damage_by_kind": {}, "damage_taken_by_kind": {}, "overkill": 0.0,
				"damage_by_skill": {},
				"cancelled_damage": 0.0, "first_hit_time": -1.0, "death_time": -1.0,
				"target_changes": 0, "target_change_reasons": {}, "ranged_in_band": 0.0,
				"ranged_observed": 0.0, "ranged_in_melee": 0.0, "recent_attackers": {}, "focus_damage": 0.0})
	_emit({"kind": "match_start", "seed": seed_value})
	return true

static func ticks(seconds: float) -> int:
	return maxi(1, int(ceil(seconds / DT - 0.000001)))

func _emit(event: Dictionary) -> void:
	event["tick"] = tick
	event["time"] = time
	events.append(event)
	if trace_enabled:
		trace.append(event.duplicate(true))

func _living_target(uid: int) -> bool:
	return uid >= 0 and uid < units.size() and bool(units[uid].alive)

func edge_distance(a: Dictionary, b: Dictionary) -> float:
	return Vector2(a.pos).distance_to(b.pos) - a.definition.radius - b.definition.radius

func _enemies(u: Dictionary) -> Array:
	var found: Array = []
	for v: Dictionary in units:
		if v.alive and v.team != u.team:
			found.append(v)
	return found

func _target_candidates(u: Dictionary) -> Array:
	var all: Array = _enemies(u)
	var preferred: Array = all.filter(func(v: Dictionary) -> bool: return tick >= int(u.ignored_targets.get(v.uid, 0)))
	return all if preferred.is_empty() else preferred

func _nearest(u: Dictionary, melee_only: bool = false) -> int:
	var best: int = -1
	var distance: float = INF
	for v: Dictionary in _target_candidates(u):
		if melee_only and v.definition.role == "ranged":
			continue
		var d: float = edge_distance(u, v)
		if d < distance - TARGET_TIE_EPSILON or (absf(d - distance) < TARGET_TIE_EPSILON and _tie(v, u) < _tie(units[best], u)):
			best = v.uid
			distance = d
	return best

func _tie(v: Dictionary, u: Dictionary) -> int:
	# Stable species/slot tie-break, invariant under team swap / array ID permutation.
	return int(hash(str(v.id) + ":" + str(v.slot) + ":" + str(u.slot) + ":" + str(seed_value)) & 0x7fffffff)

func _farthest(u: Dictionary) -> int:
	var best: int = -1
	var distance: float = -INF
	for enemy: Dictionary in _target_candidates(u):
		var gap: float = edge_distance(u, enemy)
		if best < 0 or gap > distance + TARGET_TIE_EPSILON or (absf(gap - distance) < TARGET_TIE_EPSILON and _tie(enemy, u) < _tie(units[best], u)):
			best = enemy.uid
			distance = gap
	return best

func _choose_target(u: Dictionary) -> int:
	if not u.action.is_empty() and u.action.skill.behavior in ["dive", "dash"] and _living_target(u.action.target):
		return u.action.target
	var candidates: Array = _target_candidates(u)
	if _living_target(int(u.close_target)) and units[u.close_target] in candidates:
		return int(u.close_target)
	var enemies: Array = candidates
	if enemies.is_empty():
		return -1
	var best: int = -1
	var score: float = -INF
	for v: Dictionary in enemies:
		var distance: float = edge_distance(u, v)
		var candidate: float = -distance
		if u.definition.role == "ranged":
			candidate += 300.0 if distance <= u.definition.attack_range else 0.0
		elif u.definition.role == "utility":
			# Prefer a nearby cluster without abandoning a useful live target.
			for other: Dictionary in enemies:
				if Vector2(v.pos).distance_to(other.pos) < 120.0:
					candidate += 18.0
		if candidate > score + TARGET_TIE_EPSILON or (absf(candidate - score) < TARGET_TIE_EPSILON and _tie(v, u) < _tie(units[best], u)):
			best = v.uid
			score = candidate
	var current: int = u.target
	if _living_target(current) and units[current] in candidates:
		# Distance hysteresis keeps focus until a materially better reachable target exists.
		if edge_distance(u, units[current]) <= edge_distance(u, units[best]) + 70.0:
			return current
	return best

func _set_target(u: Dictionary, target: int, reason: String) -> void:
	if u.target == target:
		return
	if int(u.target) >= 0:
		u.target_changes += 1
	u.target = target
	u.target_change_reasons[reason] = int(u.target_change_reasons.get(reason, 0)) + 1
	_emit({"kind": "target", "source": u.uid, "target": target, "reason": reason})

func _update_ranged_contact(u: Dictionary) -> void:
	if u.definition.role != "ranged": return
	var threshold: float = u.definition.disengage_distance if int(u.close_target) >= 0 else u.definition.engage_distance
	var closest: int = -1
	var distance: float = INF
	for enemy: Dictionary in _target_candidates(u):
		if enemy.definition.role == "ranged": continue
		# Flight is not ground contact; inspect action state, not per-step movement flags.
		if not enemy.action.is_empty() and bool(enemy.action.get("flying", false)):
			continue
		var gap: float = edge_distance(u, enemy)
		if gap <= threshold + RANGE_EPSILON and (gap < distance - TARGET_TIE_EPSILON or (absf(gap - distance) < TARGET_TIE_EPSILON and _tie(enemy, u) < _tie(units[closest], u))):
			closest = enemy.uid
			distance = gap
	u.close_target = closest
	if closest >= 0: u.retreating = false

func step() -> void:
	if result != "running":
		return
	tick += 1
	time = tick * DT
	events.clear()
	_pending_status.clear()
	var hits: Array = []
	var desired: Array[Vector2] = []
	_update_cloud_slow()
	# Read a shared snapshot before any action advances or landing changes position.
	for u: Dictionary in units:
		if u.alive: _update_ranged_contact(u)
	for u: Dictionary in units:
		desired.append(u.pos)
		u["motion_dive"] = false
		u.flash = maxf(0.0, u.flash - DT)
		if not u.alive:
			continue
		if int(u.rabbit_shield_end) > 0 and tick >= int(u.rabbit_shield_end):
			u.shield_hp = 0.0
			u.rabbit_shield_end = 0
			u.rabbit_shield_sources.clear()
		if u.slow_multiplier < 1.0: u.slow_uptime += DT
		u.stagger_remaining = maxf(0.0, (int(u.stagger_end) - tick) * DT)
		u.stun_remaining = maxf(0.0, (int(u.stun_end) - tick) * DT)
		if tick < int(u.stun_end):
			u.stun_uptime += DT
			u.state = "stunned"
			continue
		if tick < int(u.stagger_end):
			u.stagger_uptime += DT
			if not u.action.is_empty():
				for timer: String in ["start", "next", "end", "travel_end", "next_leg"]:
					if u.action.has(timer): u.action[timer] += 1
				u.motion_dive = bool(u.action.get("flying", false))
			u.state = "staggered"
			continue
		if int(u.status_end) >= tick:
			u.status_uptime += DT
		if int(u.status_end) > tick:
			u.status_remaining = (int(u.status_end) - tick) * DT
		else:
			if u.status_remaining > 0.0:
				_emit({"kind": "status_expire", "target": u.uid})
			u.status_remaining = 0.0
			u.status_multiplier = 1.0
		_set_target(u, _choose_target(u), "dead_or_priority")
		if _living_target(u.target) and u.action.is_empty():
			var look: Vector2 = Vector2(units[u.target].pos) - Vector2(u.pos)
			if look.length_squared() > 0.001: u.facing = look.normalized()
		_observe_opportunities(u)
		if u.definition.role == "ranged" and _living_target(u.target):
			u.ranged_observed += DT
			var observed_distance: float = edge_distance(u, units[u.target])
			if observed_distance >= u.definition.preferred_min and observed_distance <= u.definition.preferred_max:
				u.ranged_in_band += DT
			var melee_threat: int = _nearest(u, true)
			if melee_threat >= 0 and edge_distance(u, units[melee_threat]) <= units[melee_threat].definition.attack_range:
				u.ranged_in_melee += DT
		if not u.action.is_empty():
			_process_action(u, hits, desired)
			continue
		if not _living_target(u.target):
			continue
		if _try_skill(u):
			_process_action(u, hits, desired)
			continue
		var target: Dictionary = units[u.target]
		var distance: float = edge_distance(u, target)
		var delta: Vector2 = Vector2(target.pos) - Vector2(u.pos)
		var move := Vector2.ZERO
		var trail_skill: Resource = _trail_skill(u) if not bool(u.definition.attack_enabled) else null
		var movement_override: Variant = _override_movement(u, target, distance)
		if movement_override != null:
			move = movement_override
		elif trail_skill != null:
			var orbit_side: float = 1.0 if (u.team + u.slot) % 2 == 0 else -1.0
			move = _trail_heading(u, target, trail_skill, orbit_side)
		elif distance > u.definition.attack_range + RANGE_EPSILON:
			move = delta.normalized()
		if move != Vector2.ZERO:
			move = Motion.steer(u, move, units, ARENA_SIZE)
			desired[u.uid] = Motion.translated(u.pos, move * float(u.definition.move_speed) * float(u.slow_multiplier) * DT, ARENA_SIZE)
			u.state = "move"
		else:
			u.state = "idle"
		# Ordinary attacks begin in range; only explicit skill/AI movement overrides reposition.
		var clamped: Vector2 = Motion.clamp_position(desired[u.uid], u.definition.radius, ARENA_SIZE)
		var actually_moving: bool = Vector2(u.pos).distance_to(clamped) > 0.01
		if bool(u.definition.attack_enabled) and distance <= u.definition.attack_range + RANGE_EPSILON and not actually_moving:
			u.basic_clock += 1
			if int(u.basic_clock) >= ticks(u.definition.attack_interval):
				u.basic_clock = 0
				u.state = "attack"
				if u.definition.role == "ranged":
					_launch(u, target.uid, u.definition.attack_damage, "basic", 420.0)
				else:
					hits.append(_hit(u, target.uid, u.definition.attack_damage, "basic", true))
		else:
			u.basic_clock = 0
	var released_phasers: Array = _sync_trail_phasing(false)
	Motion.apply(units, desired, ARENA_SIZE, DT)
	_separate_phasers(released_phasers)
	# Landing must use final enemy positions, including when the original target died in flight.
	var landings: Dictionary = {}
	for u: Dictionary in units:
		if u.has("landing_target"):
			var landing_target: int = u.landing_target
			if not _living_target(landing_target): landing_target = _nearest(u)
			landings[u.uid] = u.pos
			if landing_target >= 0 and not _legal_landing(u):
				landings[u.uid] = _landing(u, units[landing_target])
			u.motion_dive = false
			u.erase("landing_target")
	# Commit together: a landing cannot observe another landing from later in this same batch.
	for uid in landings:
		units[uid].pos = landings[uid]
	if not landings.is_empty():
		Motion.correct_landings(units, landings.keys(), ARENA_SIZE)
	_emit_movement_clouds()
	# Contact with a blocking frontliner makes it the next useful melee target.
	for u: Dictionary in units:
		if u.alive and u.action.is_empty() and u.definition.role != "ranged" and _living_target(u.target):
			var nearest: int = _nearest(u)
			if nearest >= 0 and edge_distance(u, units[nearest]) < 1.0 and edge_distance(u, units[u.target]) > u.definition.attack_range:
				_set_target(u, nearest, "blocked_by_enemy")
	_process_projectiles(hits)
	_process_clouds(hits)
	resolve_hits(hits)
	_sync_trail_phasing()
	for effect: Dictionary in _pending_status:
		if _living_target(effect.target) and _living_target(effect.source):
			apply_status(effect.target, effect.source, effect.definition)
	for u: Dictionary in units:
		if u.alive and not _living_target(u.target):
			_set_target(u, _choose_target(u), "target_died")
	_check_end()
	var counts: Array[int] = alive_counts()
	if units.size() > 2 and counts == [1, 1]:
		ending_1v1 = true
		ending_1v1_time += DT

## Specialized laboratory AI may override movement; null preserves normal rules.
func _override_movement(_unit: Dictionary, _target: Dictionary, _distance: float) -> Variant:
	return null

func _skill(u: Dictionary, behavior: String) -> Resource:
	if skills_disabled:
		return null
	for s: Resource in u.definition.skills:
		if s.behavior == behavior:
			return s
	return null

func _trail_skill(u: Dictionary) -> Resource:
	for s: Resource in u.definition.skills:
		if s.behavior == "trail": return s
	return null

func _trail_heading(u: Dictionary, target: Dictionary, s: Resource, orbit_side: float) -> Vector2:
	var toward: Vector2 = (Vector2(target.pos) - Vector2(u.pos)).normalized()
	var gap: float = edge_distance(u, target)
	var band: float = clampf(s.distance, 0.0, s.range)
	var radial: Vector2 = toward * clampf((gap - band) / maxf(30.0, band), -1.0, 1.0)
	var tangent: Vector2 = toward.rotated(PI * 0.5 * orbit_side)
	var heading: Vector2 = (tangent * 0.78 + radial * 0.72).normalized()
	if gap > s.range * 0.75: heading = toward
	return Motion.steer(u, heading, units, ARENA_SIZE)

func _try_skill(u: Dictionary) -> bool:
	if skills_disabled:
		return false
	for s: Resource in u.definition.skills:
		if s.behavior in ["thorns", "dash"] or tick < int(u.cooldowns.get(s.id, 0)):
			continue
		if s.behavior == "shield_jump":
			_start_skill(u, s)
			return true
		if s.behavior == "dive" and s.target_rule != "current":
			_set_target(u, _farthest(u), "dive_farthest")
		var distance: float = edge_distance(u, units[u.target])
		if s.behavior == "cone": distance += units[u.target].definition.radius
		if s.behavior != "dive" and distance > s.range + RANGE_EPSILON:
			continue
		_start_skill(u, s)
		return true
	return false

func _start_skill(u: Dictionary, s: Resource) -> void:
	if float(u.first_skill_start_time) < 0.0: u.first_skill_start_time = time
	u.skills_used[s.id] = int(u.skills_used.get(s.id, 0)) + 1
	u.cooldowns[s.id] = tick + ticks(s.cooldown)
	u.basic_clock = 0
	var duration_ticks: int = ticks(s.windup) + (int(s.hits) - 1) * ticks(s.hit_interval) + ticks(s.recovery)
	u.action = {"skill": s, "start": tick, "next": tick + ticks(s.windup),
		"end": tick + duration_ticks, "remaining": s.hits, "target": u.target,
		"origin": u.pos, "destination": u.pos, "direction": (Vector2(units[u.target].pos) - Vector2(u.pos)).normalized()}
	u.state = "cast"
	if s.behavior == "shield_jump":
		var ally: Dictionary = _shield_ally(u)
		u.action.target = ally.uid
		u.action.destination = u.pos if ally.uid == u.uid else _landing(u, ally, Vector2.LEFT if u.team == 0 else Vector2.RIGHT)
		u.action["travel_end"] = tick + (1 if ally.uid == u.uid else ticks(s.duration))
		u.action.end = u.action.travel_end
		u.action["flying"] = ally.uid != u.uid
		u.state = "dash" if ally.uid != u.uid else "cast"
		if ally.uid != u.uid: _break_aggro(u, s.aggro_duration)
	elif s.behavior == "dive":
		u.dive_used = true
		u.action.remaining = s.airborne_hits
		u.action["leg"] = 0
		_begin_dive_leg(u)
	elif s.behavior == "dash":
		u.state = "dash"
		u.action["leg"] = 0
		u.action["flying"] = true
		u.action["puff_next"] = tick + ticks(s.puff_interval)
		u.action["travel_end"] = tick + ticks(s.duration)
		u.action.end = u.action.travel_end
		if s.dash_mode == "farthest":
			_set_target(u, _farthest(u), "hybrid_dash_farthest")
			u.action.target = u.target
		if s.dash_mode == "side":
			var lateral: Vector2 = (Vector2(units[u.target].pos) - Vector2(u.pos)).normalized().orthogonal()
			lateral *= 1.0 if u.team == 0 else -1.0
			u.action.destination = _side_landing(u, lateral, (s.distance if s.distance > 0.0 else 120.0))
		else:
			u.action.destination = _landing(u, units[u.target], -Vector2(units[u.target].facing))
		_break_aggro(u, s.aggro_duration)
	elif s.behavior == "cloud":
		u.action.destination = units[u.target].pos
	elif s.behavior == "trail":
		u["phase_active"] = true
		u.action["trail_next"] = tick + ticks(s.puff_interval)
		u.action["orbit_side"] = 1.0 if (u.team + u.slot) % 2 == 0 else -1.0
		u.action.end = tick + ticks(s.duration)
		u.action.next = u.action.end
		u.state = "trail"
	_emit({"kind": "skill_start", "source": u.uid, "target": u.action.target, "skill": s.id, "behavior": s.behavior, "pos": u.pos})

func _shield_ally(u: Dictionary) -> Dictionary:
	var best: Dictionary = u
	var best_score := -INF
	for ally: Dictionary in units:
		if not ally.alive or ally.team != u.team or ally.uid == u.uid: continue
		var pressure := 0.0
		for enemy: Dictionary in units:
			if enemy.alive and enemy.team != u.team and enemy.target == ally.uid: pressure += 1.0
		var score: float = (1.0 - float(ally.hp) / float(ally.definition.max_hp)) * 3.0 + minf(pressure, 3.0) - float(ally.shield_hp) / 30.0
		if score > best_score:
			best = ally
			best_score = score
	return best

func _rabbit_shield(caster: Dictionary, ally: Dictionary, skill: Resource) -> void:
	var added: float = maxf(0.0, skill.shield_amount - float(ally.shield_hp))
	ally.shield_hp = maxf(float(ally.shield_hp), skill.shield_amount)
	ally.rabbit_shield_end = tick + ticks(skill.shield_duration)
	ally.rabbit_shield_sources[caster.uid] = float(ally.rabbit_shield_sources.get(caster.uid, 0.0)) + added
	caster.shield_granted += added
	_emit({"kind": "shield", "source": caster.uid, "target": ally.uid, "pos": ally.pos, "amount": added, "skill": skill.id})

func _side_landing(u: Dictionary, direction: Vector2, distance: float) -> Vector2:
	for sign_value in [1.0, -1.0]:
		for fraction in [1.0, 0.75, 0.5]:
			var candidate: Vector2 = Motion.clamp_position(Motion.translated(u.pos, direction * distance * sign_value * fraction, ARENA_SIZE), u.definition.radius, ARENA_SIZE)
			var legal := true
			for other: Dictionary in units:
				if other.uid != u.uid and other.alive and candidate.distance_to(other.pos) < u.definition.radius + other.definition.radius + 0.01: legal = false
			if legal: return candidate
	return u.pos

func _begin_dive_leg(u: Dictionary) -> void:
	var a: Dictionary = u.action
	var s: Resource = a.skill
	a.origin = u.pos
	a.start = tick
	var side := Vector2.ZERO
	if s.airborne_hits > 1:
		var sign_value: float = 1.0 if int(a.leg) % 2 == 0 else -1.0
		if not a.has("side_axis"):
			# Snapshot approach axis; the target's facing may already have been updated this tick.
			a["side_axis"] = Vector2(a.direction).orthogonal() * (1.0 if u.team == 0 else -1.0)
		side = Vector2(a.side_axis) * sign_value
	a.destination = _landing(u, units[a.target], side)
	a["landing_side"] = side
	var flight: float = s.duration if s.duration > 0.0 else Vector2(u.pos).distance_to(a.destination) / maxf(s.speed, 1.0)
	a["travel_end"] = tick + ticks(flight)
	a.end = a.travel_end + ticks(s.recovery)
	a.next = a.travel_end
	a["flying"] = true
	u.state = "dive"

func _observe_opportunities(u: Dictionary) -> void:
	if skills_disabled or not _living_target(u.target):
		return
	for s: Resource in u.definition.skills:
		if s.behavior in ["thorns", "dash"]:
			continue
		var ready: bool = tick >= int(u.cooldowns.get(s.id, 0))
		var distance: float = edge_distance(u, units[u.target])
		if s.behavior == "cone": distance += units[u.target].definition.radius
		ready = ready and (true if s.behavior in ["dive", "shield_jump"] else distance <= s.range + RANGE_EPSILON)
		if ready and not bool(u.opportunity_ready.get(s.id, false)):
			u.skill_opportunities[s.id] = int(u.skill_opportunities.get(s.id, 0)) + 1
			u.opportunity_ready[s.id] = true
		elif not ready:
			u.opportunity_ready[s.id] = false

func _legal_landing(u: Dictionary) -> bool:
	for other: Dictionary in units:
		if other.uid != u.uid and other.alive and edge_distance(u, other) < -0.001:
			return false
	return true

func _landing(u: Dictionary, target: Dictionary, preferred: Vector2 = Vector2.ZERO) -> Vector2:
	var radius: float = u.definition.radius + target.definition.radius + 2.0
	var toward: Vector2 = preferred.normalized() if preferred != Vector2.ZERO else (Vector2(u.pos) - Vector2(target.pos)).normalized()
	if toward == Vector2.ZERO:
		toward = Vector2.RIGHT if u.team == 0 else Vector2.LEFT
	for ring in range(1, 8):
		for offset in [0.0, 0.5, -0.5, 1.0, -1.0, 1.5, -1.5, PI]:
			var facing: float = 1.0 if u.team == 0 else -1.0
			var candidate: Vector2 = Motion.clamp_position(Motion.translated(target.pos, toward.rotated(offset * facing) * (radius + (ring - 1) * 18.0), ARENA_SIZE), u.definition.radius, ARENA_SIZE)
			var valid: bool = true
			for v: Dictionary in units:
				if v.uid == u.uid or not v.alive: continue
				if candidate.distance_to(v.pos) < u.definition.radius + v.definition.radius - 0.01:
					valid = false
					break
			if valid:
				return candidate
	return u.pos

func _process_action(u: Dictionary, hits: Array, desired: Array[Vector2]) -> void:
	var action: Dictionary = u.action
	var s: Resource = action.skill
	var target: int = action.target
	if bool(action.get("queued", false)):
		if not _living_target(target):
			u.action = {}
			return
		_set_target(u, target, "combo_followup")
		_start_skill(u, s)
		_process_action(u, hits, desired)
		return
	if s.behavior == "shield_jump":
		var flying: bool = bool(action.get("flying", false))
		u.motion_dive = flying
		u.state = "dash" if flying else "cast"
		var progress := clampf(float(tick - int(action.start)) / maxf(1.0, float(int(action.travel_end) - int(action.start))), 0.0, 1.0)
		desired[u.uid] = Motion.interpolated(action.origin, action.destination, progress, ARENA_SIZE)
		if tick >= int(action.travel_end):
			if _living_target(target):
				_rabbit_shield(u, units[target], s)
			elif _shield_ally(u).uid == u.uid:
				_rabbit_shield(u, u, s)
			if flying: u["landing_target"] = target
			_finish_action(u)
		return
	if s.behavior == "dive":
		if not _living_target(target) and not bool(action.flying):
			_finish_action(u)
			return
		if not bool(action.flying) and int(action.remaining) > 0 and tick >= int(action.get("next_leg", tick)):
			action.leg += 1
			_begin_dive_leg(u)
		var progress: float = clampf(float(tick - int(action.start)) / maxf(1.0, float(int(action.travel_end) - int(action.start))), 0.0, 1.0)
		if bool(action.flying):
			u.state = "dive"
			u.motion_dive = true
			desired[u.uid] = Motion.interpolated(action.origin, action.destination, progress, ARENA_SIZE)
		if tick >= int(action.travel_end) and bool(action.flying):
			action.remaining -= 1
			action.flying = false
			action["next_leg"] = tick + ticks(s.hit_interval)
			u["landing_target"] = target
			if _living_target(target):
				desired[u.uid] = _landing(u, units[target], action.get("landing_side", Vector2.ZERO))
				# Impact is checked at the legal landing point, not the takeoff location.
				if s.landing_cone:
					_queue_cone(u, s, desired[u.uid], (Vector2(units[target].pos) - desired[u.uid]).normalized(), hits, int(action.remaining) == 0)
				elif s.damage > 0.0:
					var hit: Dictionary = _hit(u, target, s.damage, "skill", true, s.id, s.range)
					hit["stun"] = s.stun_duration if not s.stun_last_hit_only or int(action.remaining) == 0 else 0.0
					hits.append(hit)
				if s.landing_cloud:
					_create_cloud(u.uid, desired[u.uid], s, s.cloud_damage * float(u.status_multiplier))
			else:
				action.remaining = 0
			u.state = "cast"
		if int(action.remaining) <= 0 and tick >= int(action.end):
			_finish_action(u)
		return
	if s.behavior == "dash":
		if bool(action.get("repeat_pending", false)):
			if not _living_target(target):
				_finish_action(u)
				return
			action.erase("repeat_pending")
			action.leg += 1
			action.origin = u.pos
			action.start = tick
			action.travel_end = tick + ticks(s.duration)
			action.end = action.travel_end
			var side: Vector2 = Vector2(action.direction).orthogonal() * (1.0 if int(action.leg) % 2 == 0 else -1.0) * (1.0 if u.team == 0 else -1.0)
			action.destination = _landing(u, units[target], side)
			action.flying = true
		if bool(action.get("flying", false)):
			u.motion_dive = true
			var progress: float = clampf(float(tick - int(action.start)) / maxf(1.0, float(int(action.travel_end) - int(action.start))), 0.0, 1.0)
			desired[u.uid] = Motion.interpolated(action.origin, action.destination, progress, ARENA_SIZE)
			if tick >= int(action.travel_end):
				u["landing_target"] = target
				action.flying = false
				if s.airborne_hits > 1 and int(action.leg) + 1 < s.airborne_hits and _living_target(target):
					action["repeat_pending"] = true
					return
				if s.followup_hits > 0 and _living_target(target):
					action.remaining = s.followup_hits
					action.next = tick + ticks(s.windup)
					action.end = action.next + (s.followup_hits - 1) * ticks(s.followup_interval) + ticks(s.recovery)
					u.state = "cast"
				else: _finish_action(u)
		else:
			if not _living_target(target):
				_finish_action(u)
				return
			if tick >= int(action.next) and int(action.remaining) > 0:
				var hit: Dictionary = _hit(u, target, s.followup_damage, "skill", true, s.id, maxf(s.range, u.definition.attack_range))
				hit["stun"] = s.followup_stun
				hits.append(hit)
				action.remaining -= 1
				action.next += ticks(s.followup_interval)
			if tick >= int(action.end): _finish_action(u)
		return
	if s.behavior == "trail":
		if not _living_target(target) or tick >= int(action.end):
			_finish_action(u)
			return
		var enemy: Dictionary = units[target]
		var heading: Vector2 = _trail_heading(u, enemy, s, float(action.orbit_side))
		desired[u.uid] = Motion.translated(u.pos, heading * u.definition.move_speed * u.slow_multiplier * DT, ARENA_SIZE)
		u.state = "trail"
		return
	if tick >= int(action.next) and int(action.remaining) > 0:
		action.remaining -= 1
		action.next += ticks(s.hit_interval)
		if s.behavior == "cone":
			_queue_cone(u, s, action.origin, action.direction, hits, int(action.remaining) == 0)
		elif s.behavior == "cloud":
			_create_cloud(u.uid, action.destination, s, s.damage * float(u.status_multiplier))
		elif s.behavior == "debuff":
			for enemy: Dictionary in _enemies(u):
				if edge_distance(u, enemy) <= s.range + RANGE_EPSILON:
					_pending_status.append({"source": u.uid, "target": enemy.uid, "definition": s.status})
			_emit({"kind": "cloud", "source": u.uid, "pos": u.pos, "radius": s.range})
		elif _living_target(target):
			if s.behavior == "projectile":
				_launch(u, target, s.damage, "skill", s.speed, s.id, s, int(action.remaining) == 0)
			else:
				var hit: Dictionary = _hit(u, target, s.damage, "skill", true, s.id, s.range)
				hit["stun"] = s.stun_duration
				hits.append(hit)
		else:
			_emit({"kind": "miss", "source": u.uid, "target": target, "skill": s.id})
	if tick >= int(action.end):
		_finish_action(u)

func _queue_cone(u: Dictionary, s: Resource, origin: Vector2, direction: Vector2, hits: Array, last_hit: bool) -> void:
	var radius: float = u.definition.radius + s.range
	for enemy: Dictionary in _enemies(u):
		var hit: Dictionary = _hit(u, enemy.uid, s.damage, "skill", true, s.id, INF)
		hit["cone"] = {"origin": origin, "direction": direction, "radius": radius, "angle": s.cone_angle}
		hit["stagger"] = 0.0 if s.stun_last_hit_only and last_hit and s.stun_duration > 0.0 else s.stagger_duration
		hit["stun"] = s.stun_duration if not s.stun_last_hit_only or last_hit else 0.0
		hit["banana"] = s.cone_projectile_damage
		hit["banana_definition"] = s if s.impact_cloud else null
		hits.append(hit)
	_emit({"kind": "cone_hit", "source": u.uid, "pos": origin, "direction": direction, "radius": radius, "angle": s.cone_angle})

func _finish_action(u: Dictionary) -> void:
	var finished: Dictionary = u.action
	_emit({"kind": "skill_end", "source": u.uid, "skill": finished.skill.id})
	u.action = {}
	if finished.skill.followup_skill != null and _living_target(finished.target):
		# Queue until the next step: movement and damage of this phase must resolve first.
		u.action = {"skill": finished.skill.followup_skill, "target": finished.target, "queued": true,
			"start": tick, "next": tick + 1, "end": tick + 1, "remaining": 0,
			"origin": u.pos, "destination": u.pos, "direction": u.facing}
	u.state = "idle"
	u.basic_clock = 0

func _hit(u: Dictionary, target: int, damage: float, kind: String, melee: bool, skill_id: String = "", max_range: float = -1.0) -> Dictionary:
	return {"source": u.uid, "target": target, "damage": damage * float(u.status_multiplier),
		"kind": kind, "melee": melee, "skill": skill_id, "projectile": false,
		"max_range": max_range if max_range >= 0.0 else u.definition.attack_range}

func _launch(u: Dictionary, target: int, damage: float, kind: String, speed: float, skill_id: String = "", skill: Resource = null, last_hit: bool = true) -> void:
	projectiles.append({"uid": _next_projectile, "source": u.uid, "target": target,
		"pos": u.pos, "damage": damage * float(u.status_multiplier), "kind": kind,
		"speed": maxf(speed, 1.0), "skill": skill_id, "definition": skill,
		"stun": skill.stun_duration if skill != null and (not skill.stun_last_hit_only or last_hit) else 0.0,
		"cloud_damage": skill.cloud_damage * float(u.status_multiplier) if skill != null else 0.0})
	_next_projectile += 1
	_emit({"kind": "projectile", "source": u.uid, "target": target, "pos": u.pos})

func _process_projectiles(hits: Array) -> void:
	var remaining: Array = []
	for p: Dictionary in projectiles:
		if not _living_target(p.target):
			continue
		var target: Dictionary = units[p.target]
		p.pos = Motion.toward(p.pos, target.pos, float(p.speed) * DT, ARENA_SIZE)
		if Vector2(p.pos).distance_to(target.pos) <= target.definition.radius:
			hits.append({"source": p.source, "target": p.target, "damage": p.damage,
				"kind": p.kind, "melee": false, "skill": p.skill, "projectile": true, "stun": p.get("stun", 0.0)})
			var definition: Resource = p.get("definition")
			if definition != null and definition.impact_cloud:
				_create_cloud(p.source, target.pos, definition, p.cloud_damage)
		else:
			remaining.append(p)
	projectiles = remaining

func _create_cloud(source: int, pos: Vector2, s: Resource, damage: float) -> void:
	var cloud_lifetime: float = float(s.duration)
	if (s.behavior in ["trail", "dash"] or s.landing_cloud) and s.cloud_duration > 0.0:
		cloud_lifetime = float(s.cloud_duration)
	var pulse_interval: float = s.cloud_tick_interval if s.cloud_tick_interval > 0.0 else s.hit_interval
	clouds.append({"source": source, "team": units[source].team, "pos": pos, "radius": s.area_radius,
		"end": tick + ticks(cloud_lifetime), "next": tick + ticks(pulse_interval), "interval": ticks(pulse_interval),
		"damage": damage, "skill": s.id, "slow": s.slow_multiplier, "stagger": s.cloud_stagger})
	_emit({"kind": "cloud", "source": source, "pos": pos, "radius": s.area_radius})

func _emit_movement_clouds() -> void:
	for u: Dictionary in units:
		if not u.alive or u.action.is_empty(): continue
		if tick < int(u.stun_end) or tick < int(u.stagger_end):
			_advance_paused_cloud_timer(u)
			continue
		var s: Resource = u.action.skill
		var timer_key: String = "trail_next" if s.behavior == "trail" else ("puff_next" if s.behavior == "dash" and bool(u.action.get("flying", false)) else "")
		if timer_key.is_empty() or float(s.cloud_damage) <= 0.0 or float(s.puff_interval) <= 0.0 or not u.action.has(timer_key) or tick < int(u.action[timer_key]): continue
		_create_cloud(u.uid, u.pos, s, s.cloud_damage * float(u.status_multiplier))
		u.action[timer_key] = tick + ticks(s.puff_interval)

func _advance_paused_cloud_timer(u: Dictionary) -> void:
	if u.action.is_empty(): return
	var s: Resource = u.action.skill
	var timer_key: String = "trail_next" if s.behavior == "trail" else ("puff_next" if s.behavior == "dash" and bool(u.action.get("flying", false)) else "")
	if not timer_key.is_empty() and u.action.has(timer_key): u.action[timer_key] += 1

func _update_cloud_slow() -> void:
	for u: Dictionary in units:
		u.slow_multiplier = 1.0
		if not u.alive: continue
		for cloud: Dictionary in clouds:
			if tick <= int(cloud.end) and u.team != cloud.team and Vector2(u.pos).distance_to(cloud.pos) <= float(cloud.radius):
				u.slow_multiplier = minf(float(u.slow_multiplier), float(cloud.get("slow", 1.0)))

func _process_clouds(hits: Array) -> void:
	for cloud: Dictionary in clouds:
		if tick > int(cloud.end) or tick < int(cloud.next): continue
		cloud.next += int(cloud.interval)
		for u: Dictionary in units:
			if u.alive and u.team != cloud.team and Vector2(u.pos).distance_to(cloud.pos) <= float(cloud.radius):
				var key: String = "%s:%s" % [cloud.source, u.uid]
				if tick < int(cloud_damage_ready.get(key, 0)): continue
				cloud_damage_ready[key] = tick + int(cloud.interval)
				hits.append({"source": cloud.source, "target": u.uid, "damage": cloud.damage, "kind": "dot", "skill": cloud.skill, "melee": false, "persistent": true, "stagger": cloud.get("stagger", 0.0)})
	clouds = clouds.filter(func(c: Dictionary) -> bool: return tick < int(c.end))

func _inside_cone(point: Vector2, cone: Dictionary) -> bool:
	var offset: Vector2 = point - Vector2(cone.origin)
	return offset.length() <= float(cone.radius) + RANGE_EPSILON and (offset.length_squared() < 0.001 or offset.normalized().dot(cone.direction) >= cos(deg_to_rad(float(cone.angle) * 0.5)) - 0.00001)

func _break_aggro(rabbit: Dictionary, duration: float) -> void:
	for enemy: Dictionary in _enemies(rabbit):
		if enemy.target != rabbit.uid and (enemy.action.is_empty() or enemy.action.target != rabbit.uid): continue
		enemy.ignored_targets[rabbit.uid] = tick + ticks(duration)
		enemy.close_target = -1
		# In-flight attacks already committed are not erased. Grounded windups retarget.
		if not enemy.action.is_empty() and enemy.action.skill.behavior not in ["dive", "dash"]:
			enemy.action = {}
			enemy.basic_clock = 0
		_set_target(enemy, _choose_target(enemy), "rabbit_aggro_break")
	_emit({"kind": "aggro_break", "source": rabbit.uid, "pos": rabbit.pos})

func _apply_stun(target: Dictionary, duration: float) -> void:
	target.stun_end = maxi(int(target.stun_end), tick + ticks(duration))
	target.stun_remaining = (int(target.stun_end) - tick) * DT
	target.action = {}
	target.basic_clock = 0
	target.motion_dive = false
	target.state = "stunned"
	_emit({"kind": "stun", "target": target.uid, "pos": target.pos})

func resolve_hits(hits: Array) -> void:
	if result != "running":
		return
	var eligible: Array = []
	var thorns: Array = []
	for hit: Dictionary in hits:
		if not _living_target(hit.target) or int(hit.source) < 0 or int(hit.source) >= units.size():
			continue
		if not _living_target(hit.source) and not bool(hit.get("projectile", false)) and not bool(hit.get("persistent", false)):
			continue
		if hit.has("cone") and not _inside_cone(units[hit.target].pos, hit.cone): continue
		if bool(hit.get("melee", false)) and hit.has("max_range") and edge_distance(units[hit.source], units[hit.target]) > float(hit.max_range) + 0.05:
			_emit({"kind": "miss", "source": hit.source, "target": hit.target, "reason": "out_of_range_at_impact"})
			continue
		eligible.append(hit)
		var defender: Dictionary = units[hit.target]
		var passive: Resource = _skill(defender, "thorns")
		if passive != null and bool(hit.get("melee", false)) and hit.kind != "thorns":
			thorns.append({"source": hit.target, "target": hit.source, "damage": passive.damage,
				"kind": "thorns", "melee": false, "skill": passive.id})
			defender.skills_used[passive.id] = int(defender.skills_used.get(passive.id, 0)) + 1
			defender.skill_opportunities[passive.id] = int(defender.skill_opportunities.get(passive.id, 0)) + 1
	_apply_damage_batch(thorns)
	var direct: Array = []
	for hit: Dictionary in eligible:
		if not units[hit.source].alive and not bool(hit.get("projectile", false)) and not bool(hit.get("persistent", false)):
			units[hit.source].cancelled_damage += float(hit.damage)
			_emit({"kind": "cancelled", "source": hit.source, "target": hit.target,
				"reason": "killed_by_thorns", "attempted": hit.damage, "applied": 0.0})
		elif units[hit.target].alive:
			direct.append(hit)
	_apply_damage_batch(direct)
	var stunned: Array = []
	for hit: Dictionary in direct:
		if _living_target(hit.target) and float(hit.get("stagger", 0)) > 0:
			var victim: Dictionary = units[hit.target]
			if tick >= int(victim.stagger_ready):
				victim.stagger_end = tick + ticks(hit.stagger)
				victim.stagger_remaining = float(hit.stagger)
				victim.stagger_ready = victim.stagger_end + (ticks(0.2) if hit.kind == "dot" else 0)
		if _living_target(hit.target) and _living_target(hit.source) and float(hit.get("banana", 0)) > 0:
			_launch(units[hit.source], hit.target, hit.banana, "skill", 500.0, str(hit.skill) + "_banana", hit.get("banana_definition"))
		if _living_target(hit.target) and float(hit.get("stun", 0)) > 0:
			_apply_stun(units[hit.target], float(hit.stun))
			if hit.target not in stunned: stunned.append(hit.target)
	# A stun can interrupt airborne movement; resolve body overlap at that position.
	if not stunned.is_empty(): Motion.correct_landings(units, stunned, ARENA_SIZE)
	# Conditional dash occurs only after surviving direct damage; thorns cannot proc it.
	var dash_triggers: Dictionary = {}
	for hit: Dictionary in direct:
		if hit.kind in ["thorns", "dot"] or float(hit.damage) <= 0.0 or not _living_target(hit.source): continue
		if not dash_triggers.has(hit.target) or float(hit.damage) > float(dash_triggers[hit.target].damage) or (float(hit.damage) == float(dash_triggers[hit.target].damage) and _tie(units[hit.source], units[hit.target]) < _tie(units[dash_triggers[hit.target].source], units[hit.target])):
			dash_triggers[hit.target] = hit
	for uid in dash_triggers:
		var defender: Dictionary = units[uid]
		if not defender.alive or tick < int(defender.stun_end) or tick < int(defender.stagger_end): continue
		var dash: Resource = _skill(defender, "dash")
		if dash == null or tick < int(defender.cooldowns.get(dash.id, 0)):
			continue
		var threat: int = int(dash_triggers[uid].source)
		if _living_target(threat):
			defender.skill_opportunities[dash.id] = int(defender.skill_opportunities.get(dash.id, 0)) + 1
			if defender.action.is_empty() or (dash.interrupt_on_hit and not bool(defender.action.get("flying", false))):
				_set_target(defender, threat, "rabbit_counter")
				_start_skill(defender, dash)
	_check_end()

func _apply_damage_batch(hits: Array) -> void:
	# Only normal Rabbit shields are handled here; T retains its own shield accounting.
	for hit: Dictionary in hits:
		var defender: Dictionary = units[hit.target]
		if int(defender.rabbit_shield_end) <= tick: continue
		var absorbed := minf(float(defender.shield_hp), maxf(0.0, float(hit.damage)))
		if absorbed <= 0.0: continue
		defender.shield_hp -= absorbed
		hit.damage -= absorbed
		var left := absorbed
		for owner in defender.rabbit_shield_sources.keys():
			var portion := minf(left, float(defender.rabbit_shield_sources[owner]))
			defender.rabbit_shield_sources[owner] -= portion
			left -= portion
			units[owner].shield_absorbed += portion
			if portion > 0.0:
				_emit({"kind": "shield_absorb", "source": owner, "target": defender.uid, "pos": defender.pos, "amount": portion, "skill": "rabbit_dash"})
	var totals: Dictionary = {}
	for hit: Dictionary in hits:
		totals[hit.target] = float(totals.get(hit.target, 0.0)) + maxf(0.0, hit.damage)
		if float(hit.damage) > 0.0:
			units[hit.target].recent_attackers[hit.source] = tick
	# Proportional overkill attribution, independent of iteration order.
	for hit: Dictionary in hits:
		var u: Dictionary = units[hit.target]
		var source: Dictionary = units[hit.source]
		var attempted: float = maxf(0.0, hit.damage)
		var total: float = totals[hit.target]
		var applied: float = attempted * minf(1.0, float(u.hp) / maxf(total, 0.00001))
		u.damage_taken += applied
		u.damage_taken_by_kind[hit.kind] = float(u.damage_taken_by_kind.get(hit.kind, 0.0)) + applied
		source.damage_dealt += applied
		source.overkill += attempted - applied
		source.damage_by_kind[hit.kind] = float(source.damage_by_kind.get(hit.kind, 0.0)) + applied
		var skill_id: String = str(hit.get("skill", ""))
		if not skill_id.is_empty(): source.damage_by_skill[skill_id] = float(source.damage_by_skill.get(skill_id, 0.0)) + applied
		if applied > 0.0:
			if first_hit_time < 0.0:
				first_hit_time = time
			if u.first_hit_time < 0.0:
				u.first_hit_time = time
			u.flash = 0.18
			var attackers: int = 0
			for last_tick in u.recent_attackers.values():
				if tick - int(last_tick) <= 60:
					attackers += 1
			if attackers >= 2:
				u.focus_damage += applied
		_emit({"kind": "damage", "source": hit.source, "target": hit.target,
			"damage_kind": hit.kind, "skill": hit.get("skill", ""), "pos": u.pos,
			"amount": applied, "attempted": attempted, "applied": applied, "overkill": attempted - applied})
	for uid in totals:
		var u: Dictionary = units[uid]
		u.hp = maxf(0.0, float(u.hp) - float(totals[uid]))
		if u.hp <= 0.0 and u.alive:
			u.alive = false
			u.action = {}
			u.state = "dead"
			u.death_time = time
			u.velocity = Vector2.ZERO
			_emit({"kind": "death", "target": uid, "pos": u.pos})

func apply_status(target: int, source: int, status: Resource) -> void:
	if status == null or not _living_target(target):
		return
	var u: Dictionary = units[target]
	var refresh: bool = int(u.status_end) > tick
	u.status_end = tick + ticks(status.duration)
	u.status_remaining = status.duration
	u.status_multiplier = status.multiplier
	u.status_source = source
	_emit({"kind": "status_refresh" if refresh else "status_apply", "source": source,
		"target": target, "status": status.id, "pos": u.pos})

func alive_counts() -> Array[int]:
	var counts: Array[int] = [0, 0]
	for u: Dictionary in units:
		if u.alive:
			counts[u.team] += 1
	return counts

func _check_end() -> void:
	if result != "running":
		return
	var counts: Array[int] = alive_counts()
	if counts[0] == 0 or counts[1] == 0:
		result = "draw" if counts == [0, 0] else ("A" if counts[0] > 0 else "B")
		_emit({"kind": "match_end", "result": result})

func summary() -> Dictionary:
	var rows: Array = []
	for u: Dictionary in units:
		rows.append({"uid": u.uid, "team": u.team, "id": u.id, "hp": u.hp,
			"level": u.definition.level,
			"max_hp": u.definition.max_hp, "survived": u.alive,
			"shield_granted": u.shield_granted, "shield_absorbed": u.shield_absorbed, "shield_hp": u.shield_hp,
			"damage_dealt": u.damage_dealt, "damage_taken": u.damage_taken,
			"damage_by_kind": u.damage_by_kind.duplicate(), "damage_by_skill": u.damage_by_skill.duplicate(), "overkill": u.overkill,
			"damage_taken_by_kind": u.damage_taken_by_kind.duplicate(),
			"cancelled_damage": u.cancelled_damage, "skill_uses": u.skills_used.duplicate(),
			"skill_opportunities": u.skill_opportunities.duplicate(), "death_time": u.death_time,
			"first_hit_time": u.first_hit_time, "first_skill_start_time":u.first_skill_start_time,
			"ttk": float(u.death_time) - float(u.first_hit_time) if not u.alive and u.first_hit_time >= 0.0 else -1.0,
			"target_changes": u.target_changes, "target_change_reasons": u.target_change_reasons.duplicate(),
			"status_uptime": u.status_uptime, "ranged_in_band": u.ranged_in_band,
			"stun_uptime": u.stun_uptime,
			"stagger_uptime": u.stagger_uptime, "slow_uptime": u.slow_uptime,
			"ranged_observed": u.ranged_observed, "ranged_in_melee": u.ranged_in_melee, "focus_damage": u.focus_damage})
	return {"result": result, "duration": time, "tick": tick, "first_hit_time": first_hit_time,
		"seed": seed_value, "rules_version": RULES_VERSION, "units": rows,
		"ending_1v1": ending_1v1, "ending_1v1_time": ending_1v1_time}

func _sync_trail_phasing(separate: bool = true) -> Array:
	var released: Array = []
	for u: Dictionary in units:
		var active: bool = u.alive and not u.action.is_empty() and u.action.skill.behavior == "trail" and not bool(u.action.get("queued", false))
		if bool(u.get("phase_active", false)) and not active and u.alive and not bool(u.action.get("flying", false)):
			released.append(u.uid)
		u["phase_active"] = active
	if separate: _separate_phasers(released)
	return released

func _separate_phasers(released: Array) -> void:
	var origins: Dictionary = {}
	for uid: int in released: origins[uid] = units[uid].pos
	Motion.correct_landings(units, released, ARENA_SIZE)
	for uid: int in released:
		var u: Dictionary = units[uid]
		if _legal_landing(u): continue
		# Dense crowds can trap the local projection; find the nearest sampled free spot.
		var origin: Vector2 = origins[uid]
		var found := false
		for radius in range(4, 1250, 4):
			for angle in range(48):
				var direction := Vector2(cos(TAU * angle / 48.0), sin(TAU * angle / 48.0))
				direction.x *= 1.0 if u.team == 0 else -1.0
				u.pos = Motion.clamp_position(Motion.translated(origin,direction * radius,ARENA_SIZE),u.definition.radius,ARENA_SIZE)
				if _legal_landing(u):
					found = true
					break
			if found: break
