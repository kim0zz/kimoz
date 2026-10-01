extends SceneTree
const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _run() -> void:
	check(Catalog.validate().is_empty(), "Definitions validate")
	var sim := Sim.new()
	var stationary: Resource = Catalog.load_units().hedgehog.duplicate(true)
	stationary.move_speed = 0.01
	sim.setup(["skunk"], ["hedgehog"], 1, {"definitions": {"hedgehog": stationary}, "positions": [Vector2(400,250),Vector2(530,250)]})
	var source: Vector2 = sim.units[0].pos
	for i in range(90): sim.step()
	check(sim.units[0].damage_dealt > 0, "Skunk damages at distance")
	check(sim.units[0].damage_taken_by_kind.get("thorns", 0) == 0, "Ranged basic does not trigger thorns")
	check(sim.units[0].pos.distance_to(source) < 100, "No uncontrolled retreat")
	sim.setup(["skunk"], ["bear"], 1, {"positions": [Vector2(400,250),Vector2(490,250)]})
	var cloud: Resource = sim.units[0].definition.skills[0]
	for i in range(Sim.ticks(cloud.initial_cooldown+cloud.windup+cloud.hit_interval)+2): sim.step()
	check(sim.units[1].damage_taken_by_kind.get("dot",0) > 0, "Cloud damages enemies in its area")
	sim.setup(["skunk"], ["eagle"], 1, {"disable_skills": true, "positions": [Vector2(400,250),Vector2(450,250)]})
	for i in range(75): sim.step()
	check(sim.units[0].pos == Vector2(400,250), "Caught skunk stands and fires")
	check(sim.units[0].damage_dealt > 0, "Caught skunk can fight back")
	sim.setup(["eagle"], ["bear", "skunk"])
	for i in range(Sim.ticks(sim.units[0].definition.skills[0].initial_cooldown)): sim.step()
	check(sim.units[0].action.get("target", -1) == 2, "Dive recognises skunk as backline")
	for preset: Dictionary in Catalog.presets():
		var a := Sim.new()
		var b := Sim.new()
		a.setup(preset.a, preset.b)
		b.setup(preset.b, preset.a)
		while a.result == "running" and a.time < 90: a.step()
		while b.result == "running" and b.time < 90: b.step()
		check(a.result != "running" and b.result != "running", "Preset finishes: " + preset.name)
		var expected: String = "B" if a.result == "A" else ("A" if a.result == "B" else a.result)
		check(b.result == expected and a.tick == b.tick, "Preset mirror: " + preset.name)
		print("PRESET %s result=%s duration=%.3f" % [preset.name, a.result, a.time])
	print("SKUNK RANGED: %d checks; %d failures" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
