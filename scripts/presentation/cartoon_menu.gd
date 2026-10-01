extends Node2D
const Art = preload("res://scripts/presentation/cartoon_art.gd")
const BACKGROUND = preload("res://assets/cartoon/arena.png")
var menu: CanvasLayer
var artwork: Array[TextureRect] = []
var menu_hippo: Node2D
var elapsed := 0.0
var local_match: Node

func _ready() -> void:
	local_match = $LocalMatch
	local_match.overlay.hide()
	menu = CanvasLayer.new()
	menu.layer = 10
	add_child(menu)
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.03,0.13,0.15,0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(shade)
	var title := Label.new()
	title.text = "KIMOZ"
	title.add_theme_font_override("font",Art.DISPLAY_FONT)
	title.position = Vector2(86,48)
	title.add_theme_font_size_override("font_size", 108)
	title.add_theme_color_override("font_color",Color("ffc366"))
	title.add_theme_color_override("font_outline_color",Color("173338"))
	title.add_theme_constant_override("outline_size",20)
	menu.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Małe zwierzaki. Wielka zadyma."
	subtitle.position = Vector2(98,180)
	subtitle.add_theme_font_size_override("font_size",24)
	subtitle.add_theme_color_override("font_outline_color",Color("173338"))
	subtitle.add_theme_constant_override("outline_size",8)
	menu.add_child(subtitle)
	var animals := ["hippo", "eagle", "monkey", "eagle_hippo"]
	var positions := [Vector2(58,285),Vector2(335,235),Vector2(255,425),Vector2(500,390)]
	var sizes := [300.0,235.0,240.0,245.0]
	for i in range(animals.size()):
		var animal := Art.portrait(animals[i],sizes[i])
		animal.position = positions[i]
		animal.size = Vector2.ONE * sizes[i]
		animal.set_meta("rest",positions[i])
		menu.add_child(animal)
		artwork.append(animal)
		if animals[i] == "hippo":
			animal.hide()
			var anchor := Node2D.new()
			anchor.position = Vector2(210,570)
			anchor.scale = Vector2.ONE*2.7
			menu.add_child(anchor)
			menu_hippo = preload("res://scenes/units/hippo_rig.tscn").instantiate()
			anchor.add_child(menu_hippo)
	var panel := PanelContainer.new()
	panel.position = Vector2(820,225)
	panel.size = Vector2(370,370)
	panel.add_theme_stylebox_override("panel",Art.panel(Color("183e46"),Color("e9c887")))
	menu.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	panel.add_child(column)
	var caption := Label.new()
	caption.text = "ZBIERZ SWOJĄ EKIPĘ"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",20)
	column.add_child(caption)
	_button(column,"GRAJ LOKALNIE",func() -> void: _open("local"),true)
	_button(column,"ZE ZNAJOMYM",func() -> void: _open("online"))
	_button(column,"COMBAT LAB",func() -> void: _open("lab"))
	_button(column,"WYJDŹ",func() -> void: get_tree().quit())
	var animation_button := Button.new()
	animation_button.text = "HIPOPOTAM • ANIMACJE"
	animation_button.theme = Art.theme()
	animation_button.position = Vector2(855,620)
	animation_button.custom_minimum_size = Vector2(300,40)
	animation_button.pressed.connect(func() -> void:
		menu.hide()
		var showcase := CanvasLayer.new()
		showcase.set_script(preload("res://scripts/presentation/hippo_showcase.gd"))
		showcase.owner_menu = menu
		add_child(showcase))
	menu.add_child(animation_button)
	var foot := Label.new()
	foot.text = "Łącz zwierzaki • odkrywaj hybrydy • kibicuj swojej drużynie"
	foot.position = Vector2(92,673)
	foot.add_theme_font_size_override("font_size",17)
	foot.add_theme_color_override("font_outline_color",Color("173338"))
	foot.add_theme_constant_override("outline_size",6)
	menu.add_child(foot)
	var back := Button.new()
	back.text = "Menu"
	back.pressed.connect(_show_menu)
	local_match.root_column.get_child(0).add_child(back)

func _button(parent: Node, label: String, action: Callable, primary: bool = false) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(320,61)
	button.theme = Art.theme()
	button.add_theme_font_size_override("font_size",22)
	if primary:
		button.add_theme_stylebox_override("normal",Art.panel(Color("ef963e"),Color("f5d390")))
		button.add_theme_color_override("font_color",Color("243338"))
	button.pressed.connect(action)
	parent.add_child(button)

func _open(mode: String) -> void:
	menu.hide()
	local_match.overlay.show()
	if mode == "online": local_match._open_network()
	elif mode == "lab": local_match._enter_lab()

func _show_menu() -> void:
	# An online match cannot be paused by opening a local screen.
	if local_match._is_online():
		local_match._open_network()
		return
	if local_match.lab_mode: local_match._exit_lab()
	if local_match.arena.running: local_match.arena._toggle()
	local_match.overlay.hide()
	menu.show()

func _process(delta: float) -> void:
	if menu == null or not menu.visible: return
	elapsed += delta
	if is_instance_valid(menu_hippo): menu_hippo.sample({"pos":Vector2.ZERO,"facing":Vector2.RIGHT,"alive":true,"action":{}},elapsed)
	for i in range(artwork.size()):
		artwork[i].position = Vector2(artwork[i].get_meta("rest")) + Vector2(0,sin(elapsed*2.0+i)*5.0)
