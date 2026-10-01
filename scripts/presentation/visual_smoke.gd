extends SceneTree
## Real controller clock vs direct simulation. No desktop input or alternate combat rules.
const Simulation = preload("res://scripts/combat/combat_simulation.gd")
var failures: Array[String] = []
var started_ms: int = 0
var finished := false

func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	call_deferred("run")

func _process(_delta: float) -> bool:
	# Also exits nonzero if a script error aborts run() before normal completion.
	if not finished and Time.get_ticks_msec() - started_ms > 30000:
		printerr("PRESENTATION_SMOKE_FAIL: watchdog / incomplete test")
		quit(1)
	return false

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("PRESENTATION_SMOKE_FAIL: ", message)

func run() -> void:
	var scene: Node = load("res://scenes/combat/combat_prototype.tscn").instantiate()
	root.add_child(scene)
	# Explicit calls below are the only controller clock; disable engine dispatch.
	scene.set_physics_process(false)
	check(scene.sim.units.size() == 12, "Default preset must contain 6v6")
	check(not scene.running, "Default paused state")
	scene._single_step()
	check(scene.sim.tick == 1, "Single step must advance exactly once")
	scene._toggle()
	check(scene.running, "Start enables controller clock")
	scene._toggle()
	check(not scene.running, "Pause disables controller clock")
	scene._reset()
	check(scene.sim.tick == 0, "Reset clears tick")
	for team in scene.selectors:
		for selector in team: selector.select(0)
	scene._reset()
	check(scene.sim.units.is_empty(), "Empty rosters must not start")
	var empty_validation: String = scene.status.text
	scene._single_step()
	check(scene.sim.tick == 0, "Step cannot advance an invalid empty roster")
	check(scene.status.text == empty_validation, "Step preserves empty roster validation message")
	check(scene.sim.result == "running", "Step cannot turn invalid roster into draw")
	scene._select_preset(0)
	check(scene.sim.units.size() == 12, "Preset restores 6v6")
	var reference := Simulation.new()
	check(reference.setup(scene._roster(0),scene._roster(1),1), "Reference setup")
	var steps := 0
	while reference.result == "running" and steps < 7200:
		reference.step()
		steps += 1
	check(reference.result != "running", "Reference must finish within test watchdog")
	var expected := JSON.stringify(reference.summary())
	for speed: float in [0.5,1.0,4.0]:
		scene._reset()
		scene.speed = speed
		scene._toggle()
		var frames := 0
		var pause_tested := false
		var checkpoint_tested := false
		# Deliberately nonuniform wall-clock frames exercise accumulator carry.
		var deltas := [1.0/120.0,1.0/60.0,1.0/37.0,1.0/90.0]
		while scene.sim.result == "running" and frames < 20000:
			scene._physics_process(deltas[frames % deltas.size()])
			frames += 1
			if not pause_tested and scene.sim.tick >= 100:
				pause_tested = true
				scene._toggle()
				var paused_summary := JSON.stringify(scene.sim.summary())
				var paused_accumulator: float = scene.accumulator
				for _frame in range(10): scene._physics_process(0.75)
				check(JSON.stringify(scene.sim.summary()) == paused_summary, "Pause freezes all summary fields at speed %s" % speed)
				check(scene.accumulator == paused_accumulator, "Pause freezes accumulator at speed %s" % speed)
				scene._toggle()
			if not checkpoint_tested and scene.sim.tick >= 240:
				checkpoint_tested = true
				var checkpoint := Simulation.new()
				check(checkpoint.setup(scene._roster(0),scene._roster(1),1), "Checkpoint setup")
				while checkpoint.tick < scene.sim.tick: checkpoint.step()
				check(JSON.stringify(checkpoint.summary()) == JSON.stringify(scene.sim.summary()), "Every summary field matches at tick %s / speed %s" % [scene.sim.tick,speed])
		check(pause_tested and checkpoint_tested, "Pause/checkpoint exercised at speed %s" % speed)
		check(scene.sim.result != "running", "Controller finishes at speed %s" % speed)
		check(not scene.running, "Controller automatically stops after result at speed %s" % speed)
		check(JSON.stringify(scene.sim.summary()) == expected, "Final full summary parity at speed %s" % speed)
		scene._physics_process(2.0)
		check(JSON.stringify(scene.sim.summary()) == expected, "Finished result is frozen at speed %s" % speed)
		print("PRESENTATION_PARITY speed=",speed," frames=",frames," tick=",scene.sim.tick," result=",scene.sim.result)
	scene._reset()
	check(scene.sim.projectiles.is_empty(), "Reset clears projectiles")
	check(scene.sim.time == 0.0 and scene.accumulator == 0.0, "Reset clears clocks")
	finished = true
	if failures.is_empty():
		print("PRESENTATION_SMOKE_PASS: UI wiring; controller/headless complete summary parity at 0.5x, 1x, 4x; pause and terminal invariance")
		quit(0)
	else:
		printerr("PRESENTATION_SMOKE_FAILURES: ", failures.size())
		quit(1)

