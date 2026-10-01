extends SceneTree
const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func advance(sim: RefCounted, seconds: float) -> void:
	for i in range(ceili(seconds * 60)):
		if sim.result == "running": sim.step()
func fixture(id: String, count: int = 1) -> RefCounted:
	var dummy: Resource = Catalog.load_units().monkey.duplicate(true)
	dummy.max_hp = 10000
	dummy.move_speed = 0.01
	dummy.attack_interval = 1000
	dummy.skills.clear()
	var targets: Array = []
	var positions: Array = [Vector2(300,250)]
	for i in range(count):
		targets.append("monkey")
		positions.append(Vector2(380,250 + (i * 60 - 30 if count > 1 else 0)))
	var sim := Sim.new()
	check(sim.setup([id], targets, 1, {"trace":true,"startup_skill_delay":0,"definitions":{"monkey":dummy},"positions":positions}),"fixture " + id)
	return sim
func damage_events(sim: RefCounted, skill: String) -> Array:
	return sim.trace.filter(func(e: Dictionary) -> bool: return e.kind == "damage" and e.get("skill", "") == skill)

func _run() -> void:
	check(Catalog.validate().is_empty(),"All data valid")
	check(Catalog.load_units().size() == 20,"8 lvl1 and 12 lvl2")
	check(Catalog.fusion("bear","bear") == "" and Catalog.fusion("monkey","bear") == "bear_monkey", "Fusion pairs exact and unordered")
	var sim := fixture("bear_cheetah",2)
	var s: Resource = sim.units[0].definition.skills[0]
	advance(sim,1.5)
	check(damage_events(sim,s.id).size() == 6,"Three cones hit two targets each")
	sim = fixture("bear_monkey",2)
	s = sim.units[0].definition.skills[0]
	advance(sim,2)
	check(damage_events(sim,s.id+"_banana").size() == 2,"One bonus banana per cone victim")
	sim = fixture("cheetah_eagle")
	s = sim.units[0].definition.skills[0]
	advance(sim,3)
	check(damage_events(sim,s.id).size() == 3,"Three dive impacts on the same victim")
	sim = fixture("monkey_hippo")
	s = sim.units[0].definition.skills[0]
	advance(sim,2)
	check(sim.units[1].stun_uptime > 0,"Heavy banana applies stun")
	sim = fixture("cheetah_rabbit")
	s = sim.units[0].definition.skills[0]
	sim.resolve_hits([{"source":1,"target":0,"damage":1.0,"kind":"basic","melee":false}])
	advance(sim,2)
	check(damage_events(sim,s.id).size() == 3,"Counter dash follows with three hits")
	sim = fixture("hippo_rabbit",2)
	sim.units[2].pos = Vector2(800,250)
	sim.resolve_hits([{"source":1,"target":0,"damage":1.0,"kind":"basic","melee":false}])
	check(sim.units[0].action.target == 2,"Hippo rabbit counter selects farthest")
	advance(sim,2)
	check(sim.units[2].stun_uptime > 0,"Heavy followup stuns after landing")
	sim = fixture("monkey_skunk")
	s = sim.units[0].definition.skills[0]
	sim.skills_disabled = true
	sim._create_cloud(0,sim.units[1].pos,s,s.cloud_damage)
	sim._create_cloud(0,sim.units[1].pos,s,s.cloud_damage)
	advance(sim,s.hit_interval)
	check(sim.units[1].damage_taken_by_kind.get("dot",0) == s.cloud_damage,"Overlapping same-owner clouds do not stack damage")
	check(sim.units[1].slow_multiplier == s.slow_multiplier,"Cloud slow applied once")
	sim.units[1].pos = Vector2(900,250)
	sim.step()
	check(sim.units[1].slow_multiplier == 1.0,"Leaving cloud removes slow")
	sim = fixture("hedgehog_skunk")
	s = sim.units[0].definition.skills[0]
	advance(sim,2)
	check(sim.units[1].stagger_uptime > 0,"Spiked cloud staggers victim")
	sim = fixture("skunk_rabbit")
	sim.resolve_hits([{"source":1,"target":0,"damage":1.0,"kind":"basic","melee":false}])
	check(absf(sim.units[0].action.destination.y-250) > 60,"Skunk rabbit evades laterally")
	advance(sim,0.5)
	check(sim.units[0].hp < sim.units[0].definition.max_hp,"Evasion never erases incoming damage")
	for opponents in [["bear", "hippo"], ["hippo", "skunk"]]:
		var original := Sim.new()
		var mirrored := Sim.new()
		original.setup(["cheetah_eagle"], opponents, 1)
		mirrored.setup(opponents, ["cheetah_eagle"], 1)
		var exact := true
		while original.result == "running" and mirrored.result == "running" and original.time < 120:
			original.step()
			mirrored.step()
			for index in range(3):
				var other: Dictionary = mirrored.units[2 if index == 0 else index-1]
				exact = exact and original.units[index].pos == Vector2(Sim.ARENA_SIZE.x-other.pos.x,other.pos.y) and original.units[index].hp == other.hp
		check(exact and original.result != "running" and mirrored.result != "running", "Triple dive mirrors positions and HP on every tick: " + str(opponents))
	print("HYBRID MECHANICS: %d checks; %d failures" % [checks,failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
