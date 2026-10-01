extends SceneTree
const Sim=preload("res://scripts/combat/combat_simulation.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for id in ["monkey","monkey_hippo","monkey_skunk","lvl3_04"]:
		var sim=Sim.new()
		assert(sim.setup([id],["bear"],1,{"disable_skills":true,"positions":[Vector2(450,250),Vector2(550,250)]}))
		var original: Vector2=sim.units[0].pos
		for i in range(180): sim.step()
		assert(sim.units[0].pos.distance_to(original)<0.1,"Ranged must not kite nearby melee")
		assert(sim.units[0].damage_dealt>0 and sim.units[1].damage_dealt>0,"Both sides must exchange damage")
	var sim=Sim.new()
	assert(sim.setup(["monkey"],["hippo"],1,{"disable_skills":true,"positions":[Vector2(180,250),Vector2(940,250)]}))
	for i in range(360): sim.step()
	assert(sim.units[0].pos.x>180,"Ranged still approaches distant enemies")
	assert(sim.units[0].damage_dealt>0,"Ranged attacks after approaching")
	var rabbit=Sim.new()
	assert(rabbit.setup(["rabbit","bear"],["hippo"],1))
	var u: Dictionary=rabbit.units[0]
	u.target=2
	var before: Vector2=u.pos
	rabbit._start_skill(u,u.definition.skills[0])
	for i in range(20): rabbit.step()
	assert(u.pos.distance_to(before)>40,"Explicit rabbit dash remains active")
	print("NO KITING PASS: four ranged forms, mutual damage, approach, rabbit dash")
	quit()

