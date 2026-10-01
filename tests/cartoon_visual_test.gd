extends SceneTree
const Art = preload("res://scripts/presentation/cartoon_art.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
var game: Node
func _initialize() -> void: call_deferred("run")
func capture(file: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://" + file + ".png")
func click(button: Button) -> void:
	var event := InputEventMouseButton.new()
	event.position = button.get_global_rect().get_center()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame
func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await capture("cartoon_menu")
	var menu_buttons: Array[Node] = game.menu.find_children("*","Button",true,false)
	assert(menu_buttons.size() == 5)
	await click(menu_buttons[0])
	assert(not game.menu.visible and game.local_match.overlay.visible)
	await capture("cartoon_draft")
	var match_screen: Node = game.local_match
	for i in range(4): match_screen._pick_offer(0)
	assert(match_screen.model.phase == "prep")
	match_screen._start_battle()
	assert(match_screen.model.phase == "battle")
	await capture("cartoon_match")
	match_screen.arena.running = false
	match_screen.model.phase = "prep"
	match_screen._enter_lab()
	match_screen.arena.set_balance_variant("T")
	match_screen.arena.set_physics_process(false)
	match_screen.arena.running = true
	for tick in range(330): match_screen.arena._physics_process(1.0/60.0)
	await capture("cartoon_teamfight")
	game.queue_free()
	await process_frame
	var gallery := GridContainer.new()
	gallery.columns = 8
	gallery.size = Vector2(1280,720)
	root.add_child(gallery)
	for id in Catalog.ids()+Catalog.hybrid_ids()+Catalog.lvl3_ids():
		var column := VBoxContainer.new()
		gallery.add_child(column)
		var tex := Art.texture(id)
		assert(tex.get_width()>10 and tex.get_height()>10)
		column.add_child(Art.portrait(id,145))
		var label := Label.new()
		label.text = id
		label.add_theme_font_size_override("font_size",12)
		column.add_child(label)
	await capture("cartoon_roster")
	print("CARTOON PASS: real menu click, draft, battle, Teamfight, 32 atlas regions")
	quit()

