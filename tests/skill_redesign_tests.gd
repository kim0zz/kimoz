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

func advance(sim: RefCounted, count: int) -> void:
	for i in range(count): sim.step()

func _run() -> void:
	check(Catalog.validate().is_empty(), "Resource validation")
	var dummy: Resource = Catalog.load_units().monkey.duplicate(true)
	dummy.move_speed = 0.01
	dummy.max_hp = 1000
	dummy.skills.clear()
	var sim := Sim.new()
	sim.setup(["bear"], ["monkey", "monkey", "monkey"], 1, {"definitions": {"monkey": dummy}, "startup_skill_delay": 0, "positions": [Vector2(300,250),Vector2(390,225),Vector2(390,275),Vector2(210,250)]})
	sim._set_target(sim.units[0], 1, "fixture")
	sim._start_skill(sim.units[0], sim.units[0].definition.skills[0])
	advance(sim, 27)
	var cone_hp := 1000.0-float(sim.units[0].definition.skills[0].damage)
	check(sim.units[1].hp == cone_hp and sim.units[2].hp == cone_hp, "Cone hits both forward enemies")
	check(sim.units[3].hp == 1000, "Cone excludes rear enemy")
	sim.setup(["bear"], ["monkey"], 1, {"definitions": {"monkey": dummy}, "startup_skill_delay": 0, "positions": [Vector2(300,250),Vector2(390,250)]})
	sim.step()
	sim.units[1].pos = Vector2(210,250)
	advance(sim, 28)
	check(sim.units[1].hp == 1000, "Leaving telegraphed cone dodges strike")
	sim.setup(["hippo"], ["monkey"], 1, {"definitions": {"monkey": dummy}, "startup_skill_delay": 0, "positions": [Vector2(300,250),Vector2(360,250)]})
	advance(sim, 61)
	check(sim.units[1].hp == 1000.0-float(sim.units[0].definition.skills[0].damage) and sim.units[1].stun_remaining == 1.0, "Hippo deals skill damage and applies1s stun")
	var pos_before: Vector2 = sim.units[1].pos
	var fired_while_stunned := false
	for i in range(59):
		sim.step()
		for event: Dictionary in sim.events:
			if event.kind == "projectile" and event.source == 1: fired_while_stunned = true
	check(not fired_while_stunned and sim.units[1].pos == pos_before, "Stun blocks new attacks and movement; existing projectiles survive")
	sim.step()
	check(sim.units[1].stun_remaining == 0, "Stun expires on time")
	sim.setup(["skunk"], ["monkey"], 1, {"definitions": {"monkey": dummy}, "startup_skill_delay": 0, "positions": [Vector2(300,250),Vector2(420,250)]})
	advance(sim,16)
	check(sim.clouds.size() == 1 and sim.clouds[0].pos == Vector2(420,250), "Cloud is placed toward target, not on skunk")
	advance(sim,30)
	var pulse: float = sim.units[0].definition.skills[0].damage
	check(sim.units[1].damage_taken_by_kind.get("dot",0) == pulse, "Cloud first pulse")
	sim.units[1].pos = Vector2(650,250)
	advance(sim,30)
	check(sim.units[1].damage_taken_by_kind.get("dot",0) == pulse, "Leaving cloud stops damage")
	sim.units[1].pos = Vector2(420,250)
	advance(sim,30)
	check(sim.units[1].damage_taken_by_kind.get("dot",0) == 2*pulse, "Reentering cloud resumes damage")
	advance(sim,100)
	check(sim.clouds.is_empty() and sim.units[1].status_multiplier == 1, "Cloud expires without old weaken debuff")
	sim.setup(["rabbit", "bear"], ["bear", "bear"], 1, {"startup_skill_delay": 0, "positions": [Vector2(400,250),Vector2(300,350),Vector2(450,250),Vector2(450,350)]})
	sim.units[2].target = 0
	sim.units[3].target = 0
	sim.resolve_hits([{"source":2,"target":0,"damage":9,"kind":"basic","melee":true}])
	check(sim.units[2].target == 1 and sim.units[3].target == 1, "All attackers drop rabbit for alternative")
	check(sim.units[0].action.destination.x > sim.units[2].pos.x, "Rabbit destination behind attacker")
	advance(sim,15)
	check(sim.units[0].pos.x > sim.units[2].pos.x, "Rabbit leaps through to rear")
	check(sim.edge_distance(sim.units[0],sim.units[2]) >= -0.01, "Rabbit landing does not overlap attacker")
	sim.setup(["rabbit"], ["bear"], 1, {"startup_skill_delay":0})
	sim.units[1].target = 0
	sim.resolve_hits([{"source":1,"target":0,"damage":9,"kind":"basic","melee":true}])
	check(sim.units[1].target == 0, "1v1 enemy retains usable target")
	# Broader safety: a small representative set, not the full balance matrix.
	for preset: Dictionary in Catalog.presets():
		var a := Sim.new()
		var b := Sim.new()
		a.setup(preset.a,preset.b)
		b.setup(preset.b,preset.a)
		while a.result == "running" and a.time < 90: a.step()
		while b.result == "running" and b.time < 90: b.step()
		var expected: String = "B" if a.result == "A" else ("A" if a.result == "B" else a.result)
		check(a.result != "running" and b.result != "running", "Preset ends: " + preset.name)
		check(b.result == expected and a.tick == b.tick, "Mirror: " + preset.name)
		print("PRESET %s result=%s time=%.3f mirrored=%.3f" % [preset.name,a.result,a.time,b.time])
	print("SKILL REDESIGN: %d checks; %d failures" % [checks,failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
