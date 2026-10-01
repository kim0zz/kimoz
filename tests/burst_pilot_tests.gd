extends SceneTree
const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Variants = preload("res://scripts/data/combat_variants.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _run() -> void:
	var baseline: Dictionary = Variants.definitions("A")
	var candidate: Dictionary = Variants.definitions("B")
	var ids: Array[String] = Catalog.ids() + Catalog.hybrid_ids()
	_check(baseline.size() == ids.size() + Catalog.lvl3_ids().size() and candidate.size() == baseline.size(), "A and B provide every roster definition")
	var snapshot: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/balance/full_roster_baseline.json"))
	var sources: Dictionary = Catalog.load_units()
	for id in ids:
		_check(_matches_snapshot(baseline[id], snapshot.units[id]), "A restores the complete pre-rollout numeric snapshot for " + id)
		_check(candidate[id] != sources[id] and candidate[id].skills[0] != sources[id].skills[0], "B deep-clones unit and skill resources for " + id)
		for skill in candidate[id].skills:
			if skill.behavior == "thorns":
				_check(skill.initial_cooldown == 0.0, id + "/" + skill.id + " passive thorns stay ready at tick zero")
			else:
				_check(skill.initial_cooldown > 0.0, id + "/" + skill.id + " active skill has its own opening deadline")

	_check(baseline.eagle_hippo.skills[0].damage == 80.0 and baseline.eagle_hippo.attack_damage == 6.0, "A preserves the live Eagle/Hippo pilot before full-roster rollout")
	_check(baseline.monkey_hippo.skills[0].damage == 65.0 and baseline.monkey_hippo.attack_damage == 6.0, "A preserves the live Monkey/Hippo pilot before full-roster rollout")
	_check(baseline.bear_cheetah.skills[0].damage == 24.0 and baseline.bear_cheetah.attack_damage == 6.0, "A preserves the live Bear/Cheetah pilot before full-roster rollout")
	_check(candidate.rabbit.attack_damage == 5.5, "Rabbit retains its basic damage because its skill contributes mobility and aggro control")
	_check(candidate.hedgehog.attack_damage == 5.5 and candidate.hedgehog.skills[0].damage == 3.0, "Hedgehog keeps a modest basic reduction and stronger contact thorns")
	_check(candidate.eagle_hippo.skills[0].damage == 80.0 and candidate.monkey_hippo.skills[0].damage == 65.0 and candidate.bear_cheetah.skills[0].damage == 24.0, "The three pilot B numbers remain unchanged during expansion")

	# Test clone isolation across each unit class, including a lvl1 parent and a non-pilot hybrid.
	candidate.bear.skills[0].damage = 999.0
	candidate.bear_cheetah.skills[0].damage = 998.0
	candidate.eagle_hedgehog.skills[0].damage = 997.0
	_check(sources.bear.skills[0].damage == 45.0, "Mutating the B lvl1 clone cannot mutate its source Resource")
	_check(sources.bear_cheetah.skills[0].damage == 24.0, "Mutating the pilot clone cannot mutate its source Resource")
	_check(sources.eagle_hedgehog.skills[0].damage == 40.0, "Mutating a non-pilot hybrid clone cannot mutate its source Resource")
	_check(baseline.bear.skills[0].damage == 25.0 and baseline.eagle_hedgehog.skills[0].damage == 22.0, "A clones are isolated from mutations made through B")

	var dummy: ZooUnitDefinition = sources.bear.duplicate(true)
	dummy.id = "durable_dummy"
	dummy.max_hp = 100000.0
	dummy.attack_damage = 0.01
	dummy.move_speed = 0.01
	dummy.skills.clear()
	var overrides: Dictionary = Variants.definitions("B")
	overrides["durable_dummy"] = dummy
	var deadline_checks := 0
	for id in ids:
		var sim := Sim.new()
		sim.setup([id], ["durable_dummy"], 1, {"definitions":overrides})
		var actor: Dictionary = sim.units[0]
		var definition: ZooUnitDefinition = overrides[id]
		for skill in definition.skills:
			var expected := 0 if skill.behavior == "thorns" else ceili(skill.initial_cooldown * 60.0)
			_check(int(actor.cooldowns.get(skill.id, -1)) == expected, id + "/" + skill.id + " readiness uses its resource opening deadline")
			deadline_checks += 1
	_check(deadline_checks == 24, "All 24 active/passive skill entries were checked for correct first readiness")

	var repeat := Sim.new()
	repeat.setup(["eagle_hippo"], ["durable_dummy"], 1, {"definitions":overrides, "trace":true, "positions":[Vector2(500,250),Vector2(550,250)]})
	for _i in range(1080): repeat.step()
	var starts: Array = repeat.trace.filter(func(event: Dictionary) -> bool: return event.kind == "skill_start" and event.get("skill", "") == "eagle_hippo_dive")
	_check(starts.size() == 2, "Pilot repeats after the normal recurring cooldown")
	if starts.size() == 2:
		_check(starts[0].tick == 300 and starts[1].tick - starts[0].tick == 720, "Repeated deadline starts at the 5s initial delay then 12s apart")

	print("FULL ROSTER VARIANT TARGETED TESTS: %d checks; %d failures" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)

func _matches_snapshot(unit: ZooUnitDefinition, entry: Dictionary) -> bool:
	for property_name in entry.unit:
		if unit.get(property_name) != entry.unit[property_name]: return false
	if unit.skills.size() != entry.skills.size(): return false
	for index in unit.skills.size():
		var skill: ZooSkillDefinition = unit.skills[index]
		var numbers: Dictionary = entry.skills[index]
		for property_name in numbers:
			if skill.get(property_name) != numbers[property_name]: return false
	return true
