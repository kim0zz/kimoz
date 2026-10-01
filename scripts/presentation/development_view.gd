extends Control
const Art = preload("res://scripts/presentation/cartoon_art.gd")
const Info = preload("res://scripts/presentation/unit_info.gd")
var host: Node
var inspector: Panel
var details: Label
var graph: Control
var lines: Array[PackedVector2Array] = []
var pinned := false
var pending := 0
var current_id := ""
var origin: Control
var card_list: Array[Button] = []
var inspected_player := 0
var panel_tween: Tween
var modal_shade: ColorRect

func _ready() -> void:
	custom_minimum_size.y=492
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	theme=Art.theme()
	_build()

func label_at(parent: Node, text: String, rect: Rect2, font_size: int=15) -> Label:
	var l := Label.new()
	l.text=text
	l.position=rect.position
	l.size=rect.size
	l.add_theme_font_size_override("font_size",font_size)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _build() -> void:
	var draft: bool=host.model.phase in ["initial_draft","draft"]
	var player: int=host.model.turn_player if draft else host._management_player()
	label_at(self,"WSPÓLNA PULA  •  A / Enter: wybierz   •   i / Y / prawy klik: szczegóły",Rect2(0,0,1200,24))
	for i in range(8):
		var rect := Rect2((i%4)*306,28+int(i/4)*88,298,82)
		if i<host.model.offers.size():
			var id: String=host.model.offers[i]
			var legal: bool=draft and host._can_control(player) and host.model.owned_count(player)<9
			_card(self,id,player,rect,"pool_%d"%i,func() -> void:
				if legal: host._pick_offer(i),66,"" if legal else "podgląd")
		else:
			_slot(self,rect,"Pula wykorzystana" if i==0 else "—")
	for team in range(2):
		var panel := Panel.new()
		panel.position=Vector2(team*614,210)
		panel.size=Vector2(606,204)
		panel.add_theme_stylebox_override("panel",host._panel_style(team,team==player))
		add_child(panel)
		label_at(panel,"GRACZ %d • %d ♥   %s"%[team+1,host.model.lives[team],"TWÓJ WYBÓR" if team==player else ""],Rect2(10,6,585,24),17)
		var active_index := 0
		var reserve_index := 0
		for unit: Dictionary in host.model.teams[team]:
			var active: bool=unit.active
			var index: int=active_index if active else reserve_index
			var rect := Rect2(10+index*98,36,92,94) if active else Rect2(85+index*166,148,158,46)
			var token: int=unit.token
			var selected: bool=host.selected_tokens[team].has(token)
			var partner: bool=host._is_compatible_with_selection(team,token)
			var card := _card(panel,unit.id,team,rect,"unit_%d"%token,func() -> void: host._select_unit(team,token),48 if active else 30,"✓ WYBRANA" if selected else "+ PARTNER" if partner else "")
			card.set_meta("unit_token",token)
			card.set_meta("selected_unit",selected)
			if selected:
				var style: StyleBoxFlat=host._card_style(Color("ffe18b"))
				style.bg_color=Color("65542c")
				card.add_theme_stylebox_override("normal",style)
			elif partner: card.add_theme_stylebox_override("normal",host._card_style(Color("68c8a0")))
			if active: active_index+=1
			else: reserve_index+=1
		for i in range(active_index,6): _slot(panel,Rect2(10+i*98,36,92,94),str(i+1))
		label_at(panel,"REZERWA",Rect2(10,156,75,20),12)
		for i in range(reserve_index,3): _slot(panel,Rect2(85+i*166,148,158,46),"—")
	var controls := HBoxContainer.new()
	controls.position=Vector2(0,426)
	controls.add_theme_constant_override("separation",8)
	add_child(controls)
	if draft:
		var fusion: String=host._selected_pair_result(player)
		_action(controls,"Połącz → "+host._unit_name(fusion) if fusion!="" else "Połącz wybrane",host.model.phase=="draft" and fusion!="",host._fuse_selected)
		_action(controls,"Odrzuć",host.model.phase=="draft" and host.selected_tokens[player].size()==1,host._discard_selected)
		_action(controls,"Wyczyść wybór",true,func() -> void: host.selected_tokens[player].clear(); host._refresh())
		_action(controls,"Pasuj",host.model.phase=="draft" and not host.model.can_act(player),host._pass)
	else:
		_action(controls,"Aktywna / rezerwa",host.selected_tokens[player].size()==1,host._toggle_selected)
		_action(controls,"Zamień miejsca",host.selected_tokens[player].size()==2,host._swap_selected)
		_action(controls,"←",host.selected_tokens[player].size()==1,host._move_selected.bind(-1))
		_action(controls,"→",host.selected_tokens[player].size()==1,host._move_selected.bind(1))
		_action(controls,"Odrzuć",host.selected_tokens[player].size()==1,host._discard_selected)
		_action(controls,"Edytuj "+host._player_name(1-player),true,host._switch_management_player)
		_action(controls,"ROZPOCZNIJ WALKĘ",host.model.active_count(0)>0 and host.model.active_count(1)>0,host._start_battle)
	label_at(self,"Złota karta = wybrana  •  Zielona ramka = partner do fuzji  •  B / Esc = zamknij szczegóły",Rect2(0,468,1200,20),13)
	_build_inspector()
	var key: String=host.get_meta("development_focus","")
	for card in card_list:
		if card.get_meta("focus_key")==key: _restore_card_focus.call_deferred(card); break

func _slot(parent: Node, rect: Rect2, text: String) -> void:
	var panel := Panel.new()
	panel.position=rect.position
	panel.size=rect.size
	panel.add_theme_stylebox_override("panel",Art.panel(Color("193438"),Color("365b5e")))
	parent.add_child(panel)
	label_at(panel,text,Rect2(8,8,rect.size.x-16,24),13)

func _card(parent: Node,id: String,player: int,rect: Rect2,key: String,action: Callable,portrait_size: int,tag: String) -> Button:
	var b := Button.new()
	b.position=rect.position
	b.size=rect.size
	b.set_meta("focus_key",key)
	b.set_meta("inspect_card",true)
	b.add_theme_stylebox_override("focus",host._card_style(Color.WHITE))
	parent.add_child(b)
	var portrait := Art.portrait(id,portrait_size)
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	portrait.position=Vector2(5,4)
	b.add_child(portrait)
	var compact := rect.size.x<100
	var name_rect := Rect2(4,56,rect.size.x-8,20) if compact else Rect2(portrait_size+12,5,rect.size.x-portrait_size-16,34)
	var l := label_at(b,host._unit_name(id),name_rect,11 if compact else 14)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.clip_text=true
	l.size=name_rect.size
	label_at(b,tag if tag!="" else "LVL %d"%host.definitions[id].level,Rect2(4 if compact else portrait_size+12,77 if compact else rect.size.y-22,rect.size.x-8,18),10 if compact else 12)
	b.pressed.connect(func() -> void:
		host.set_meta("development_focus",key)
		action.call())
	var info := Button.new()
	info.text="i"
	info.position=Vector2(rect.size.x-25,3)
	info.size=Vector2(22,22)
	info.add_theme_font_size_override("font_size",12)
	info.add_theme_stylebox_override("normal",host._card_style(Color("5f8f91")))
	info.set_meta("inspect_card",true)
	info.tooltip_text="Skille i drzewko rozwoju • Y / prawy klik"
	info.pressed.connect(func() -> void: _show_details(id,player,b))
	b.add_child(info)
	b.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed) or (event is InputEventJoypadButton and event.button_index==JOY_BUTTON_Y and event.pressed):
			_show_details(id,player,b); pinned=true; inspector.grab_focus(); accept_event())
	card_list.append(b)
	return b

func _action(parent: Node,text: String,enabled: bool,callback: Callable) -> void:
	var b: Button=host._make_button(text,enabled)
	b.pressed.connect(callback)
	parent.add_child(b)

func _build_inspector() -> void:
	modal_shade=ColorRect.new()
	modal_shade.color=Color(0.01,0.05,0.06,0.65)
	modal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_shade.z_index=119
	host.overlay.add_child(modal_shade)
	modal_shade.hide()
	inspector=Panel.new()
	inspector.theme=Art.theme()
	inspector.position=Vector2(72,90)
	inspector.size=Vector2(1136,528)
	inspector.z_index=120
	inspector.focus_mode=Control.FOCUS_ALL
	inspector.add_theme_stylebox_override("panel",Art.panel(Color("122f35"),Color("efc276")))
	host.overlay.add_child(inspector)
	inspector.hide()
	details=label_at(inspector,"",Rect2(18,52,290,448),14)
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	graph=Control.new()
	graph.position=Vector2(320,58)
	graph.size=Vector2(800,440)
	graph.draw.connect(func() -> void:
		for points in lines:
			graph.draw_polyline(points,Color("91aca4"),2.0,true)
			var tip: Vector2=points[-1]
			var direction: Vector2=(tip-points[-2]).normalized()
			graph.draw_line(tip,tip-direction.rotated(0.5)*7,Color("91aca4"),2,true)
			graph.draw_line(tip,tip-direction.rotated(-0.5)*7,Color("91aca4"),2,true))
	inspector.add_child(graph)
	var close := Button.new()
	close.text="Zamknij • B / Esc"
	close.position=Vector2(930,8)
	close.pressed.connect(_close_details)
	inspector.add_child(close)
	label_at(inspector,"ROZWÓJ  •  postać + partner → wynik",Rect2(18,14,780,30),20)

func _show_details(id: String,player: int,card: Control) -> void:
	pinned=true
	origin=card
	inspected_player=player
	current_id=id
	for child in graph.get_children(): graph.remove_child(child); child.queue_free()
	lines.clear()
	_set_description(id)
	var branches: Array=host._partners(id)
	_node(id,Vector2(0,180),Vector2(128,78))
	for i in range(branches.size()):
		var branch: Dictionary=branches[i]
		var y: float=i*144.0
		var available: bool=host._owns(player,id) and host._owns(player,branch.partner)
		_node(branch.partner,Vector2(154,y),Vector2(120,60))
		_node(branch.hybrid,Vector2(304,y+20),Vector2(138,76),available)
		label_at(graph,"+",Rect2(130,y+24,20,20),20)
		lines.append(PackedVector2Array([Vector2(128,219),Vector2(142,219),Vector2(142,y+70),Vector2(304,y+70)]))
		lines.append(PackedVector2Array([Vector2(274,y+30),Vector2(304,y+58)]))
		var next: Array=host._partners(branch.hybrid)
		for j in range(next.size()):
			var recipe: Dictionary=next[j]
			var yy: float=y+j*68
			_node(recipe.partner,Vector2(484,yy),Vector2(122,60))
			_node(recipe.hybrid,Vector2(650,yy),Vector2(138,60),host._owns(player,branch.hybrid) and host._owns(player,recipe.partner))
			label_at(graph,"+",Rect2(455,yy+18,24,22),18)
			lines.append(PackedVector2Array([Vector2(442,y+58),Vector2(452,y+58),Vector2(452,yy+63),Vector2(650,yy+63),Vector2(650,yy+30)]))
			lines.append(PackedVector2Array([Vector2(606,yy+30),Vector2(650,yy+30)]))
	if branches.is_empty(): label_at(graph,"FORMA KOŃCOWA • LVL 3",Rect2(160,200,600,30),22)
	label_at(graph,"Złota ramka: masz oboje rodziców • fuzja zużywa 1 akcję, od rundy 2",Rect2(0,433,800,22),12)
	graph.queue_redraw()
	modal_shade.show()
	inspector.show()
	inspector.grab_focus()
	inspector.modulate.a=0.0
	if panel_tween: panel_tween.kill()
	inspector.position=Vector2(80,90)
	panel_tween=create_tween().set_parallel(true)
	panel_tween.tween_property(inspector,"modulate:a",1.0,0.12)
	panel_tween.tween_property(inspector,"position",Vector2(72,90),0.14)
	_wire_inspector.call_deferred()

func _node(id: String,at: Vector2,dimensions: Vector2,available: bool=false) -> void:
	var b := Button.new()
	b.position=at
	b.size=dimensions
	b.text=""
	if available: b.add_theme_stylebox_override("normal",host._card_style(Color("ffe18b")))
	graph.add_child(b)
	var art := Art.portrait(id,36)
	art.position=Vector2(4,2)
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	b.add_child(art)
	var name_label := label_at(b,host._unit_name(id),Rect2(42,3,dimensions.x-44,dimensions.y-4),12)
	name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_text=true
	name_label.text=host._unit_name(id).replace("-","-\n")
	name_label.size=Vector2(dimensions.x-44,dimensions.y-4)
	b.mouse_entered.connect(_set_description.bind(id))
	b.focus_entered.connect(_set_description.bind(id))
	b.pressed.connect(func() -> void: pinned=true; _set_description(id))
	b.modulate.a=0.0
	var tween := create_tween()
	tween.tween_interval(minf(graph.get_child_count()*0.008,0.12))
	tween.tween_property(b,"modulate:a",1.0,0.10)

func _set_description(id: String) -> void:
	var d: Resource=host.definitions[id]
	var text := "%s • LVL %d\n%s\n\n%s\n\nHP %s • atak %s\n"%[d.display_name,d.level,Info.role_text(d),Info.summary(d),d.max_hp,d.attack_damage]
	for skill: Resource in d.skills:
		if skill.behavior == "shield_jump":
			text += "\nSkok z osłoną • CD %s s\nTarcza %s • czas %s s\n" % [skill.cooldown, skill.shield_amount, skill.shield_duration]
			continue
		text+="\n%s • CD %s s\nDMG %s × %s • stun %s s\n"%[preload("res://scripts/presentation/skill_feedback_style.gd").label(skill.behavior),skill.cooldown,skill.damage,skill.hits,skill.stun_duration]
	text+="\nZasięg: %s • odstęp ataków: %s s\n" % [d.attack_range,d.attack_interval]
	text+="\nGracz %d • akcje: %d\n%s"%[inspected_player+1,host.model.actions_left[inspected_player],"Fuzje dostępne w fazie draftu." if host.model.phase=="draft" else "Teraz tylko podgląd rozwoju."]
	details.text=text

func _close_details() -> void:
	pinned=false
	pending+=1
	inspector.hide()
	modal_shade.hide()
	if is_instance_valid(origin) and origin.is_inside_tree(): origin.grab_focus()
	pending+=1

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventJoypadButton and event.pressed and get_viewport().gui_get_focus_owner()==null and not card_list.is_empty(): card_list[0].grab_focus()
	if inspector.visible and (event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.button_index==JOY_BUTTON_B and event.pressed)):
		_close_details()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if is_instance_valid(inspector): inspector.queue_free()
	if is_instance_valid(modal_shade): modal_shade.queue_free()

func _wire_inspector() -> void:
	var nodes: Array[Control]=[]
	for child in graph.get_children():
		if child is Button: nodes.append(child)
	for child in inspector.get_children():
		if child is Button: nodes.append(child)
	if not nodes.is_empty(): nodes[0].grab_focus()
	for i in range(nodes.size()):
		var node: Control=nodes[i]
		node.focus_next=node.get_path_to(nodes[(i+1)%nodes.size()])
		node.focus_previous=node.get_path_to(nodes[(i-1+nodes.size())%nodes.size()])
		for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
			var best: Control=node
			var distance := INF
			var direction := Vector2.LEFT if side==SIDE_LEFT else Vector2.RIGHT if side==SIDE_RIGHT else Vector2.UP if side==SIDE_TOP else Vector2.DOWN
			for other in nodes:
				var delta: Vector2=other.global_position-node.global_position
				if delta.dot(direction)<=1: continue
				var score: float=delta.length()+absf(delta.cross(direction))*2.0
				if score<distance: best=other; distance=score
			node.set_focus_neighbor(side,node.get_path_to(best))

func _restore_card_focus(card: Control) -> void:
	if is_instance_valid(card) and card.is_inside_tree(): card.grab_focus()
