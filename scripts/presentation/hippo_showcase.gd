extends CanvasLayer
const Rig = preload("res://scenes/units/hippo_rig.tscn")
const Art = preload("res://scripts/presentation/cartoon_art.gd")
const BACKGROUND = preload("res://assets/cartoon/arena.png")
const HEAVY = preload("res://resources/skills/hippo_heavy.tres")
var audio: Node
var contact: Node2D
var rig: Node2D
var miniature: Node2D
var mode := "Sekwencja"
var time := 0.0
var pause := false
var speed := 1.0
var title: Label
var state_label: Label
var event_sent := false
var owner_menu: CanvasLayer
var unit := {"pos":Vector2.ZERO,"facing":Vector2.RIGHT,"alive":true,"stun_remaining":0.0,"action":{}}

func _ready() -> void:
	layer = 20
	audio = preload("res://scripts/presentation/hippo_audio.gd").new()
	add_child(audio)
	audio.set_playback(true,1.0)
	var background := TextureRect.new()
	background.texture=BACKGROUND
	background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var heading_panel := PanelContainer.new()
	heading_panel.position=Vector2(30,18)
	heading_panel.size=Vector2(1040,90)
	heading_panel.add_theme_stylebox_override("panel",Art.panel(Color("183e46"),Color("e9c887")))
	add_child(heading_panel)
	title=_label("HIPOPOTAM  /  PRÓBA ANIMACJI",Vector2(50,28),34)
	title.add_theme_color_override("font_color",Color("fff1d4"))
	var subtitle := _label("Ruch części ciała • ciężar • przygotowanie • uderzenie • reakcja",Vector2(52,77),18)
	subtitle.add_theme_color_override("font_color",Color("fff1d4"))
	var big := Node2D.new()
	big.position=Vector2(600,470)
	big.scale=Vector2.ONE*3.8
	add_child(big)
	rig=Rig.instantiate()
	big.add_child(rig)
	rig.cue.connect(audio.cue)
	contact = preload("res://scripts/presentation/hippo_contact_fx.gd").new()
	big.add_child(contact)
	var small := Node2D.new()
	small.position=Vector2(1080,490)
	add_child(small)
	miniature=Rig.instantiate()
	small.add_child(miniature)
	_label("Skala walki",Vector2(1023,535),17)
	state_label=_label("",Vector2(70,520),28)
	var row := HBoxContainer.new()
	row.position=Vector2(50,580)
	row.add_theme_constant_override("separation",8)
	add_child(row)
	for option in ["Sekwencja","Spoczynek","Chód","Ciężki cios","Pudło","Oberwanie","Ogłuszenie","Radość","Porażka"]:
		var button := Button.new()
		button.text=option
		button.theme=Art.theme()
		button.custom_minimum_size.y=43
		button.pressed.connect(set_mode.bind(option))
		row.add_child(button)
	var pause_button := Button.new()
	pause_button.text="Pauza / wznów"
	pause_button.theme=Art.theme()
	pause_button.position=Vector2(50,639)
	pause_button.pressed.connect(func() -> void: pause=not pause)
	add_child(pause_button)
	var speed_button := Button.new()
	speed_button.text="Tempo: 1× / 0,35×"
	speed_button.theme=Art.theme()
	speed_button.position=Vector2(230,639)
	speed_button.pressed.connect(func() -> void: speed=0.35 if speed==1.0 else 1.0)
	add_child(speed_button)
	_label("Podgląd ruchu. W meczu animacją sterują rzeczywiste zdarzenia walki.",Vector2(465,653),15)
	var close := Button.new()
	close.text="← Menu"
	close.theme=Art.theme()
	close.position=Vector2(1120,30)
	close.pressed.connect(func() -> void:
		if is_instance_valid(owner_menu): owner_menu.show()
		queue_free())
	add_child(close)

func _label(text: String, at: Vector2, size_px: int) -> Label:
	var label := Label.new()
	label.text=text
	label.position=at
	label.add_theme_font_size_override("font_size",size_px)
	label.add_theme_font_override("font",Art.DISPLAY_FONT)
	label.add_theme_color_override("font_color",Color("21373c"))
	add_child(label)
	return label

func set_mode(value: String) -> void:
	mode=value
	time=0.0
	event_sent=false
	pause=false
	unit.pos=Vector2.ZERO
	audio.reset_feedback()
	contact.hits.clear()

func _process(delta: float) -> void:
	audio.set_playback(not pause,speed)
	if pause: return
	time+=delta*speed
	contact.advance(time)
	var cycle := fmod(time,12.0)
	var current := mode
	var local := fmod(time,3.0)
	if mode=="Sekwencja":
		if cycle<2.0: current="Spoczynek"; local=cycle
		elif cycle<4.0: current="Chód"; local=cycle-2.0
		elif cycle<7.0: current="Ciężki cios"; local=cycle-4.0
		elif cycle<8.0: current="Oberwanie"; local=cycle-7.0
		elif cycle<10.0: current="Ogłuszenie"; local=cycle-8.0
		else: current="Radość"; local=cycle-10.0
	unit.alive=current!="Porażka" or local<0.5
	unit.stun_remaining=1.0 if current=="Ogłuszenie" else 0.0
	unit.action={}
	if current=="Chód": unit.pos.x+=delta*speed*65.0
	if current in ["Ciężki cios","Pudło"] and local<1.75:
		var start := int(round((time-local)*60.0))
		unit.action={"skill":HEAVY,"start":start,"next":start+60,"remaining":1 if local<1.0 else 0,"direction":Vector2.RIGHT}
	if local<0.4: event_sent=false
	if current=="Ciężki cios" and local>=1.0 and not event_sent:
		for target in [rig,miniature]: target.source_event({"kind":"damage","damage_kind":"skill","amount":45},time)
		contact.impact(Vector2(52,-28),Vector2.RIGHT,time)
		event_sent=true
	if current=="Oberwanie" and local>=0.4 and not event_sent:
		for target in [rig,miniature]: target.target_event({"kind":"damage","damage_kind":"basic","amount":12},time)
		event_sent=true
	for target in [rig,miniature]: target.sample(unit,time,current=="Radość")
	state_label.text=current
