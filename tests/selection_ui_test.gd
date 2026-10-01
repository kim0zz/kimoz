extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var screen: Node = load("res://scenes/match/match.tscn").instantiate()
	root.add_child(screen)
	screen.model.phase = "draft"
	screen.model.turn_player = 0
	for i in range(9):
		screen.model.teams[0].append({"id": "bear" if i == 2 else "cheetah", "token": i + 1, "active": i < 6})
	screen._refresh()
	for i in range(5): await process_frame
	screen.content_scroll.scroll_vertical = 240
	screen.team_scrolls[0].scroll_vertical = 95
	var page_y: int = screen.content_scroll.scroll_vertical
	var team_y: int = screen.team_scrolls[0].scroll_vertical
	screen._select_unit(0, 3)
	for i in range(5): await process_frame
	assert(screen.content_scroll.scroll_vertical == page_y, "Outer scroll retained")
	assert(screen.team_scrolls[0].scroll_vertical == team_y, "Roster scroll retained")
	var selected_count := 0
	for button in screen.buttons.find_children("*", "Button", true, false):
		if button.get_meta("selected_unit", false):
			selected_count += 1
			assert(button.text.contains("WYBRANA"))
	assert(selected_count == 1)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://selection_online_ui.png")
	screen._open_network()
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://online_lobby_ui.png")
	print("SELECTION UI PASS: chosen marker, outer and roster scroll preserved")
	screen.queue_free()
	await process_frame
	quit()
