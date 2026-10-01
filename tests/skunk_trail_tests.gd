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

func advance(sim: RefCounted, frames: int) -> void:
	for _i in range(frames):
		if sim.result == "running": sim.step()

func anchored_dummy() -> Resource:
	var dummy: Resource = Catalog.load_units().monkey.duplicate(true)
	dummy.id = "trail_dummy"
	dummy.display_name = "Trail dummy"
	dummy.max_hp = 10000
	dummy.attack_damage = 0.01
	dummy.attack_interval = 1000
	dummy.move_speed = 0.01
	dummy.attack_enabled = false
	dummy.skills.clear()
	return dummy

func _run() -> void:
	var loaded: Dictionary = Catalog.load_units()
	check(Catalog.validate().is_empty(), "Definitions validate")
	for id in ["skunk", "hedgehog_skunk", "skunk_rabbit"]:
		var definition: Resource = loaded[id]
		check(not definition.attack_enabled, id + " has no basic attack")
		check(definition.skills.any(func(s: Resource) -> bool: return s.behavior == "trail"), id + " has an active trail skill")

	var dummy: Resource = anchored_dummy()
	var sim := Sim.new()
	sim.setup(["skunk"], ["trail_dummy"], 1, {"trace": true, "startup_skill_delay": 0.0,
		"definitions": {"trail_dummy": dummy}, "positions": [Vector2(400, 250), Vector2(500, 250)]})
	var origin: Vector2 = sim.units[0].pos
	advance(sim, 70)
	var trail_events: Array = sim.trace.filter(func(e: Dictionary) -> bool: return e.kind == "cloud" and e.source == 0)
	check(sim.units[0].pos != origin, "Skunk moves while running its trail")
	check(trail_events.size() >= 1, "Trail emits a puff on cadence")
	check(not sim.trace.any(func(e: Dictionary) -> bool: return e.kind == "damage" and e.get("damage_kind", "") == "basic" and e.source == 0), "Trail unit never deals basic attack damage")
	if not trail_events.is_empty():
		check(Vector2(trail_events[0].pos).distance_to(sim.units[0].pos) < 150.0, "Puff positions follow the moving skunk")
		check(sim.units[1].damage_taken_by_kind.get("dot", 0.0) > 0.0, "Trail cloud pulses damage to a nearby enemy")
	var clouds_before_stun: int = sim.clouds.size()
	sim.resolve_hits([{"source": 1, "target": 0, "damage": 1.0, "kind": "basic", "melee": false, "stun": 0.3}])
	var stopped_at: Vector2 = sim.units[0].pos
	advance(sim, 8)
	check(sim.units[0].pos == stopped_at, "Stun stops trail movement")
	check(sim.clouds.size() == clouds_before_stun, "Stun pauses trail puff emission")
	advance(sim, 100)
	check(sim.units[0].pos != stopped_at, "Trail resumes after stun expires")

	var no_opening := Sim.new()
	no_opening.setup(["skunk"], ["trail_dummy"], 1, {"definitions": {"trail_dummy": dummy}, "positions": [Vector2(400, 250), Vector2(500, 250)]})
	advance(no_opening, 120)
	check(no_opening.units[0].skills_used.get("skunk_cloud", 0) == 0, "Initial trail cooldown is respected")

	var dash := Sim.new()
	dash.setup(["skunk_rabbit"], ["trail_dummy"], 1, {"trace": true, "startup_skill_delay": 0.0,
		"definitions": {"trail_dummy": dummy}, "positions": [Vector2(400, 250), Vector2(500, 250)]})
	dash.resolve_hits([{"source": 1, "target": 0, "damage": 1.0, "kind": "basic", "melee": false}])
	advance(dash, 20)
	var dash_clouds: Array = dash.clouds.filter(func(c: Dictionary) -> bool: return c.source == 0 and c.skill == "skunk_rabbit_dash")
	check(dash_clouds.size() >= 2, "Skunk-Rabbit dash emits multiple flight puffs")
	if dash_clouds.size() >= 2:
		check(Vector2(dash_clouds[0].pos).distance_to(dash_clouds[-1].pos) > 1.0, "Dash puffs follow distinct resolved flight positions")
	check(dash_clouds.any(func(c: Dictionary) -> bool: return int(c.end) > dash.tick), "Dash puffs persist after flight ends")

	print("SKUNK TRAIL: %d checks; %d failures" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
