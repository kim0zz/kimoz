extends SceneTree
const Catalog = preload("res://scripts/data/catalog.gd")
var arena: Node
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Node = load("res://scenes/match/match.tscn").instantiate()
	root.add_child(screen)
	arena = screen.arena
	screen._enter_lab()
	arena.set_physics_process(false)
	arena.set_balance_variant("T")
	assert(arena.balance_variant == "T" and arena.sim.units.size() == 6)
	for unit in arena.sim.units:
		assert(unit.definition.skills.size() == 2)
		assert(not str(unit.get("teamfight_role", "")).is_empty())
	var healed := false
	var shielded := false
	# A staged injury makes support feedback reproducible without changing live data.
	for unit in arena.sim.units:
		if unit.id == "cheetah" and unit.team == 0: unit.hp = unit.definition.max_hp * 0.35
	arena.running = true
	for tick in range(1200):
		arena._physics_process(1.0 / 60.0)
		var fresh_support := false
		for event in arena.sim.events:
			if event.kind == "heal":
				healed = true
				fresh_support = true
			if event.kind == "shield":
				shielded = true
				fresh_support = true
		if fresh_support and tick > 120:
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://teamfight_lab.png")
			break
	assert(healed or shielded, "Support events visible in integrated Lab")
	var watched: Dictionary = arena.sim.units[1]
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(80,160) + Vector2(watched.pos)
	root.push_input(motion, true)
	await process_frame
	await process_frame
	if arena._inspection_unit().get("uid", -1) != watched.uid:
		printerr("Hover mismatch: ", arena.pointer_position, " expected ", motion.position)
		quit(1)
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://teamfight_hover.png")
	arena._show_teamfight_report()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://teamfight_report.png")
	assert(arena.teamfight_report_text.text.contains("leczenie"))
	arena.teamfight_report.hide()
	# Main match can still configure every catalog unit after leaving T.
	screen._exit_lab()
	screen.model.teams = [[{"id":"lvl3_03","active":true,"token":1}],[{"id":"bear","active":true,"token":2}]]
	screen.model.phase = "prep"
	screen._start_battle()
	assert(arena.balance_variant == "B")
	assert(arena.sim.units[0].id == "lvl3_03" and arena.sim.units[1].id == "bear")
	assert(not arena.sim.units[0].has("teamfight_role"))
	assert(Catalog.load_units()["monkey"].skills[0].id != "tf_monkey_heal", "Catalog not mutated")
	print("TEAMFIGHT UI PASS: T preset, support feedback, report, return to B/full match")
	screen.queue_free()
	await process_frame
	quit()
