extends SceneTree
## Focused playtest regression; intentionally independent of the full balance suite.
const Sim = preload("res://scripts/combat/combat_simulation.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _run() -> void:
	var variants: Array = [[Vector2(280, 250), Vector2(840, 250)], [Vector2(180, 150), Vector2(940, 350)], [Vector2(450, 250), Vector2(670, 250)], [Vector2(300, 80), Vector2(820, 420)], [Vector2(650, 250), Vector2(1090, 250)]]
	for positions: Array in variants:
		var original := _fight(["eagle"], ["monkey"], positions)
		var mirrored: Array = [Vector2(1120 - positions[1].x, positions[1].y), Vector2(1120 - positions[0].x, positions[0].y)]
		var mirror := _fight(["monkey"], ["eagle"], mirrored)
		check(original.result == "A", "Eagle wins isolated dive: " + str(positions))
		check(mirror.result == "B" and mirror.tick == original.tick, "Exact mirrored outcome")
		print("DUEL eagle HP=%.1f time=%.3f" % [original.units[0].hp, original.time])
	var contact := Sim.new()
	contact.setup(["eagle"], ["monkey"], 1, {"disable_skills": true, "positions": [Vector2(400,250), Vector2(450,250)]})
	var start: Vector2 = contact.units[1].pos
	for i in range(75): contact.step()
	check(contact.units[1].pos == start, "Caught monkey stays and fights away from wall")
	check(contact.units[0].damage_taken > 0 and contact.units[1].damage_taken > 0, "Both units exchange basics in contact")
	contact.units[0].pos = Vector2(370,250) # 32 px edge gap: retain contact state.
	contact.step()
	check(contact.units[1].pos == start, "Small separation does not restart retreat")
	contact.units[0].pos = Vector2(340,250) # 62 px edge gap: release.
	contact.step()
	check(contact.units[1].pos == start, "Separation does not restore removed distance keeping")
	contact.units[0].alive = false
	contact._update_ranged_contact(contact.units[1])
	check(contact.units[1].close_target == -1, "Dead threat releases engagement")
	var airborne := Sim.new()
	airborne.setup(["eagle"], ["monkey"], 1, {"positions": [Vector2(400,250), Vector2(450,250)]})
	airborne.units[0].action = {"skill": airborne.units[0].definition.skills[0], "remaining": 1}
	airborne._update_ranged_contact(airborne.units[1])
	check(airborne.units[1].close_target == -1, "Airborne diver does not pin monkey")
	# A guarded ranged unit can still beat the assassin; no species hard counter.
	var guarded := _fight(["eagle"], ["bear", "monkey"], [])
	check(guarded.result == "B", "Guarded monkey can survive diver")
	print("RANGED CONTACT: %d checks; %d failures" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)

func _fight(a: Array, b: Array, positions: Array) -> RefCounted:
	var sim := Sim.new()
	var options: Dictionary = {} if positions.is_empty() else {"positions": positions}
	check(sim.setup(a, b, 1, options), "Setup")
	while sim.result == "running" and sim.time < 60: sim.step()
	check(sim.result != "running", "Fight finishes")
	return sim
