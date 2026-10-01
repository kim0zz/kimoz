extends SceneTree
## The A/B control must preserve rosters, reset the battle, and leave combat authoritative.
const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Variants = preload("res://scripts/data/combat_variants.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
var failures: Array[String] = []

func _initialize() -> void:
	create_timer(45.0).timeout.connect(func() -> void: push_error("Burst presentation watchdog"); quit(1))
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value: failures.append(label)

func run() -> void:
	var scene: Node = load("res://scenes/combat/combat_prototype.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	var ids: Array[String] = Catalog.ids() + Catalog.hybrid_ids()
	for offset in [0,10]:
		var teams: Array = [[],[]]
		for i in range(12): teams[i/6].append(ids[(offset+i)%ids.size()])
		verify_teams(scene,teams)
	scene.queue_free()
	await process_frame
	var match_screen: Node = load("res://scenes/match/match.tscn").instantiate()
	root.add_child(match_screen)
	match_screen.arena.set_physics_process(false)
	match_screen.arena.set_balance_variant("A")
	for i in range(4): check(match_screen.model.pick(0),"Initial pick")
	match_screen._start_battle()
	check(match_screen.arena.balance_variant == "B","Full match always uses B after Lab A")
	for failure in failures: push_error(failure)
	print("BURST_PRESENTATION_TESTS failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

func verify_teams(scene: Node, teams: Array) -> void:
	for team in range(2):
		for slot in range(6):
			scene.selectors[team][slot].select(scene.ids.find(teams[team][slot])+1)
	for variant in ["A","B"]:
		scene.set_balance_variant(variant)
		check(scene._roster(0) == teams[0] and scene._roster(1) == teams[1],"A/B preserves rosters")
		check(scene.sim.tick == 0 and not scene.running,"A/B resets and pauses")
		var reference := Sim.new()
		check(reference.setup(teams[0],teams[1],1,{"definitions":Variants.definitions(variant)}),"Reference setup")
		while reference.result == "running" and reference.time < 90.0: reference.step()
		check(reference.result != "running","Reference finishes")
		for speed in [1.0,4.0]:
			scene._reset()
			scene.result_recorded = true
			scene.speed = speed
			scene.running = true
			while scene.sim.result == "running" and scene.sim.time < 90.0: scene._physics_process(1.0/60.0)
			check(JSON.stringify(scene.sim.summary()) == JSON.stringify(reference.summary()),"Presentation parity %s %.0fx" % [variant,speed])
		scene._reset()
		check(scene.effects_view.effects.is_empty(),"Reset clears impacts")
		check(scene.sim.tick == 0,"Reset clears cooldown time")
