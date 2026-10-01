extends SceneTree
## Executable contract tests. Fixtures exercise outcomes, not copies of the combat logic.
const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Motion = preload("res://scripts/combat/combat_movement.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_data_and_reset()
	_test_neutral()
	_test_resolver()
	_test_movement()
	_test_skills()
	_test_startup_lock()
	_test_ranged_no_skills()
	_test_projectiles_and_targeting()
	_test_repeatability_and_smoke()
	_test_invariants()
	_test_mirror_regressions()
	_test_lattice_symmetry()
	print("COMBAT TESTS: %d assertions; %d failures" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)

func _near(actual: float, expected: float, message: String, tolerance: float = 0.0001) -> void:
	_check(absf(actual - expected) <= tolerance, "%s (actual=%f expected=%f)" % [message, actual, expected])

func _fixture(hp: float = 100.0) -> Resource:
	var definition: Resource = load("res://resources/units/bear.tres").duplicate(true)
	definition.id = "neutral"
	definition.max_hp = hp
	definition.attack_damage = 10.0
	definition.attack_interval = 1.0
	definition.attack_range = 8.0
	definition.radius = 24.0
	definition.skills.clear()
	return definition

func _duel(a: String, b: String, options: Dictionary = {}) -> RefCounted:
	var sim := Sim.new()
	_check(sim.setup([a], [b], 1, options), "Valid duel setup: " + a + "/" + b)
	return sim

func _advance(sim: RefCounted, seconds: float) -> void:
	for _tick in range(ceili(seconds * 60.0)):
		if sim.result != "running": break
		sim.step()

func _finish(sim: RefCounted) -> void:
	while sim.result == "running" and sim.time < 120.0: sim.step()

func _hit(source: int, target: int, damage: float, melee: bool = true, kind: String = "basic") -> Dictionary:
	return {"source": source, "target": target, "damage": damage, "melee": melee, "kind": kind}

func _uses(unit: Dictionary) -> int:
	var count := 0
	for value in unit.skills_used.values(): count += int(value)
	return count

func _test_data_and_reset() -> void:
	_check(Catalog.validate().is_empty(), "All eight resources validate")
	_check(Catalog.ids().size() == 8 and Catalog.load_units().size() == 20, "Eight lvl1 plus twelve lvl2 definitions")
	var invalid := Sim.new()
	_check(not invalid.setup([], ["bear"]), "Empty roster rejected")
	_check(not invalid.setup(["missing"], ["bear"]), "Unknown id rejected")
	_check(not invalid.setup(["bear","bear","bear","bear","bear","bear","bear"], ["bear"]), "Oversize roster rejected")
	var sim := Sim.new()
	sim.setup(["bear", "bear"], ["hippo"])
	var hp: float = sim.units[0].definition.max_hp
	sim.resolve_hits([_hit(2, 0, 20)])
	_near(sim.units[1].hp, hp, "Damage does not mutate another instance")
	_near(sim.units[0].definition.max_hp, hp, "Damage does not mutate Resource")
	sim.setup(["bear", "bear"], ["hippo"])
	_near(sim.units[0].hp, hp, "Reset restores HP")
	_check(sim.tick == 0 and sim.projectiles.is_empty() and sim.units[0].skills_used.is_empty(), "Reset clears runtime state")

func _test_neutral() -> void:
	var fixture := _fixture()
	var sim := _duel("neutral", "neutral", {"definitions": {"neutral": fixture}, "positions": [Vector2(500,250), Vector2(550,250)], "trace": true})
	_advance(sim, 59.0/60.0)
	_near(sim.units[0].hp, 100.0, "No first basic before full attack interval")
	sim.step()
	_near(sim.units[0].hp, 90.0, "First basic after exactly one second")
	_finish(sim)
	_check(sim.result == "draw", "Symmetric neutral simultaneous lethal hits draw")
	_near(sim.time, 10.0, "Neutral 100HP/10 damage per second dies at 10s", Sim.DT)
	_near(sim.summary().units[0].ttk, 9.0, "TTK starts at first received hit, not match start", Sim.DT)
	var frozen := JSON.stringify(sim.summary())
	sim.step()
	_check(JSON.stringify(sim.summary()) == frozen, "Terminal match state frozen")

func _test_resolver() -> void:
	var sim := _duel("bear", "hippo")
	sim.units[0].hp = 10.0
	sim.units[1].hp = 10.0
	sim.resolve_hits([_hit(0,1,10), _hit(1,0,10)])
	_check(sim.result == "draw", "Ordinary simultaneous attacks do not cancel dead source")
	sim = _duel("bear", "hedgehog")
	sim.units[0].hp = 2.0
	sim.units[1].hp = 1.0
	sim.resolve_hits([_hit(0,1,100)])
	_check(sim.result == "B" and sim.units[1].hp == 1.0, "Lethal thorns cancel incoming lethal melee")
	_near(sim.units[0].cancelled_damage, 100.0, "Cancelled damage telemetry")
	sim = _duel("hedgehog", "hedgehog")
	sim.units[0].hp = 2.0
	sim.units[1].hp = 2.0
	sim.resolve_hits([_hit(0,1,7), _hit(1,0,7)])
	_check(sim.result == "draw", "Two lethal thorns resolve simultaneously")
	_near(sim.units[0].damage_taken + sim.units[1].damage_taken, 4.0, "Thorns cannot recurse")
	sim = _duel("bear", "hedgehog")
	sim.resolve_hits([_hit(0,1,10,false), _hit(0,1,2,true,"thorns")])
	_near(sim.units[0].damage_taken, 0.0, "Projectile and thorns damage do not activate thorns")
	sim = _duel("cheetah", "hedgehog")
	sim.resolve_hits([_hit(0,1,1), _hit(0,1,1), _hit(0,1,1)])
	_near(sim.units[0].damage_taken, 3.0 * sim.units[1].definition.skills[0].damage, "Each multi-hit independently triggers thorns")
	var other := _duel("hippo", "hedgehog")
	other.resolve_hits([_hit(0,1,3)])
	_near(other.units[0].damage_taken, other.units[1].definition.skills[0].damage, "Same total damage in one hit triggers only one thorn")
	var team := Sim.new()
	team.setup(["bear", "bear"], ["hippo"])
	team.units[2].hp = 10.0
	team.resolve_hits([_hit(0,2,20), _hit(1,2,20)])
	_near(team.units[0].damage_dealt + team.units[1].damage_dealt, 10.0, "Applied damage excludes overkill")
	_near(team.units[0].damage_dealt, team.units[1].damage_dealt, "Simultaneous overkill attribution symmetric")
	_near(team.units[2].focus_damage, 10.0, "Focus-fire telemetry recognizes two attackers")

func _test_movement() -> void:
	var landing := Sim.new()
	landing.setup(["eagle"],["eagle"],1,{"positions":[Vector2(560,250),Vector2(560,250)]})
	Motion.correct_landings(landing.units,[0,1],Sim.ARENA_SIZE)
	_check(landing.units[0].pos.distance_to(landing.units[1].pos)>=47.99,"Simultaneous overlapping dives separate")
	_near((landing.units[0].pos.x+landing.units[1].pos.x)/2.0,560.0,"Simultaneous landing correction preserves shared midpoint",0.001)
	landing.setup(["eagle"],["bear"],1,{"positions":[Vector2(30,100),Vector2(30,100)]})
	var stationary: Vector2 = landing.units[1].pos
	Motion.correct_landings(landing.units,[0],Sim.ARENA_SIZE)
	_check(landing.units[1].pos==stationary,"Landing correction does not move ordinary defender")
	_check(landing.units[0].pos.distance_to(landing.units[1].pos)>=landing.units[0].definition.radius+landing.units[1].definition.radius-0.01,"Landing at wall resolves overlap with stationary defender")
	landing.setup(["eagle","bear"],["hippo"],1,{"positions":[Vector2(400,250),Vector2(400,250),Vector2(1000,250)]})
	stationary=landing.units[1].pos
	Motion.correct_landings(landing.units,[0],Sim.ARENA_SIZE)
	_check(landing.units[1].pos==stationary,"Landing correction leaves stationary ally in place")
	_check(landing.units[0].pos.distance_to(landing.units[1].pos)>=landing.units[0].definition.radius+landing.units[1].definition.radius-0.01,"Dive landing cannot overlap an ally")
	var chain_definition := _fixture()
	chain_definition.radius = 25.0
	var chain := Sim.new()
	chain.setup(["neutral", "neutral"], ["neutral"],1,{"definitions":{"neutral":chain_definition},"positions":[Vector2(100,250),Vector2(200,250),Vector2(150,250)]})
	var chain_desired: Array[Vector2] = [Vector2(110,250),Vector2(200,250),Vector2(160,250)]
	Motion.apply(chain.units,chain_desired,Sim.ARENA_SIZE,Sim.DT)
	_check(chain.units[0].pos.distance_to(chain.units[2].pos)>=49.99 and chain.units[1].pos.distance_to(chain.units[2].pos)>=49.99,"Chained contact: stopping middle enemy also stops following unit")
	var sim := _duel("bear", "bear", {"disable_skills": true, "positions": [Vector2(350,250), Vector2(700,250)]})
	var desired: Array[Vector2] = [Vector2(900,250), Vector2(150,250)]
	Motion.apply(sim.units, desired, Sim.ARENA_SIZE, Sim.DT)
	_check(sim.units[0].pos.x < sim.units[1].pos.x, "Fast opposing movement does not tunnel")
	_check(sim.units[0].pos.distance_to(sim.units[1].pos) >= sim.units[0].definition.radius + sim.units[1].definition.radius - 0.01, "Opponents do not overlap")
	var allies := Sim.new()
	allies.setup(["bear", "bear"], ["bear"], 1, {"positions": [Vector2(300,250),Vector2(400,250),Vector2(1000,250)]})
	var ally_desired: Array[Vector2] = [Vector2(400,250),Vector2(300,250),Vector2(1000,250)]
	Motion.apply(allies.units, ally_desired, Sim.ARENA_SIZE, Sim.DT)
	_check(allies.units[0].pos.x < allies.units[1].pos.x, "Fast allies cannot pass through each other")
	_check(allies.units[0].pos.distance_to(allies.units[1].pos) >= allies.units[0].definition.radius + allies.units[1].definition.radius - 0.01, "Allied collision prevents overlap")
	desired = [Vector2(-1000,-1000), Vector2(2000,2000)]
	Motion.apply(sim.units, desired, Sim.ARENA_SIZE, Sim.DT)
	for unit in sim.units:
		_check(unit.pos.x >= unit.definition.radius and unit.pos.y >= unit.definition.radius and unit.pos.x <= 1120-unit.definition.radius and unit.pos.y <= 500-unit.definition.radius, "Arena contains unit circle")

func _test_skills() -> void:
	var sim := _duel("eagle", "hippo", {"startup_skill_delay": 0.0, "trace": true})
	sim.step()
	_check(_uses(sim.units[0]) == 1 and sim.units[0].state == "dive", "Eagle starts dive on first tick")
	_finish(sim)
	_check(_uses(sim.units[0]) >= 2, "Eagle repeats dive during a long duel")
	sim = _duel("rabbit", "bear", {"startup_skill_delay": 0.0, "positions": [Vector2(500,250),Vector2(555,250)]})
	_check(_uses(sim.units[0]) == 0, "Rabbit does not dash before hit")
	sim.resolve_hits([_hit(1,0,10)])
	_near(sim.units[0].hp, 65.0, "Dash does not undo damage")
	_check(sim.units[0].state == "dash" and _uses(sim.units[0]) == 1, "Surviving hit near melee triggers dash")
	sim.resolve_hits([_hit(1,0,10)])
	_near(sim.units[0].hp, 55.0, "Dash grants no invulnerability")
	_check(_uses(sim.units[0]) == 1, "Dash cannot re-trigger during cooldown")
	sim = _duel("rabbit", "monkey", {"startup_skill_delay": 0.0, "positions": [Vector2(400,250),Vector2(800,250)]})
	sim.resolve_hits([_hit(1,0,10,false)])
	_check(_uses(sim.units[0]) == 1, "Rabbit counters a ranged attacker too")
	sim = _duel("rabbit", "bear", {"startup_skill_delay": 0.0, "positions": [Vector2(500,250),Vector2(555,250)]})
	sim.resolve_hits([_hit(1,0,100)])
	_check(_uses(sim.units[0]) == 0, "Dead rabbit cannot dash")
	sim = _duel("hippo", "bear", {"startup_skill_delay": 0.0, "positions": [Vector2(500,250),Vector2(562,250)], "trace": true})
	sim.step()
	var started: int = sim.tick
	_advance(sim, 0.9)
	_near(sim.units[0].damage_dealt, 0.0, "Hippo cannot hit before wind-up")
	_advance(sim, 0.2)
	_check(sim.units[0].damage_dealt >= 30.0, "Hippo heavy lands after wind-up")
	_advance(sim, 6.0)
	var starts: Array = []
	for event in sim.trace:
		if event.kind == "skill_start" and event.source == 0: starts.append(event.tick)
	_check(starts.size() >= 2, "Repeated heavy hit has second activation")
	if starts.size() >= 2: _check(starts[1] - started >= 360, "Heavy cooldown counted from cast start")
	sim = _duel("cheetah", "bear", {"startup_skill_delay": 0.0, "positions": [Vector2(500,250),Vector2(553,250)], "trace": true})
	sim.step()
	sim.resolve_hits([_hit(1,0,1000)])
	_advance(sim, 1.0)
	_near(sim.units[0].damage_dealt, 0.0, "Death cancels unlanded multi-hit sequence")
	var status: Resource = load("res://resources/statuses/weakened.tres") # Generic legacy status contract, no longer Skunk's skill.
	sim = _duel("bear", "hippo", {"disable_skills": true, "positions": [Vector2(100,250),Vector2(1020,250)]})
	sim.apply_status(0,1,status)
	_near(sim.units[0].status_multiplier, 0.75, "Debuff multiplier")
	_advance(sim, 1.0)
	sim.apply_status(0,1,status)
	_near(sim.units[0].status_multiplier, 0.75, "Repeated debuff does not stack")
	_near(sim.units[0].status_remaining, 3.0, "Repeated debuff refreshes duration")
	_advance(sim, 3.0)
	_near(sim.units[0].status_multiplier, 1.0, "Debuff expires")
	var neutral := _fixture(1000)
	sim = _duel("neutral","neutral", {"definitions":{"neutral":neutral}, "positions":[Vector2(500,250),Vector2(550,250)]})
	sim.apply_status(0,1,status)
	_advance(sim,1.0)
	_near(sim.units[0].damage_dealt,7.5,"Debuff affects actual outgoing basic damage")

func _test_projectiles_and_targeting() -> void:
	var sim := Sim.new()
	sim.setup(["eagle"],["monkey","cheetah"],1,{"startup_skill_delay":0.0,"positions":[Vector2(200,250),Vector2(900,250),Vector2(850,250)]})
	sim.step()
	sim.units[1].alive = false
	sim.units[1].hp = 0.0
	sim.units[0].action.destination = Vector2(850,250)
	sim.units[0].action.travel_end = sim.tick + 1
	sim.units[0].action.end = sim.tick + 19
	sim.step()
	_check(sim.units[0].pos.distance_to(sim.units[2].pos) >= sim.units[0].definition.radius+sim.units[2].definition.radius-0.01,"Dive target dies midflight: landing remains legal against moving survivor")
	_check(_uses(sim.units[0]) == 1,"Lost dive target does not grant second dive")
	sim.setup(["eagle"], ["bear", "monkey"],1,{"startup_skill_delay":0.0,"positions":[Vector2(200,250),Vector2(600,250),Vector2(900,250)]})
	sim.step()
	_check(sim.units[0].target == 2, "Dive prefers backline over nearby front")
	_advance(sim, 1.5)
	_check(sim.units[0].pos.x > sim.units[1].pos.x, "Dive crosses blocking front")
	for foe in [sim.units[1],sim.units[2]]:
		_check(sim.units[0].pos.distance_to(foe.pos) >= sim.units[0].definition.radius+foe.definition.radius-0.1, "Dive lands without enemy overlap")
	sim = Sim.new()
	sim.setup(["bear", "bear"], ["hippo", "skunk"], 1, {"disable_skills": true, "positions": [Vector2(500,220),Vector2(500,280),Vector2(562,250),Vector2(900,250)]})
	sim.step()
	_check(sim.units[0].target == 2 and sim.units[1].target == 2, "Focus fire allows multiple attackers on one target")
	sim.resolve_hits([_hit(0,2,1000)])
	sim.step()
	_check(sim.units[0].target == 3 and sim.units[1].target == 3, "Retarget after target death")
	sim = Sim.new()
	sim.setup(["monkey", "bear"],["bear", "hippo"],1,{"disable_skills":true})
	sim.projectiles.append({"uid":0,"source":0,"target":2,"pos":sim.units[2].pos,"damage":10.0,"kind":"basic","speed":420.0,"skill":""})
	sim.resolve_hits([_hit(2,0,1000)])
	sim.step()
	_near(sim.units[2].damage_taken, 10.0, "Existing projectile survives shooter death while match continues")
	sim.projectiles.append({"uid":1,"source":0,"target":2,"pos":sim.units[2].pos,"damage":10.0,"kind":"basic","speed":420.0,"skill":""})
	sim.resolve_hits([_hit(1,2,1000)])
	sim.step()
	_check(sim.projectiles.is_empty(), "Projectile loses dead target without retargeting")
	_near(sim.units[3].damage_taken,0.0,"Lost projectile does not damage other enemy")
	sim = _duel("monkey","bear",{"disable_skills":true,"positions":[Vector2(500,250),Vector2(570,250)]})
	var before: float = sim.units[0].pos.x
	sim.step()
	_near(sim.units[0].pos.x, before,"Ranged stands and attacks instead of retreating")

func _test_startup_lock() -> void:
	var dummy := _fixture(10000.0)
	dummy.attack_interval = 1000.0
	dummy.move_speed = 0.1
	for id in ["bear","cheetah","monkey","hippo","skunk"]:
		var definition: Resource = load("res://resources/units/%s.tres" % id)
		var edge: float = 165.0 if id == "monkey" else 6.0
		var sim := _duel(id,"neutral",{"definitions":{"neutral":dummy},"positions":[Vector2(500,250),Vector2(500+definition.radius+dummy.radius+edge,250)],"trace":true})
		var deadline := Sim.ticks(definition.skills[0].initial_cooldown)
		_advance(sim,float(deadline-1)/60.0)
		_check(_uses(sim.units[0])==0,"Individual startup lock prevents early special: "+id)
		_check(sim.units[0].damage_dealt>0.0,"Startup skill lock does not delay basic attacks: "+id)
		sim.step()
		_check(_uses(sim.units[0])==1,"In-range active starts at its individual deadline: "+id)
	var eagle := Sim.new()
	eagle.setup(["eagle"],["bear","monkey"],1,{"trace":true})
	var origin: Vector2 = eagle.units[0].pos
	_advance(eagle,float(eagle.units[0].cooldowns.eagle_dive-1)/60.0)
	_check(_uses(eagle.units[0])==0 and not eagle.units[0].dive_used,"Eagle cannot dive before its opening deadline")
	_check(eagle.units[0].pos.distance_to(origin)>10.0,"Eagle walks during startup lock")
	_check(eagle.units[0].target==1,"Locked eagle targets nearby front normally")
	eagle.step()
	_check(eagle.units[0].state=="dive" and _uses(eagle.units[0])==1,"Eagle begins dive at its opening deadline")
	_check(eagle.units[0].target==2,"Unlocked eagle reselects backline for dive")
	var rabbit := _duel("rabbit","neutral",{"definitions":{"neutral":dummy},"positions":[Vector2(500,250),Vector2(552,250)]})
	rabbit.resolve_hits([_hit(1,0,10)])
	_check(_uses(rabbit.units[0])==0,"Rabbit cannot dash on hit during startup lock")
	_advance(rabbit,float(rabbit.units[0].cooldowns.rabbit_dash-1)/60.0)
	rabbit.resolve_hits([_hit(1,0,1)])
	_check(_uses(rabbit.units[0])==0,"Rabbit remains dash-locked until its deadline")
	rabbit.step()
	_check(_uses(rabbit.units[0])==0,"Unlock alone does not trigger dash without fresh hit")
	rabbit.resolve_hits([_hit(1,0,1)])
	_check(rabbit.units[0].state=="dash" and _uses(rabbit.units[0])==1,"Fresh qualifying hit at opening deadline triggers dash")
	var thorns := _duel("bear","hedgehog")
	thorns.resolve_hits([_hit(0,1,1)])
	_near(thorns.units[0].damage_taken,thorns.units[1].definition.skills[0].damage,"Passive thorns remain active at time0 despite startup lock")
	var dash_block := Sim.new()
	dash_block.setup(["rabbit","bear"],["neutral"],1,{"startup_skill_delay":0.0,"definitions":{"neutral":dummy},"positions":[Vector2(500,250),Vector2(420,250),Vector2(555,250)]})
	dash_block.resolve_hits([_hit(2,0,1)])
	_advance(dash_block,0.25)
	_check(dash_block.units[0].pos.x>dash_block.units[1].pos.x,"Rabbit dash does not cross ally blocking retreat")
	_check(dash_block.units[0].pos.distance_to(dash_block.units[1].pos)>=dash_block.units[0].definition.radius+dash_block.units[1].definition.radius-0.01,"Rabbit dash stops without allied overlap")

func _test_ranged_no_skills() -> void:
	# With no allies nearby, a wall must pin ranged into shooting rather than orbiting.
	for id in Catalog.ids():
		var sim := _duel("monkey",id,{"disable_skills":true,"positions":[Vector2(280,250),Vector2(840,250)]})
		_finish(sim)
		_check(sim.result in ["A","B","draw"],"No-skills ranged duel finishes without perpetual wall circling: "+id)

func _test_repeatability_and_smoke() -> void:
	var a: Array = ["bear","monkey","rabbit"]
	var b: Array = ["hippo","eagle","skunk"]
	var sim := Sim.new()
	var copy := Sim.new()
	sim.setup(a,b,7,{"trace":true})
	copy.setup(a,b,7,{"trace":true})
	_finish(sim)
	_finish(copy)
	_check(JSON.stringify(sim.trace) == JSON.stringify(copy.trace), "Same inputs produce identical full event trace")
	var mirror := Sim.new()
	mirror.setup(b,a,7)
	_finish(mirror)
	_check((sim.result == "A" and mirror.result == "B") or (sim.result == "B" and mirror.result == "A") or (sim.result == "draw" and mirror.result == "draw"), "Team swap preserves mirrored winner")
	_near(sim.time, mirror.time, "Team swap preserves duration",Sim.DT)
	var ids: Array[String] = Catalog.ids()
	for i in range(ids.size()):
		sim = _duel(ids[i],ids[(i+1)%ids.size()])
		_finish(sim)
		_check(sim.result in ["A","B","draw"], "All-eight skill smoke completes: " + ids[i])
		var dealt := 0.0
		var taken := 0.0
		for unit in sim.units:
			dealt += unit.damage_dealt
			taken += unit.damage_taken
			_check(is_finite(unit.hp) and unit.hp >= 0 and is_finite(unit.pos.x) and is_finite(unit.pos.y), "Finite legal runtime state: "+unit.id)
		_near(dealt,taken,"Conservation of applied damage: "+ids[i])

func _test_invariants() -> void:
	var sim := Sim.new()
	sim.setup(["bear","cheetah","monkey","eagle","hedgehog","rabbit"],["hippo","skunk","eagle","monkey","cheetah","rabbit"],3,{"trace":true})
	var valid_bounds := true
	var valid_collisions := true
	var collision_detail := ""
	while sim.result == "running" and sim.time < 120.0:
		sim.step()
		for unit in sim.units:
			if not unit.alive: continue
			var radius: float = unit.definition.radius
			if unit.pos.x < radius-0.001 or unit.pos.x > 1120-radius+0.001 or unit.pos.y < radius-0.001 or unit.pos.y > 500-radius+0.001: valid_bounds = false
			for other in sim.units:
				if not other.alive or unit.uid == other.uid or unit.get("motion_dive",false) or other.get("motion_dive",false): continue
				if unit.pos.distance_to(other.pos) < radius + other.definition.radius - 0.1:
					valid_collisions = false
					collision_detail = "%s/%s at %.3f" % [unit.id,other.id,sim.time]
	_check(valid_bounds,"6v6 all-tick arena containment")
	_check(valid_collisions,"6v6 all-tick allied and enemy non-overlap outside dive: "+collision_detail)
	var last_starts: Dictionary = {}
	var valid_cooldowns := true
	var valid_busy := true
	var active: Dictionary = {}
	for event in sim.trace:
		if event.kind == "skill_start":
			var key := str(event.source)+":"+str(event.skill)
			var skill: Resource = sim.units[event.source].definition.skills[0]
			if last_starts.has(key) and event.tick-last_starts[key] < Sim.ticks(skill.cooldown): valid_cooldowns = false
			last_starts[key] = event.tick
			active[event.source] = event.skill
		elif event.kind == "skill_end": active.erase(event.source)
		elif event.kind == "death": active.erase(event.target)
		elif event.kind == "damage" and event.damage_kind == "basic" and active.has(event.source) and sim.units[event.source].definition.role != "ranged": valid_busy = false
	_check(valid_cooldowns,"All repeated skills obey their data cooldowns")
	_check(valid_busy,"Melee basics never occur during active special action")

func _test_mirror_regressions() -> void:
	var ids: Array[String] = Catalog.ids()
	var rosters: Array = []
	for excluded_a in range(8):
		for excluded_b in range(excluded_a+1,8):
			var roster: Array = []
			for index in range(8):
				if index != excluded_a and index != excluded_b: roster.append(ids[index])
			rosters.append(roster)
	for pair in [[21,23],[16,16],[3,16],[0,23],[4,16],[7,18],[12,14]]:
		var one := Sim.new()
		var two := Sim.new()
		one.setup(rosters[pair[0]],rosters[pair[1]],1)
		two.setup(rosters[pair[1]],rosters[pair[0]],1)
		_finish(one)
		_finish(two)
		var expected: String = "B" if one.result == "A" else ("A" if one.result == "B" else one.result)
		_check(two.result == expected,"Mirror regression winner: "+str(pair))
		_near(one.time,two.time,"Mirror regression duration: "+str(pair),Sim.DT)
		var health_equal := true
		for i in range(12):
			if absf(one.units[i].hp-two.units[(i+6)%12].hp)>0.001: health_equal=false
		_check(health_equal,"Mirror regression remaining HP: "+str(pair))

func _reflect(pos: Vector2) -> Vector2:
	return Vector2(Sim.ARENA_SIZE.x-pos.x,pos.y)

func _test_lattice_symmetry() -> void:
	# Translation reflection is a geometric invariant, independent of game balance.
	for row in range(11):
		for column in range(11):
			var pos := Vector2(40+column*100,30+row*44)
			var target := Vector2(1000-column*43,470-row*33)
			var delta := (target-pos).normalized()*1.437
			var mirrored_delta := Vector2(-delta.x,delta.y)
			var pairs: Array = [
				[Motion.translated(pos,delta,Sim.ARENA_SIZE),Motion.translated(_reflect(pos),mirrored_delta,Sim.ARENA_SIZE)],
				[Motion.toward(pos,target,2.173,Sim.ARENA_SIZE),Motion.toward(_reflect(pos),_reflect(target),2.173,Sim.ARENA_SIZE)],
				[Motion.interpolated(pos,target,0.371,Sim.ARENA_SIZE),Motion.interpolated(_reflect(pos),_reflect(target),0.371,Sim.ARENA_SIZE)],
				[Motion.clamp_position(pos,23.7,Sim.ARENA_SIZE),Motion.clamp_position(_reflect(pos),23.7,Sim.ARENA_SIZE)]]
			var valid := true
			for pair in pairs:
				var actual: Vector2 = pair[0]
				valid = valid and actual == _reflect(pair[1])
				valid = valid and actual.x/Motion.GRID == roundf(actual.x/Motion.GRID) and actual.y/Motion.GRID == roundf(actual.y/Motion.GRID)
			_check(valid,"Binary lattice exact reflection: sample %d/%d" % [row,column])




