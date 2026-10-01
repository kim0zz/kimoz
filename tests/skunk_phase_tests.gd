extends SceneTree
const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Motion = preload("res://scripts/combat/combat_movement.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for id in ["skunk","hedgehog_skunk","skunk_rabbit"]:
		var sim := Sim.new()
		assert(sim.setup([id,"bear"],["hippo"],1))
		var u: Dictionary = sim.units[0]
		u.pos = Vector2(500,250)
		sim.units[1].pos = Vector2(560,250)
		sim.units[2].pos = Vector2(620,250)
		u.target = 2
		sim._start_skill(u,u.definition.skills[0])
		var desired: Array[Vector2] = [Vector2(680,250),sim.units[1].pos,sim.units[2].pos]
		Motion.apply(sim.units,desired,sim.ARENA_SIZE,sim.DT)
		assert(u.pos.x > 670, "Active trail crosses both teams")
		u.pos = sim.units[2].pos
		var hp: float = u.hp
		sim.resolve_hits([{"source":2,"target":0,"damage":1.0,"kind":"basic","melee":false,"stun":1.0}])
		assert(u.hp < hp and u.action.is_empty(), "Phasing can be hit and stunned")
		sim._sync_trail_phasing()
		assert(not u.phase_active)
		assert(u.pos.distance_to(sim.units[2].pos) >= u.definition.radius+sim.units[2].definition.radius-0.01,"Stun restores separated collision")
		u.target = 2
		sim._start_skill(u,u.definition.skills[0])
		u.pos = sim.units[1].pos
		sim._finish_action(u)
		sim._sync_trail_phasing()
		assert(not u.phase_active)
		assert(u.pos.distance_to(sim.units[1].pos) >= u.definition.radius+sim.units[1].definition.radius-0.01,"Natural end separates allies")
	print("TRAIL PHASING PASS: crossing allies/enemies, damage, stun, release for all3")
	quit()
