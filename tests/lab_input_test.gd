extends SceneTree
func _initialize() -> void: call_deferred("run")
func click_at(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await process_frame
func run() -> void:
	root.size = Vector2i(1280,720)
	var screen: Node = load("res://scenes/match/match.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await click_at(screen.lab_button.get_global_rect().get_center())
	if not screen.lab_mode:
		printerr("FAIL: real click did not enter Lab")
		quit(1)
		return
	await click_at(screen.arena.variant_picker.get_global_rect().get_center())
	var opened: bool = screen.arena.variant_picker.get_popup().visible
	print("LAB DROPDOWN CLICK: ", opened)
	screen.arena.variant_picker.get_popup().hide()
	await click_at(screen.arena.teamfight_button.get_global_rect().get_center())
	var selected: bool = screen.arena.balance_variant == "T"
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://lab_entry_fixed.png")
	await click_at(screen.arena.start_button.get_global_rect().get_center())
	var started: bool = screen.arena.running
	await click_at(screen.arena.variant_picker.get_global_rect().get_center())
	var opened_running: bool = screen.arena.variant_picker.get_popup().visible
	screen.arena.variant_picker.get_popup().hide()
	await click_at(screen.lab_exit_button.get_global_rect().get_center())
	var returned: bool = not screen.lab_mode and screen.match_panel.visible
	print("LAB REAL INPUT: dropdown=",opened," T button=",selected," Start=",started," dropdown during combat=",opened_running," return=",returned)
	opened = opened and selected and started and opened_running and returned
	screen.queue_free()
	await process_frame
	quit(0 if opened else 1)
