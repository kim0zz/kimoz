extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/development_"+name+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	var screen: Node=load("res://scenes/match/match.tscn").instantiate()
	root.add_child(screen)
	screen.model.phase="draft"
	screen.model.offers=screen.Catalog.ids()
	for player in range(2):
		for i in range(9): screen.model.teams[player].append({"id":screen.Catalog.ids()[i%8],"active":i<6,"token":player*20+i+1})
	screen._refresh()
	await capture("full")
	var view: Control=screen.buttons.get_child(0)
	assert(view.get_global_rect().end.y<=720)
	assert(view.card_list.size()==26)
	view.card_list[0].mouse_entered.emit()
	await create_timer(0.3).timeout
	assert(not view.inspector.visible,"Hover must never open the development window")
	view._show_details("bear",0,view.card_list[0])
	await create_timer(0.3).timeout
	await capture("tree")
	assert(view.inspector.get_global_rect().end.y<=720)
	assert(view.lines.size()==18)
	view._close_details()
	var token: int=screen.model.teams[screen.model.turn_player][0].token
	screen._select_unit(screen.model.turn_player,token)
	assert(screen.selected_tokens[screen.model.turn_player].has(token))
	await process_frame
	view=screen.buttons.get_child(0)
	view._show_details("lvl3_01",0,view.card_list[0])
	await create_timer(0.3).timeout
	await capture("lvl3")
	view._close_details()
	var controller_event := InputEventJoypadButton.new()
	controller_event.button_index=JOY_BUTTON_Y
	controller_event.pressed=true
	view.card_list[0].gui_input.emit(controller_event)
	assert(view.pinned and view.inspector.visible)
	controller_event.button_index=JOY_BUTTON_B
	view._input(controller_event)
	assert(not view.inspector.visible and not view.pinned)
	assert(view.card_list[0].has_focus())
	# Actual button callbacks preserve the existing fusion and purchase rules.
	screen.selected_tokens=[[],[]]
	var player: int=screen.model.turn_player
	screen._select_unit(player,screen.model.teams[player][0].token)
	screen._select_unit(player,screen.model.teams[player][1].token)
	view=screen.buttons.get_child(0)
	var fused := false
	for button in view.find_children("*","Button",true,false):
		if button.text.begins_with("Połącz"):
			assert(not button.disabled)
			button.pressed.emit()
			fused=true
			break
	assert(fused and screen.model.teams[player].size()==8)
	screen.model.begin_match(1)
	screen._refresh()
	view=screen.buttons.get_child(0)
	player=screen.model.turn_player
	view.card_list[0].pressed.emit()
	assert(screen.model.teams[player].size()==1)
	for i in range(3): screen._pick_offer(0)
	assert(screen.model.phase=="prep")
	await capture("prep")
	root.size=Vector2i(1920,1080)
	await capture("1080")
	print("PASS: full roster fits, full depth tree, separate selection, lvl3 detail")
	quit()
