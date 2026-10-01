extends SceneTree
## Focused lvl3 data, fusion, and combat regressions.
const Catalog = preload("res://scripts/data/catalog.gd")
const MatchModel = preload("res://scripts/match/match_model.gd")
const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Variants = preload("res://scripts/data/combat_variants.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _run() -> void:
	_test_matrix_and_traits()
	_test_nested_variant_isolation()
	_test_draft_and_fusion()
	_test_followup()
	_test_last_hit_control()
	_test_area_impacts()
	_test_multileg_mobility()
	_test_reactive_interrupt()
	print("LVL3 TARGETED TESTS: %d checks; %d failures" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)

func _test_matrix_and_traits() -> void:
	var units: Dictionary = Catalog.load_units()
	_check(Catalog.lvl3_ids().size() == 12, "Catalog exposes twelve lvl3 identities")
	_check(Catalog.validate().is_empty(), "All lvl1, lvl2, and lvl3 Resources validate")
	var counts: Dictionary = {}
	var pair_keys: Dictionary = {}
	for id in Catalog.lvl3_ids():
		if not units.has(id): continue
		var hybrid: Resource = units[id]
		var parents: Array = hybrid.parents
		if parents.size() != 2 or not units.has(parents[0]) or not units.has(parents[1]): continue
		counts[parents[0]] = int(counts.get(parents[0], 0)) + 1
		counts[parents[1]] = int(counts.get(parents[1], 0)) + 1
		var pair_ids: Array[String] = [str(parents[0]), str(parents[1])]
		pair_ids.sort()
		var key := "|".join(pair_ids)
		_check(not pair_keys.has(key), "Each lvl2 parent pair has one unique lvl3 result: " + key)
		pair_keys[key] = id
		_check(Catalog.fusion(parents[0], parents[1]) == id, "Parent pair resolves to its lvl3 result: " + id)
		var traits: Array[String] = Catalog.base_traits(id)
		var unique_traits: Dictionary = {}
		for trait_id in traits: unique_traits[trait_id] = true
		_check(traits.size() == 4 and unique_traits.size() == 4, id + " contains four unique base traits")
		var left: Array[String] = Catalog.base_traits(str(parents[0]))
		var right: Array[String] = Catalog.base_traits(str(parents[1]))
		_check(left.size() == 2 and right.size() == 2, id + " parents each contain two base traits")
		_check(left.filter(func(trait_id: String) -> bool: return trait_id in right).is_empty(), id + " parents share no base animal")
	for id in Catalog.hybrid_ids():
		_check(int(counts.get(id, 0)) == 2, id + " has exactly two lvl3 partners")

func _test_draft_and_fusion() -> void:
	var model := MatchModel.new()
	model.begin_match(4107)
	_check(model.offers.size() == 8, "Initial draft offers all eight base animals")
	_check(model.offers.size() == Catalog.ids().size() and model.offers.all(func(id: String) -> bool: return id in Catalog.ids()), "Initial offers contain only base animals")
	while model.phase == "initial_draft":
		model.pick(0)
	_check(model.phase == "prep", "Initial ABBA draft completes after four picks")
	_check(model.teams[0].size() == 2 and model.teams[1].size() == 2, "ABBA gives each player two lvl1 units")
	_check(model.actions_left == [0, 0], "Initial picks consume exactly two actions per player")
	_check(model._actions_for_lives(5) == 2 and model._actions_for_lives(3) == 2, "Three to five lives grant two draft actions")
	_check(model._actions_for_lives(2) == 2 and model._actions_for_lives(1) == 2, "Low lives keep two base actions; comeback bonuses are tracked per player")

	var selected: Resource = Catalog.load_units()[Catalog.lvl3_ids()[0]]
	var left_id: String = selected.parents[0]
	var right_id: String = selected.parents[1]
	var fusion_model := MatchModel.new()
	fusion_model.phase = "draft"
	fusion_model.turn_player = 0
	fusion_model.actions_left = [2, 1]
	fusion_model.offers = Catalog.ids()
	fusion_model.teams[0] = [
		{"id": left_id, "active": true, "token": 11},
		{"id": right_id, "active": true, "token": 12},
	]
	fusion_model.next_token = 13
	var actions_before: int = fusion_model.actions_left[0]
	_check(fusion_model.can_fuse(0), "Two compatible lvl2 units can be fused during a draft")
	_check(fusion_model.fuse(11, 12), "Lvl2 fusion action succeeds")
	_check(fusion_model.teams[0].size() == 1 and fusion_model.teams[0][0].id == selected.id, "Fusion removes both lvl2 parents and creates their lvl3")
	_check(fusion_model.actions_left[0] == actions_before - 1, "Lvl2 fusion consumes one action")
	_check(bool(fusion_model.teams[0][0].active), "Lvl3 inherits active status from its parents")

func _test_nested_variant_isolation() -> void:
	var sources: Dictionary = Catalog.load_units()
	var owner_id := ""
	var owner_skill_index := -1
	var source_skill: Resource
	for id in Catalog.lvl3_ids():
		for index in sources[id].skills.size():
			var skill: Resource = sources[id].skills[index]
			if skill.followup_skill != null:
				owner_id = id
				owner_skill_index = index
				source_skill = skill
				break
		if not owner_id.is_empty(): break
	_check(not owner_id.is_empty(), "At least one lvl3 skill has a nested followup Resource")
	if owner_id.is_empty(): return
	var a: Dictionary = Variants.definitions("A")
	var b: Dictionary = Variants.definitions("B")
	var a_skill: Resource = a[owner_id].skills[owner_skill_index]
	var b_skill: Resource = b[owner_id].skills[owner_skill_index]
	_check(a_skill.followup_skill != null and b_skill.followup_skill != null, "A and B preserve nested followup Resources")
	_check(a_skill.followup_skill != b_skill.followup_skill and b_skill.followup_skill != source_skill.followup_skill,
		"Nested followup is independently cloned for A, B, and source")
	var source_damage: float = source_skill.followup_skill.damage
	var b_damage: float = b_skill.followup_skill.damage
	a_skill.followup_skill.damage = source_damage + 1000.0
	_check(is_equal_approx(source_skill.followup_skill.damage, source_damage), "Changing A nested followup cannot mutate its source")
	_check(is_equal_approx(b_skill.followup_skill.damage, b_damage), "Changing A nested followup cannot mutate B")

func _dummy(id: String, max_hp: float = 10000.0) -> Resource:
	var unit: Resource = Catalog.load_units().bear.duplicate(true)
	unit.id = id
	unit.display_name = id
	unit.max_hp = max_hp
	unit.attack_damage = 0.01
	unit.attack_interval = 1000.0
	unit.attack_enabled = false
	unit.move_speed = 0.01
	unit.attack_range = 500.0
	unit.skills.clear()
	return unit

func _skill(id: String, behavior: String = "heavy") -> ZooSkillDefinition:
	var skill := ZooSkillDefinition.new()
	skill.id = id
	skill.behavior = behavior
	skill.initial_cooldown = 0.0
	skill.cooldown = 60.0
	skill.range = 300.0
	skill.windup = 0.0
	skill.recovery = 0.05
	skill.damage = 5.0
	skill.hits = 1
	skill.hit_interval = 0.05
	skill.speed = 2500.0
	skill.duration = 0.05
	skill.stun_duration = 0.6
	return skill

func _simulation(skill: ZooSkillDefinition, enemy_count: int = 1) -> RefCounted:
	var attacker: Resource = _dummy("lvl3_test_attacker", 10000.0)
	attacker.level = 3
	var parent_ids: Array[String] = ["bear_cheetah", "monkey_hippo"]
	var attacker_skills: Array[ZooSkillDefinition] = [skill]
	attacker.parents = parent_ids
	attacker.skills = attacker_skills
	var defs := {"lvl3_test_attacker": attacker}
	var enemy_ids: Array[String] = []
	var positions: Array[Vector2] = [Vector2(300, 250)]
	for i in enemy_count:
		var id := "lvl3_test_enemy_%d" % i
		defs[id] = _dummy(id)
		enemy_ids.append(id)
		positions.append(Vector2(410.0 + i * 12.0, 250.0 + i * 4.0))
	var sim := Sim.new()
	sim.setup(["lvl3_test_attacker"], enemy_ids, 1, {"trace": true, "definitions": defs, "positions": positions, "startup_skill_delay": 0.0})
	sim.units[0].target = 1
	sim.units[0].facing = Vector2.RIGHT
	return sim

func _advance(sim: RefCounted, frames: int) -> void:
	for _i in frames:
		if sim.result != "running": return
		sim.step()

func _skill_events(sim: RefCounted, kind: String, skill_id: String = "") -> Array:
	return sim.trace.filter(func(event: Dictionary) -> bool:
		return event.kind == kind and (skill_id.is_empty() or event.get("skill", "") == skill_id)
	)

func _test_followup() -> void:
	var first := _skill("lvl3_opener")
	first.hits = 2
	first.hit_interval = 0.05
	var follow := _skill("lvl3_followup", "projectile")
	follow.damage = 3.0
	first.followup_skill = follow
	var sim := _simulation(first, 2)
	sim._start_skill(sim.units[0], first)
	var saw_queued := false
	for _i in 40:
		sim.step()
		if bool(sim.units[0].action.get("queued", false)):
			saw_queued = true
			_check(int(sim.units[0].action.target) == 1, "Followup queue retains the original target")
			sim.units[0].target = 2
			break
	_check(saw_queued, "Natural completion queues its nested followup Resource")
	if saw_queued:
		sim.step()
		var started := _skill_events(sim, "skill_start", "lvl3_followup")
		_check(started.size() == 1 and int(started[0].target) == 1, "Followup starts against its original target after natural completion")

	var interrupted := _simulation(first, 1)
	interrupted._start_skill(interrupted.units[0], first)
	for _i in 40:
		interrupted.step()
		if bool(interrupted.units[0].action.get("queued", false)): break
	interrupted.resolve_hits([{"source": 1, "target": 0, "damage": 1.0, "kind": "basic", "melee": false, "stun": 0.5}])
	_check(interrupted.units[0].action.is_empty(), "Stun cancels a queued followup")
	_advance(interrupted, 3)
	_check(_skill_events(interrupted, "skill_start", "lvl3_followup").is_empty(), "Cancelled followup never starts after stun")

	var dead_target := _simulation(first, 1)
	dead_target._start_skill(dead_target.units[0], first)
	for _i in 40:
		dead_target.step()
		if bool(dead_target.units[0].action.get("queued", false)): break
	dead_target.units[1].alive = false
	dead_target.units[1].hp = 0.0
	dead_target.step()
	_check(_skill_events(dead_target, "skill_start", "lvl3_followup").is_empty(), "Dead original target cancels the followup")

func _test_last_hit_control() -> void:
	var projectile := _skill("lvl3_projectile_series", "projectile")
	projectile.hits = 3
	projectile.hit_interval = 0.08
	projectile.stun_last_hit_only = true
	var ranged := _simulation(projectile)
	ranged._start_skill(ranged.units[0], projectile)
	_advance(ranged, 90)
	_check(_skill_events(ranged, "stun").size() == 1, "Projectile series stuns only on its final hit")
	_check(ranged.units[1].stun_uptime > 0.0, "Final projectile applies its configured stun")

	var cone := _skill("lvl3_cone_series", "cone")
	cone.hits = 3
	cone.hit_interval = 0.08
	cone.stun_last_hit_only = true
	cone.cone_angle = 100.0
	var melee := _simulation(cone, 2)
	melee._start_skill(melee.units[0], cone)
	_advance(melee, 40)
	_check(_skill_events(melee, "stun").size() == 2, "Cone stuns each target only on the series final hit")

	var dive := _skill("lvl3_three_pass_dive", "dive")
	dive.range = 8.0
	dive.speed = 2200.0
	dive.duration = 0.05
	dive.airborne_hits = 3
	dive.hit_interval = 0.03
	dive.stun_last_hit_only = true
	var flyer := _simulation(dive)
	flyer._start_skill(flyer.units[0], dive)
	_advance(flyer, 100)
	_check(_skill_events(flyer, "stun").size() == 1, "Repeated dive stuns only on its final landing")
	_check(flyer.units[0].action.is_empty(), "Three-leg dive completes cleanly")

func _test_area_impacts() -> void:
	var cone := _skill("lvl3_banana_cone", "cone")
	cone.range = 220.0
	cone.cone_projectile_damage = 2.0
	cone.impact_cloud = true
	cone.cloud_damage = 1.0
	cone.duration = 3.0
	cone.hit_interval = 0.2
	var sim := _simulation(cone)
	sim._start_skill(sim.units[0], cone)
	_advance(sim, 35)
	_check(not sim.projectiles.is_empty() or not sim.clouds.is_empty(), "Cone launches its banana impact projectile")
	_check(sim.clouds.any(func(cloud: Dictionary) -> bool: return cloud.source == 0), "Banana impact creates its configured cloud")

	var landing_cone := _skill("lvl3_landing_cone", "dive")
	landing_cone.range = 100.0
	landing_cone.speed = 2200.0
	landing_cone.duration = 0.05
	landing_cone.landing_cone = true
	landing_cone.cone_angle = 360.0
	landing_cone.damage = 7.0
	var cone_sim := _simulation(landing_cone)
	cone_sim._start_skill(cone_sim.units[0], landing_cone)
	_advance(cone_sim, 30)
	_check(_skill_events(cone_sim, "cone_hit").size() == 1, "Dive resolves its landing cone at the impact point")
	_check(cone_sim.units[1].damage_taken_by_kind.get("skill", 0.0) >= landing_cone.damage, "Landing cone damages the target")

	var landing_cloud := _skill("lvl3_landing_cloud", "dive")
	landing_cloud.range = 8.0
	landing_cloud.speed = 2200.0
	landing_cloud.duration = 0.05
	landing_cloud.landing_cloud = true
	landing_cloud.cloud_damage = 1.0
	landing_cloud.cloud_duration = 1.0
	landing_cloud.hit_interval = 0.2
	var cloud_sim := _simulation(landing_cloud)
	cloud_sim._start_skill(cloud_sim.units[0], landing_cloud)
	_advance(cloud_sim, 20)
	_check(cloud_sim.clouds.any(func(cloud: Dictionary) -> bool: return cloud.source == 0), "Dive creates its configured landing cloud")

	var timed_cloud := _skill("lvl3_timed_cloud", "cloud")
	timed_cloud.duration = 1.0
	timed_cloud.hit_interval = 0.5
	timed_cloud.cloud_tick_interval = 0.2
	var timed := _simulation(timed_cloud)
	timed._start_skill(timed.units[0], timed_cloud)
	_advance(timed, 5)
	_check(not timed.clouds.is_empty() and int(timed.clouds[0].interval) == Sim.ticks(0.2), "Cloud uses its explicit pulse cadence")

func _test_reactive_interrupt() -> void:
	var cast := _skill("lvl3_grounded_cast")
	cast.windup = 1.0
	var reaction := _skill("lvl3_reactive_dash", "dash")
	reaction.interrupt_on_hit = true
	var attacker: Resource = _dummy("lvl3_test_attacker", 10000.0)
	attacker.level = 3
	var cast_skills: Array[ZooSkillDefinition] = [cast, reaction]
	attacker.skills = cast_skills
	var enemy: Resource = _dummy("lvl3_test_enemy")
	var sim := Sim.new()
	sim.setup(["lvl3_test_attacker"], ["lvl3_test_enemy"], 1,
		{"trace": true, "definitions": {"lvl3_test_attacker": attacker, "lvl3_test_enemy": enemy},
		"positions": [Vector2(300, 250), Vector2(410, 250)], "startup_skill_delay": 0.0})
	sim.units[0].target = 1
	sim._start_skill(sim.units[0], cast)
	sim.resolve_hits([{"source": 1, "target": 0, "damage": 1.0, "kind": "basic", "melee": false}])
	_check(not sim.units[0].action.is_empty() and sim.units[0].action.skill.id == reaction.id,
		"Reactive dash interrupts a grounded cast after a direct hit")

	var trail := _skill("lvl3_phase_trail", "trail")
	trail.duration = 2.0
	trail.cloud_duration = 1.0
	trail.puff_interval = 0.2
	trail.hit_interval = 0.2
	var phased_dash := _skill("lvl3_phase_dash", "dash")
	phased_dash.interrupt_on_hit = true
	phased_dash.duration = 0.15
	phased_dash.dash_mode = "rear"
	phased_dash.distance = 80.0
	var phasing_attacker: Resource = _dummy("lvl3_test_attacker", 10000.0)
	phasing_attacker.level = 3
	var phasing_skills: Array[ZooSkillDefinition] = [trail, phased_dash]
	phasing_attacker.skills = phasing_skills
	var phasing_enemy: Resource = _dummy("lvl3_test_enemy")
	var transition := Sim.new()
	transition.setup(["lvl3_test_attacker"], ["lvl3_test_enemy"], 1,
		{"definitions": {"lvl3_test_attacker": phasing_attacker, "lvl3_test_enemy": phasing_enemy},
		"positions": [Vector2(300, 250), Vector2(410, 250)], "startup_skill_delay": 0.0})
	transition.units[0].target = 1
	transition._start_skill(transition.units[0], trail)
	transition.units[0].pos = transition.units[1].pos
	var overlap_origin: Vector2 = transition.units[0].pos
	transition.resolve_hits([{"source": 1, "target": 0, "damage": 1.0, "kind": "basic", "melee": false}])
	_check(bool(transition.units[0].action.get("flying", false)), "Hit interrupts the trail into an airborne reactive dash")
	_check(transition.units[0].pos == overlap_origin, "Trail to dash transition preserves the overlapping flight origin")
	_advance(transition, 20)
	_check(transition.units[0].pos.distance_to(transition.units[1].pos) >= transition.units[0].definition.radius + transition.units[1].definition.radius - 0.01,
		"Interrupted trail dash lands with legal body separation")


func _test_multileg_mobility() -> void:
	var dash := _skill("lvl3_three_hop_dash", "dash")
	dash.range = 300.0
	dash.duration = 0.06
	dash.airborne_hits = 3
	dash.dash_mode = "side"
	dash.distance = 90.0
	var sim := _simulation(dash)
	sim._start_skill(sim.units[0], dash)
	var highest_leg := 0
	for _i in 60:
		if not sim.units[0].action.is_empty(): highest_leg = maxi(highest_leg, int(sim.units[0].action.get("leg", 0)))
		sim.step()
	_check(highest_leg >= 1, "Repeated dash begins its second airborne leg")
	_check(sim.units[0].action.is_empty(), "Three-leg dash returns to neutral after landing")
