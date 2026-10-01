extends SceneTree
const Sim = preload("res://scripts/combat/combat_simulation.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var sim = Sim.new()
	assert(sim.setup(["rabbit", "bear"], ["hippo", "monkey"], 1, {"trace":true}))
	var rabbit: Dictionary = sim.units[0]
	var ally: Dictionary = sim.units[1]
	var skill: Resource = rabbit.definition.skills[0]
	rabbit.target = 2
	sim.units[2].target = 0
	ally.hp = 60.0
	assert(sim._shield_ally(rabbit).uid == 1)
	sim._start_skill(rabbit, skill)
	assert(sim.units[2].target == 1, "Jump breaks aggro")
	for i in range(17): sim.step()
	assert(ally.shield_hp == 30.0 and rabbit.shield_granted == 30.0)
	var hp: float = ally.hp
	sim._apply_damage_batch([sim._hit(sim.units[2],1,20,"basic",false)])
	assert(ally.hp == hp and ally.shield_hp == 10.0 and rabbit.shield_absorbed == 20.0)
	sim._rabbit_shield(rabbit, ally, skill)
	sim._rabbit_shield(rabbit, ally, skill)
	assert(ally.shield_hp == 30.0 and rabbit.shield_granted == 50.0, "Refresh does not stack")
	sim._apply_damage_batch([sim._hit(sim.units[2],1,45,"skill",false)])
	assert(ally.hp == hp-15 and ally.shield_hp == 0.0)
	sim._rabbit_shield(rabbit, ally, skill)
	ally.rabbit_shield_end = sim.tick + 1
	sim.step()
	assert(ally.shield_hp == 0.0, "Shield expires")
	var solo = Sim.new()
	assert(solo.setup(["rabbit"],["hippo"],1,{"trace":true}))
	for i in range(480): solo.step()
	assert(solo.units[0].skills_used.get("rabbit_dash",0)>=2, "Skill repeats automatically")
	assert(solo.units[0].damage_dealt>0 and solo.units[0].shield_absorbed>0)
	var dying = Sim.new()
	dying.setup(["rabbit","bear"],["hippo"])
	dying.units[0].target=2
	dying._start_skill(dying.units[0],dying.units[0].definition.skills[0])
	dying.units[1].alive=false
	for i in range(17): dying.step()
	assert(dying.units[0].shield_hp == 30.0, "Last ally dies: shield self")
	var cases: Array = [[ ["rabbit","bear"],["monkey","hippo"] ],[["rabbit","rabbit"],["cheetah","bear"]],[["rabbit"],["rabbit"]]]
	for matchup: Array in cases:
		var battle = Sim.new()
		battle.setup(matchup[0],matchup[1])
		for i in range(5400):
			if battle.result != "running": break
			battle.step()
		assert(battle.result != "running", "No shield stalemate")
		print("RABBIT CASE: ", matchup, " time=",battle.time," result=",battle.result," shield=",battle.units[0].shield_absorbed)
	var interrupted = Sim.new()
	interrupted.setup(["rabbit","bear"],["hippo"])
	interrupted.units[0].target=2
	interrupted._start_skill(interrupted.units[0],interrupted.units[0].definition.skills[0])
	interrupted._apply_stun(interrupted.units[0],1.0)
	for i in range(20): interrupted.step()
	assert(interrupted.units[1].shield_hp == 0.0, "Stun cancels shield delivery")
	var wire = preload("res://scripts/network/combat_wire.gd")
	var snapshot: Dictionary = wire.capture(solo)
	var replica = Sim.new()
	wire.apply(replica,snapshot,solo.definitions)
	assert(replica.units[0].shield_hp == solo.units[0].shield_hp, "Online shield state")
	print("RABBIT SUPPORT PASS")
	quit()
