extends SceneTree
const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _run() -> void:
	var dive: Resource = Catalog.load_units().eagle.skills[0]
	var opening := Sim.ticks(dive.initial_cooldown)
	var repeat_ticks := Sim.ticks(dive.cooldown)
	var dummy: Resource = Catalog.load_units().bear.duplicate(true)
	dummy.max_hp = 10000
	dummy.move_speed = 0.01
	dummy.skills.clear()
	var sim := Sim.new()
	sim.setup(["eagle"], ["monkey", "bear"], 1, {"definitions": {"bear": dummy}, "positions": [Vector2(200,250),Vector2(500,250),Vector2(950,250)]})
	for i in range(opening-1): sim.step()
	check(sim.units[0].skills_used.is_empty(), "No dive before individual opening")
	sim.step()
	check(sim.units[0].action.target == 2, "Farthest melee beats nearer ranged as dive target")
	check(sim.units[0].cooldowns.eagle_dive == opening+repeat_ticks, "Next dive uses recurring cooldown after opening")
	# Isolated durable opponent: repeated dive from point blank, with real damage.
	sim.setup(["eagle"], ["bear"], 1, {"definitions": {"bear": dummy}, "trace": true, "positions": [Vector2(450,250),Vector2(500,250)]})
	sim.units[0].hp = 10000
	for i in range(opening+2*repeat_ticks+60): sim.step()
	var starts: Array = sim.trace.filter(func(e: Dictionary) -> bool: return e.kind == "skill_start" and e.get("skill", "") == "eagle_dive")
	check(starts.size() == 3, "Three repeated dives")
	if starts.size() == 3:
		check(starts[0].tick == opening and starts[1].tick == opening+repeat_ticks and starts[2].tick == opening+2*repeat_ticks, "Exact cooldown timing")
	check(sim.units[0].damage_by_kind.get("skill", 0) == 3*dive.damage, "Three close dives apply full skill damage")
	check(sim.units[0].damage_by_kind.get("basic", 0) > 0, "Basic attacks between dives")
	# Choice is refreshed at cast, and a cooldown never makes the eagle chase far targets.
	sim.setup(["eagle"], ["bear", "bear"], 1, {"definitions": {"bear": dummy}, "positions": [Vector2(400,250),Vector2(450,250),Vector2(1000,250)]})
	sim.units[0].cooldowns.eagle_dive = 480
	sim.step()
	check(sim.units[0].target == 1, "Nearest combat target while dive is cooling down")
	sim.tick = 479
	sim.units[1].pos = Vector2(1000,250)
	sim.units[2].pos = Vector2(450,250)
	sim.step()
	check(sim.units[0].action.target == 1, "Dive chooses current farthest at activation")
	for preset: Dictionary in Catalog.presets():
		var a := Sim.new()
		var b := Sim.new()
		a.setup(preset.a, preset.b)
		b.setup(preset.b, preset.a)
		while a.result == "running" and a.time < 90: a.step()
		while b.result == "running" and b.time < 90: b.step()
		check(a.result != "running" and b.result != "running", "Preset ends: " + preset.name)
		var expected: String = "B" if a.result == "A" else ("A" if a.result == "B" else a.result)
		check(b.result == expected and a.tick == b.tick, "Mirror: " + preset.name)
		var dives: Array = []
		for u: Dictionary in a.units:
			if u.id == "eagle": dives.append(u.skills_used.get("eagle_dive", 0))
		print("PRESET %s duration=%.3f dives=%s" % [preset.name, a.time, dives])
	print("EAGLE REPEAT: %d checks; %d failures" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
