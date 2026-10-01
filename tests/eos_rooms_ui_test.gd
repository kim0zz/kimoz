extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Node = load("res://scenes/match/match.tscn").instantiate()
	root.add_child(screen)
	screen._open_network()
	await process_frame
	await process_frame
	# Exercise controls without contacting Epic or changing any credentials.
	screen.room_input.text = "BAD"
	screen.room_join_button.pressed.emit()
	assert(screen.lobby_status.text.contains("NIEPEŁNY"))
	assert(not screen.online.active)
	var problem: String = screen.online.rooms.configuration_error()
	if not problem.is_empty():
		screen.room_host_button.pressed.emit()
		assert(not screen.online.active)
		assert(screen.lobby_status.text.contains("Epic"))
		assert(not screen.room_host_button.disabled)
	else:
		screen._online_status("POKÓJ ZE ZNAJOMYM\nUtwórz pokój lub wpisz kod. Bez ustawiania routera.")
	screen.room_input.text = ""
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/eos-rooms-ui.png")
	screen._return_local()
	assert(not screen.network_waiting)
	assert(not screen.network_dialog.visible)
	print("PASS: room controls, invalid code, configuration feedback, return to local, rendered layout.")
	quit()
