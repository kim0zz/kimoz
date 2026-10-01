extends SceneTree

const Sim = preload("res://scripts/combat/teamfight_simulation.gd")
const TeamfightData = preload("res://scripts/data/teamfight_definitions.gd")
const Catalog = preload("res://scripts/data/catalog.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_cloned_roster_and_skill_count()
	_test_heal_shield_taunt_and_interrupt()
	_test_retreat_and_plan()
	_test_pursuit_and_reaction()
	for preset: Dictionary in TeamfightData.presets():
		var sim := Sim.new()
		_check(sim.setup(preset.a, preset.b, 5), "Preset setup: " + str(preset.name))
		for _frame in range(1800):
			if sim.result != "running": break
			sim.step()
		_check(not sim.validation_errors.size() > 0, "No validation issues in " + str(preset.name))
		_check(sim.units.size() == preset.a.size() + preset.b.size(), "Team size survives setup for " + str(preset.name))
	print("TEAMFIGHT TESTS: %d assertions; %d failures" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)

func _test_cloned_roster_and_skill_count() -> void:
	var defs := TeamfightData.definitions()
	_check(defs.size() == 6, "Teamfight returns six units")
	for unit_id in ["hippo", "monkey", "hedgehog", "cheetah", "skunk", "eagle"]:
		_check(defs.has(unit_id) and defs[unit_id].skills.size() == 2, "Two active skills for " + unit_id)
		_check(defs[unit_id].validate().is_empty(), "Valid unit and skill parameters for " + unit_id)
	_check(Catalog.load_units()["monkey"].skills.size() == 1, "Catalog skill list remains untouched")
	_check(Catalog.load_units()["monkey"].skills[0].id == "monkey_banana", "Catalog monkey skill remains untouched")

func _test_heal_shield_taunt_and_interrupt() -> void:
	var sim := Sim.new()
	var positions := [Vector2(330, 250), Vector2(260, 250), Vector2(380, 320), Vector2(430, 250), Vector2(470, 330), Vector2(520, 250)]
	_check(sim.setup(["hippo", "monkey", "hedgehog"], ["cheetah", "skunk", "eagle"], 2, {"positions": positions, "trace": true}), "Support fixture setup")
	var hippo: Dictionary = sim.units[0]
	var monkey: Dictionary = sim.units[1]
	var hedgehog: Dictionary = sim.units[2]
	var cheetah: Dictionary = sim.units[3]
	var heal_skill: Resource = _skill(monkey, "tf_monkey_heal")
	var shield_skill: Resource = _skill(hedgehog, "tf_hedgehog_shield")
	var taunt_skill: Resource = _skill(hippo, "tf_hippo_taunt")
	var cry_skill: Resource = _skill(monkey, "tf_monkey_cry")

	hippo.hp -= 36.0
	monkey.cooldowns[heal_skill.id] = 0
	_check(sim._try_skill(monkey), "Healer AI selects an injured ally and starts its heal")
	for _frame in range(90): sim.step()
	_check(float(monkey.healing_done) > 0.0 and hippo.hp > hippo.definition.max_hp - 36.0, "Heal restores real ally HP and credits the caster")
	_check(_has_event(sim, "heal"), "Heal emits a compatible support event")

	sim._grant_shield(hedgehog, hippo, shield_skill, 30.0, "shield")
	var old_hp: float = hippo.hp
	sim._apply_damage_batch([{"source": cheetah.uid, "target": hippo.uid, "damage": 18.0,
		"kind": "basic", "skill": "", "melee": true, "projectile": false, "max_range": 100.0}])
	_check(is_equal_approx(float(hippo.hp), old_hp), "Shield absorbs incoming damage before HP")
	_check(is_equal_approx(float(hippo.shield_hp), 12.0), "Shield keeps the remaining absorption pool")
	_check(is_equal_approx(float(hedgehog.shield_absorbed), 18.0), "Shield absorption is credited to protector")
	_check(_has_event(sim, "shield_absorb"), "Shield absorption emits feedback event")

	# Taunt redirects later target selection only; it leaves any committed action intact.
	cheetah.target = hedgehog.uid
	var committed := {"target": hedgehog.uid, "skill": _skill(cheetah, "tf_cheetah_flurry")}
	cheetah.action = committed.duplicate()
	sim._apply_taunt(hippo, hedgehog, taunt_skill)
	_check(int(cheetah.taunt_target) == hippo.uid, "Taunt stores the hippo as forced target")
	_check(sim._choose_target(cheetah) == hippo.uid, "Taunt affects a future target choice")
	_check(not cheetah.action.is_empty(), "Taunt does not cancel an already committed action")
	_check(_has_event(sim, "taunt"), "Taunt emits an event per redirected enemy")

	cheetah.action = {"skill": _skill(cheetah, "tf_cheetah_flurry"), "target": hippo.uid}
	sim._interrupt_target(monkey, cheetah, cry_skill, 0.35)
	_check(cheetah.action.is_empty() and int(monkey.interrupts) == 1, "Interrupt records a canceled active action")
	_check(_has_event(sim, "interrupt"), "Interrupt emits a support event")
	_check(int(monkey.get("healing_done", 0)) > 0, "Support telemetry is initialized")

func _test_retreat_and_plan() -> void:
	var sim := Sim.new()
	var positions := [Vector2(390, 250), Vector2(455, 250), Vector2(520, 250)]
	_check(sim.setup(["hippo", "monkey"], ["cheetah"], 3, {"positions": positions}), "Retreat fixture setup")
	var hippo: Dictionary = sim.units[0]
	var monkey: Dictionary = sim.units[1]
	var cheetah: Dictionary = sim.units[2]
	monkey.hp = 25.0
	cheetah.target = monkey.uid
	var move: Variant = sim._override_movement(monkey, cheetah, sim.edge_distance(monkey, cheetah))
	_check(move is Vector2 and Vector2(move).x < 0.0, "Fragile low-HP unit retreats behind its protector")
	_check(bool(monkey.teamfight_retreating), "Retreat remains active while the attacker holds aggro")
	_check(str(monkey.teamfight_plan.get("kind", "")) == "retreat", "Plan reports the retreat state")
	_check(int(monkey.retreats) == 1, "Retreat telemetry increments once")
	var target := sim._choose_target(monkey)
	monkey.teamfight_plan = {"target": target, "until": sim.tick + 150, "kind": "engage"}
	var retained := sim._choose_target(monkey)
	_check(retained == target, "Utility target stays stable during its planning window")

func _skill(unit: Dictionary, skill_id: String) -> Resource:
	for skill: Resource in unit.definition.skills:
		if str(skill.id) == skill_id: return skill
	return null

func _has_event(sim: RefCounted, event_kind: String) -> bool:
	for event: Dictionary in sim.events:
		if str(event.get("kind", "")) == event_kind: return true
	for event: Dictionary in sim.trace:
		if str(event.get("kind", "")) == event_kind: return true
	return false


func _test_pursuit_and_reaction() -> void:
	var sim := Sim.new()
	sim.setup(["hippo", "eagle"], ["monkey", "hippo"], 7, {"positions":[Vector2(300,200),Vector2(300,300),Vector2(480,250),Vector2(560,250)]})
	sim.units[2].teamfight_retreating = true
	for uid in [0, 1]: sim.units[uid].target = 2
	_check(sim._choose_target(sim.units[0]) == 3, "Tank abandons a costly chase when a reachable opponent remains")
	_check(sim._choose_target(sim.units[1]) == 2, "Assassin values pursuing the exposed backline more highly")
	sim._set_target(sim.units[0], 2, "blocked_by_enemy")
	_check(sim._choose_target(sim.units[0]) == 2, "Contact with blocking opponent updates the stable plan instead of oscillating every frame")
	var eagle: Dictionary = sim.units[1]
	var enemy: Dictionary = sim.units[2]
	eagle.cooldowns["tf_eagle_evade"] = 0
	enemy.action = {"target":eagle.uid, "skill":enemy.definition.skills[1]}
	_check(not sim._try_evasion(eagle), "Visible threat does not trigger an instantaneous dodge")
	sim.tick = 26
	_check(not sim._try_evasion(eagle), "Eagle must wait through its reaction delay")
	sim.tick = 27
	_check(sim._try_evasion(eagle) and str(eagle.action.get("teamfight_kind", "")) == "evade", "Visible persistent threat can trigger a delayed skill dodge")
	_check(int(eagle.cooldowns["tf_eagle_evade"]) > sim.tick, "Reactive dodge spends its cooldown")
	var old_hp: float = eagle.hp
	sim._apply_damage_batch([{"source":enemy.uid,"target":eagle.uid,"damage":9.0,"kind":"skill","skill":"fixture"}])
	_check(eagle.hp < old_hp, "Dodging does not grant invulnerability")
	var taunt_sim := Sim.new()
	taunt_sim.setup(["hippo", "monkey"], ["cheetah"], 8, {"positions":[Vector2(300,250),Vector2(380,250),Vector2(440,250)]})
	var tank: Dictionary = taunt_sim.units[0]
	tank.target = 2
	tank.cooldowns["tf_hippo_taunt"] = 0
	taunt_sim.units[2].target = 1
	_check(taunt_sim._try_skill(tank) and tank.action.skill.id == "tf_hippo_taunt", "Automatic taunt selection protects an allied target in range")
	var skunk: Resource = TeamfightData.definitions().skunk
	_check(not skunk.attack_enabled and skunk.skills[0].behavior == "trail", "Controller preserves moving stink without basic hits")
