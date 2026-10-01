extends Node2D
const TeamfightSimulation = preload("res://scripts/combat/teamfight_simulation.gd")
const TeamfightDefinitions = preload("res://scripts/data/teamfight_definitions.gd")
const Simulation = preload("res://scripts/combat/combat_simulation.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Readiness = preload("res://scripts/presentation/skill_readiness.gd")
const Variants = preload("res://scripts/data/combat_variants.gd")
const CombatWire = preload("res://scripts/network/combat_wire.gd")
const UnitView = preload("res://scenes/units/unit_view.tscn")
const Art = preload("res://scripts/presentation/cartoon_art.gd")
const ARENA_ART = preload("res://assets/cartoon/arena.png")
const ORIGIN = Vector2(80,160)
const ARENA = Vector2(1120,500)
const INK = Color("263044")
var sim: RefCounted
var running := false
var remote_mode := false
var network_capture := false
var speed := 1.0
var accumulator := 0.0
var definitions: Dictionary
var ids: Array
var presets: Array
var selectors: Array = []
var views: Dictionary = {}
var unit_root: Node2D
var effects_view: Node2D
var inspector_view: Node2D
var pointer_position := Vector2(-1000,-1000)
var hud: CanvasLayer
var status: Label
var totals: Label
var start_button: Button
var preset_picker: OptionButton
var variant_picker: OptionButton
var teamfight_button: Button
var balance_variant := "B"
var art_hint: Label
var role_hint: Label
var role_hint_second: Label
var teamfight_report: AcceptDialog
var teamfight_report_text: RichTextLabel
var report_button: Button
var effect_texts: Array = []
var remote_interpolations: Dictionary = {}
var remote_frame_applied := false
var result_recorded := false
var capture_path := ""
var capture_done := false
var capture_time := 3.0
var network_events: Array = []
const MAX_NETWORK_EVENTS := 2048

func _ready() -> void:
	definitions = Catalog.load_units()
	ids = definitions.keys()
	presets = Catalog.presets()
	presets.append_array([
		{"name":"Cały roster • front i tyły", "a":["bear_hedgehog","bear_cheetah","monkey_hippo","skunk_rabbit","eagle","rabbit"], "b":["bear_monkey","eagle_hedgehog","monkey_skunk","hippo_rabbit","monkey","skunk"]},
		{"name":"Cały roster • ruch i kontrola", "a":["cheetah_eagle","hedgehog_skunk","hippo","bear","monkey","rabbit"], "b":["cheetah_rabbit","eagle_hippo","hedgehog","cheetah","skunk","eagle"]},
		{"name":"Próba • ciężki skok", "a":["eagle_hippo","bear","monkey"], "b":["bear_hedgehog","hippo","skunk"]},
		{"name":"Próba • potężny banan", "a":["monkey_hippo","bear","rabbit"], "b":["eagle_hedgehog","hippo","monkey"]},
		{"name":"Próba • trzy stożki", "a":["bear_cheetah","hippo","skunk"], "b":["bear_monkey","bear","cheetah"]},
		{"name":"Lvl III • Błyskobanan kontra Orłokolc", "a":["lvl3_01","bear","eagle"], "b":["lvl3_02","hippo","rabbit"]},
		{"name":"Lvl III • ciężkie nurkowania", "a":["lvl3_03","lvl3_07","monkey"], "b":["lvl3_08","lvl3_11","cheetah"]},
		{"name":"Lvl III • uniki i smród", "a":["lvl3_05","lvl3_09","skunk"], "b":["lvl3_04","lvl3_12","hedgehog"]}
	])
	presets.append_array(TeamfightDefinitions.presets())
	unit_root = Node2D.new()
	unit_root.position = ORIGIN
	unit_root.y_sort_enabled = true
	add_child(unit_root)
	effects_view = Node2D.new()
	effects_view.set_script(preload("res://scripts/presentation/effects_view.gd"))
	effects_view.position = ORIGIN
	add_child(effects_view)
	inspector_view = Node2D.new()
	inspector_view.z_index = 200
	inspector_view.draw.connect(_draw_hover)
	add_child(inspector_view)
	hud = CanvasLayer.new()
	add_child(hud)
	_make_ui()
	if not presets.is_empty(): _select_preset(0)
	_reset()
	# Reproducible optional visual QA: same core, no alternative combat rules.
	for argument in OS.get_cmdline_user_args():
		if argument == "--autostart": running = true
		if argument.begins_with("--capture="): capture_path = argument.trim_prefix("--capture=")
		if argument.begins_with("--capture-at="): capture_time = float(argument.trim_prefix("--capture-at="))

func _make_ui() -> void:
	_label("AUTO BATTLER ZOO", Vector2(36,15), 26, Color("f4edda"))
	_label("COMBAT LAB  /  v0.3", Vector2(350,23), 13, Color("a8b9b5"))
	teamfight_button = _button("NOWE: role i ratunki", Vector2(550,12), Vector2(290,34), func() -> void: set_balance_variant("T"))
	teamfight_button.tooltip_text = "Otwiera scenariusz Teamfight i resetuje obecną walkę laboratoryjną. Potem kliknij Start."
	preset_picker = OptionButton.new()
	preset_picker.position = Vector2(36,55)
	preset_picker.size = Vector2(270,30)
	preset_picker.clip_text = true
	preset_picker.fit_to_longest_item = false
	for preset in presets: preset_picker.add_item(preset.name)
	preset_picker.item_selected.connect(_select_preset)
	hud.add_child(preset_picker)
	start_button = _button("Start / pauza", Vector2(320,55), Vector2(126,30), _toggle)
	_button("Reset", Vector2(453,55),Vector2(76,30),_reset)
	_button("Krok",Vector2(536,55),Vector2(70,30),_single_step)
	var speed_picker := OptionButton.new()
	speed_picker.position = Vector2(614,55)
	speed_picker.size = Vector2(88,30)
	for title in ["0.5×", "1×", "2×", "4×"]: speed_picker.add_item(title)
	speed_picker.select(1)
	speed_picker.item_selected.connect(func(index: int) -> void: speed = [0.5,1.0,2.0,4.0][index])
	hud.add_child(speed_picker)
	variant_picker = OptionButton.new()
	variant_picker.position = Vector2(720,55)
	variant_picker.size = Vector2(260,30)
	variant_picker.add_item("B • Nowy cały roster")
	variant_picker.add_item("A • Przed zmianą całości")
	variant_picker.add_item("T • Teamfight: role i ratunki")
	variant_picker.tooltip_text = "T: osobny test 6 ról, po 2 skille, leczenie, tarcze i decyzje AI. Pełny mecz pozostaje w B. A zachowuje liczby sprzed rozszerzenia, w tym trzy poprawione hybrydy. B zmienia cały roster. Poziom III ma te same liczby w A i B. Efekty są wspólne. Zmiana A/B zachowuje składy; wejście w T ładuje pierwszy scenariusz testowy. Pełny mecz używa B."
	variant_picker.item_selected.connect(func(index: int) -> void: set_balance_variant(["B", "A", "T"][index]))
	hud.add_child(variant_picker)
	_label("Spacja: pauza • R: reset", Vector2(993,63),11,Color("a8b9b5"))
	for team in range(2):
		_label("A" if team == 0 else "B",Vector2(38,94+team*30),20,Color("55d6cb") if team == 0 else Color("ff9b79"))
		var team_selectors: Array = []
		for slot in range(6):
			var selector := OptionButton.new()
			selector.position = Vector2(70+slot*130,94+team*30)
			selector.size = Vector2(125,26)
			selector.add_theme_font_size_override("font_size",12)
			selector.add_item("— pusty —")
			for id in ids: selector.add_item(definitions[id].display_name)
			selector.item_selected.connect(func(_index: int) -> void: _reset())
			hud.add_child(selector)
			team_selectors.append(selector)
		selectors.append(team_selectors)
	status = _label("",Vector2(880,94),18,Color("f4edda"))
	totals = _label("",Vector2(880,124),12,Color("a8b9b5"))
	role_hint = _label("Niedźwiedź · szeroki zamach    Gepard · seria ×3    Małpa · banan    Orzeł · skok na najdalszego",Vector2(80,674),12,Color("d3ddd2"))
	role_hint_second = _label("Jeż · kolce    Hipopotam · ciężki cios / ogłuszenie    Skunks · ślad smrodu    Królik · skok za cel",Vector2(80,694),12,Color("a8b9b5"))
	report_button = _button("Raport ról", Vector2(1090,674), Vector2(115,26), _show_teamfight_report)
	report_button.visible = false
	art_hint = _label("KRESKÓWKOWA ZADYMA",Vector2(1080,674),11,Color("829791"))
	_label("Nad głową: HP • najedź: skille",Vector2(900,694),11,Color("c7b5fa"))

func _label(value: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.theme = Art.theme()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	hud.add_child(label)
	return label

func _button(value: String, at: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.theme = Art.theme()
	button.text = value
	button.position = at
	button.size = dimensions
	button.pressed.connect(callback)
	hud.add_child(button)
	return button

func _select_preset(index: int) -> void:
	preset_picker.select(index)
	if bool(presets[index].get("teamfight", false)):
		balance_variant = "T"
	elif balance_variant == "T":
		balance_variant = "B"
	_update_variant_controls()
	for team in range(2):
		var roster: Array = presets[index].a if team == 0 else presets[index].b
		for slot in range(6):
			selectors[team][slot].select(ids.find(roster[slot])+1 if slot < roster.size() else 0)
	_reset()

func _roster(team: int) -> Array:
	var result: Array = []
	for selector in selectors[team]:
		if selector.selected > 0: result.append(ids[selector.selected-1])
	return result

func set_balance_variant(value: String) -> void:
	var previous := balance_variant
	balance_variant = value if value in ["A", "B", "T"] else "B"
	_update_variant_controls()
	if balance_variant == "T" and previous != "T":
		for index in range(presets.size()):
			if bool(presets[index].get("teamfight", false)):
				_select_preset(index)
				return
	_reset()

func _update_variant_controls() -> void:
	variant_picker.select(["B", "A", "T"].find(balance_variant))
	var teamfight := balance_variant == "T"
	for team in selectors:
		for selector in team:
			for index in range(ids.size()):
				selector.set_item_disabled(index + 1, teamfight and ids[index] not in ["hippo", "monkey", "hedgehog", "cheetah", "skunk", "eagle"])
	role_hint.text = "HIPOPOTAM: tank   MAŁPA: leczenie   JEŻ: osłona   GEPARD: DPS   SKUNKS: kontrola   ORZEŁ: asasyn" if teamfight else "Niedźwiedź · szeroki zamach    Gepard · seria ×3    Małpa · banan    Orzeł · skok na najdalszego"
	role_hint_second.text = "T: osobny prototyp • najedź na postać: decyzja i skille • Raport ról: leczenie / tarcze / kontrola" if teamfight else "Jeż · kolce    Hipopotam · ciężki cios / ogłuszenie    Skunks · ślad smrodu    Królik · skok za cel"
	report_button.visible = teamfight
	art_hint.visible = not teamfight

func _reset() -> void:
	running = false
	remote_mode = false
	remote_interpolations.clear()
	remote_frame_applied = false
	network_events.clear()
	accumulator = 0
	result_recorded = false
	effect_texts.clear()
	effects_view.reset_feedback()
	for view in views.values(): view.queue_free()
	views.clear()
	sim = TeamfightSimulation.new() if balance_variant == "T" else Simulation.new()
	var valid: bool = false
	if not _roster(0).is_empty() and not _roster(1).is_empty():
		valid = sim.setup(_roster(0),_roster(1),1,{"definitions":TeamfightDefinitions.definitions() if balance_variant == "T" else Variants.definitions(balance_variant)})
	if not valid:
		status.text = "Wybierz obie drużyny"
		totals.text = "Minimum 1 jednostka na stronę"
		queue_redraw()
		return
	_sync()

func _toggle() -> void:
	if sim == null or sim.units.is_empty(): return
	if sim.result != "running": _reset()
	running = not running
	_sync()

func _single_step() -> void:
	running = false
	if sim != null and not sim.units.is_empty() and sim.result == "running":
		sim.step()
		_ingest_feedback()
		_capture_network_events()
		_sync()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE: _toggle()
		if event.keycode == KEY_R: _reset()

func _physics_process(delta: float) -> void:
	if sim == null: return
	if not remote_mode and running and sim.result == "running":
		accumulator += delta * speed
		while accumulator >= 1.0/60.0 and sim.result == "running":
			sim.step()
			_ingest_feedback()
			_capture_network_events()
			accumulator -= 1.0/60.0
		_sync()
	if sim.result != "running": running = false

func _ingest_feedback() -> void:
	_ingest_events(sim.events)

func _ingest_events(events: Array) -> void:
	var visual_events: Array = []
	for event: Dictionary in events:
		var visual_event := event.duplicate()
		var source := int(event.get("source", -1))
		var target := int(event.get("target", -1))
		if source >= 0 and source < sim.units.size():
			for skill: Resource in sim.units[source].definition.skills:
				var event_skill := _find_skill_in_chain(skill, str(event.get("skill", "")), [])
				if event_skill != null:
					visual_event["skill_behavior"] = event_skill.behavior
					visual_event["skill_hits"] = maxi(event_skill.hits,maxi(event_skill.airborne_hits,event_skill.followup_hits))
					break
		if source >= 0 and source < sim.units.size() and target >= 0 and target < sim.units.size():
			visual_event["impact_direction"] = (Vector2(sim.units[target].pos)-Vector2(sim.units[source].pos)).normalized()
		if views.has(source) and (event.get("kind", "") == "projectile" or (event.get("kind", "") == "damage" and event.get("damage_kind", "") in ["basic", "skill"] and not bool(event.get("projectile", false)))):
			views[source].attack_at = sim.time
		if views.has(source): views[source].receive_source_feedback(visual_event, sim.time)
		visual_events.append(visual_event)
		var recipient := -1
		if event.get("kind", "") == "skill_start": recipient = int(event.get("source", -1))
		elif event.get("kind", "") == "damage" and float(event.get("amount", 0.0)) > 0.0:
			recipient = int(event.get("target", -1))
		if views.has(recipient):
			views[recipient].receive_feedback(visual_event,sim.time)
	effects_view.ingest(visual_events,sim.units,sim.time)

func _find_skill_in_chain(skill: Resource, skill_id: String, visited: Array[String]) -> Resource:
	if skill == null or str(skill.id) in visited:
		return null
	if str(skill.id) == skill_id:
		return skill
	var next_visited := visited.duplicate()
	next_visited.append(str(skill.id))
	return _find_skill_in_chain(skill.followup_skill, skill_id, next_visited)

func _capture_network_events() -> void:
	if not network_capture:
		return
	for event: Dictionary in sim.events:
		network_events.append(event.duplicate(true))
	while network_events.size() > MAX_NETWORK_EVENTS:
		network_events.pop_front()

func drain_network_events() -> Array:
	var drained := network_events
	network_events = []
	return drained

func apply_remote_frame(frame: Dictionary, events: Array, playing: bool, playback_speed: float) -> void:
	if sim == null:
		return
	var previous_views: Dictionary = {}
	for unit: Dictionary in sim.units:
		if remote_frame_applied and views.has(unit.uid):
			previous_views[unit.uid] = {"id": unit.id, "position": views[unit.uid].position}
	remote_mode = true
	running = playing
	speed = maxf(0.0, playback_speed)
	var local_definitions: Dictionary = sim.definitions if not sim.definitions.is_empty() else definitions
	CombatWire.apply(sim, frame, local_definitions)
	_sync()
	remote_interpolations.clear()
	for unit: Dictionary in sim.units:
		if not previous_views.has(unit.uid) or str(previous_views[unit.uid].id) != str(unit.id):
			continue
		var from: Vector2 = previous_views[unit.uid].position
		var to: Vector2 = unit.pos
		if from.distance_squared_to(to) > 0.01:
			views[unit.uid].position = from
			remote_interpolations[unit.uid] = {"from": from, "to": to, "elapsed": 0.0}
	remote_frame_applied = true
	_ingest_events(events)

func _advance_remote_views(delta: float) -> void:
	if not remote_mode:
		return
	for uid in remote_interpolations:
		if not views.has(uid):
			continue
		var transition: Dictionary = remote_interpolations[uid]
		transition.elapsed = minf(0.05, float(transition.elapsed) + delta)
		var progress: float = float(transition.elapsed) / 0.05
		views[uid].position = Vector2(transition.from).lerp(Vector2(transition.to), progress)

func _sync() -> void:
	effects_view.set_playback(running or sim.result != "running",speed)
	var alive := [0,0]
	var damage := [0.0,0.0]
	var present_uids: Dictionary = {}
	for unit in sim.units:
		present_uids[unit.uid] = true
		if not views.has(unit.uid):
			var view := UnitView.instantiate()
			view.hippo_audio = effects_view.hippo_audio
			unit_root.add_child(view)
			views[unit.uid] = view
		views[unit.uid].celebrating = sim.result != "running" and bool(unit.alive)
		views[unit.uid].refresh(unit,sim.time)
		if unit.alive: alive[unit.team] += 1
		damage[unit.team] += unit.damage_dealt
	for uid in views.keys():
		if not present_uids.has(uid):
			views[uid].queue_free()
			views.erase(uid)
	status.text = "%05.1f s   A %d : %d B" % [sim.time,alive[0],alive[1]]
	totals.text = "Damage  A %.0f  /  B %.0f" % [damage[0],damage[1]]
	if sim.result != "running":
		status.text = ("REMIS" if sim.result == "draw" else "WYGRYWA " + sim.result) + "  ·  %.1f s" % sim.time
		if not result_recorded:
			result_recorded = true
			var report: Dictionary = sim.summary()
			report["balance_variant"] = balance_variant
			report["team_a"] = _roster(0)
			report["team_b"] = _roster(1)
			var file := FileAccess.open("user://last_combat.json", FileAccess.WRITE)
			if file != null: file.store_string(JSON.stringify(report, "\t"))
			print("COMBAT_RESULT ", JSON.stringify(report))
	start_button.text = "Pauza" if running else ("Start" if sim.time == 0 else "Wznów / nowa")
	for team in selectors:
		for selector in team: selector.disabled = running
	preset_picker.disabled = running
	variant_picker.disabled = false
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,Vector2(1600,1000)),Color("182c2b"))
	var border := StyleBoxFlat.new()
	border.bg_color = Color("efdbac")
	border.border_color = Color("123338")
	border.set_border_width_all(5)
	border.set_corner_radius_all(22)
	draw_style_box(border,Rect2(ORIGIN-Vector2(8,5),ARENA+Vector2(16,10)))
	draw_texture_rect(ARENA_ART, Rect2(ORIGIN, ARENA), false)
	_draw_clouds()
	draw_string(ThemeDB.fallback_font,ORIGIN+Vector2(20,30),"A",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("488d82"))
	draw_string(ThemeDB.fallback_font,ORIGIN+Vector2(1080,30),"B",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("b47858"))
	if sim == null: return
	for projectile in sim.projectiles:
		var p: Vector2 = ORIGIN + projectile.pos
		var large: bool = str(projectile.get("kind","")) != "basic"
		var projectile_color: Color = sim.units[projectile.source].definition.projectile_color
		if large:
			var direction: Vector2 = (Vector2(sim.units[projectile.target].pos) - Vector2(projectile.pos)).normalized()
			var heavy: bool = float(projectile.get("stun",0.0)) > 0.0
			var radius := 11.0 if heavy else 7.0
			var rotten: bool = float(projectile.get("cloud_damage",0.0)) > 0.0
			var tint := Color("b1d56b") if rotten else projectile_color
			draw_line(p-direction*(30.0 if heavy else 21.0),p,Color(tint,0.45),7.0 if heavy else 4.0,true)
			draw_circle(p,radius+6.0,Color(tint,0.22))
			draw_arc(p,radius,direction.angle()-2.2,direction.angle()+0.6,16,INK,9.0 if heavy else 7.0,true)
			draw_arc(p,radius,direction.angle()-2.2,direction.angle()+0.6,16,tint,5.0 if heavy else 3.5,true)
			if rotten: draw_circle(p+Vector2(2,-2),2.0,Color("567343"))
			continue
		draw_circle(p,9 if large else 4, INK)
		draw_circle(p,7 if large else 2.5,projectile_color)
	if not running and sim.result == "running" and sim.time > 0:
		draw_string(ThemeDB.fallback_font,ORIGIN+Vector2(496,28),"PAUZA",HORIZONTAL_ALIGNMENT_LEFT,-1,18,INK)

func _draw_clouds() -> void:
	if sim == null: return
	for cloud in sim.clouds:
		var point: Vector2 = ORIGIN + cloud.get("pos", Vector2.ZERO)
		var radius := float(cloud.get("radius", 55.0))
		var team := int(cloud.get("team", 0))
		var tint := Color("9cc75d") if team == 0 else Color("bdcf65")
		var thorny: bool = float(cloud.get("stagger",0.0)) > 0.0
		var slowing: bool = float(cloud.get("slow",1.0)) < 1.0
		if thorny: tint = Color("b099cd")
		elif slowing: tint = Color("86bc73")
		var age_phase := fposmod(sim.time * 1.7 + float(cloud.get("source", 0)) * 0.7, 1.0)
		var since_tick := float(sim.tick - (int(cloud.next)-int(cloud.interval))) / 60.0
		var flash := clampf(1.0-since_tick/0.18,0.0,1.0)
		var pulse := 0.96 + flash * 0.04
		tint.a = 0.11
		draw_circle(point, radius * pulse, tint)
		tint.a = 0.40 + flash * 0.30
		draw_arc(point, radius * pulse, 0, TAU, 36, tint, 2.0, true)
		if slowing: draw_arc(point,radius-6.0,0,TAU,36,Color(tint,0.35),1.5,true)
		if thorny:
			for spike in range(12):
				var outward := Vector2.from_angle(TAU*float(spike)/12.0)
				var side := outward.orthogonal()*3.0
				draw_polyline(PackedVector2Array([point+outward*(radius-5.0)-side,point+outward*(radius+3.0+flash*4.0),point+outward*(radius-5.0)+side]),Color(tint,0.7),2.0,true)
		var inner := radius * (0.48 + age_phase * 0.34)
		tint.a = 0.19
		draw_arc(point, inner, 0, TAU, 28, tint, 2.0, true)
		for index in range(7):
			var phase: float = sim.time
			var angle := phase * (0.8 + float(index % 3) * 0.2) + float(index) * TAU / 7.0
			var mote := point + Vector2.from_angle(angle) * radius * (0.3 + 0.55 * float((index * 3) % 7) / 7.0)
			draw_circle(mote + Vector2(0, sin(angle * 2.0) * 3.0), 2.0 if index % 2 == 0 else 1.4, Color(tint.r,tint.g,tint.b,0.6))

func _process(_delta: float) -> void:
	_advance_remote_views(_delta)
	if not capture_path.is_empty() and not capture_done and sim != null and sim.time >= capture_time:
		capture_done = true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_path)
		print("VISUAL_CAPTURE ", capture_path)
	# Hover inspection is read-only and never advances the simulation.
	inspector_view.queue_redraw()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer_position = get_global_transform_with_canvas().affine_inverse() * event.position

func _inspection_unit() -> Dictionary:
	if sim == null: return {}
	var mouse := pointer_position
	var hovered: Dictionary = {}
	var nearest := INF
	for unit: Dictionary in sim.units:
		if not unit.alive: continue
		var gap := mouse.distance_to(ORIGIN + Vector2(unit.pos))
		if gap < maxf(30.0, float(unit.definition.radius)) and gap < nearest:
			hovered = unit
			nearest = gap
	return hovered

func _draw_hover() -> void:
	var hovered := _inspection_unit()
	if hovered.is_empty(): return
	var skills: Array[Dictionary] = Readiness.rows(hovered, sim.time)
	var height := 100.0 + skills.size() * 46.0
	var at := Vector2(850, 652-height)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("203332")
	background.border_color = Color("8faaa4")
	background.set_border_width_all(2)
	background.set_corner_radius_all(8)
	inspector_view.draw_style_box(background,Rect2(at,Vector2(342,height)))
	inspector_view.draw_arc(ORIGIN + Vector2(hovered.pos), 39, 0, TAU, 36, Color("fff4d3"), 2.0, true)
	var definition: Resource = hovered.definition
	var title := "%s • %s" % [definition.display_name, "A" if hovered.team == 0 else "B"]
	var hp_line := "HP %.0f / %.0f" % [hovered.hp, definition.max_hp]
	if float(hovered.get("shield_hp",0)) > 0.0: hp_line += "   Tarcza: %.0f" % hovered.shield_hp
	var role := _teamfight_role_label(str(hovered.get("teamfight_role", "")))
	if not role.is_empty(): title += " • " + role
	inspector_view.draw_string(ThemeDB.fallback_font,at+Vector2(14,25),title,HORIZONTAL_ALIGNMENT_LEFT,314,15,Color("f4edda"))
	inspector_view.draw_string(ThemeDB.fallback_font,at+Vector2(14,49),hp_line,HORIZONTAL_ALIGNMENT_LEFT,314,14,Color("e8eee0"))
	inspector_view.draw_string(ThemeDB.fallback_font,at+Vector2(14,76),"UMIEJĘTNOŚCI • czas do użycia",HORIZONTAL_ALIGNMENT_LEFT,314,12,Color("a8b9b5"))
	for index in range(skills.size()):
		var skill: Dictionary = skills[index]
		var y := 98.0 + index * 46.0
		var state := "%.1f s" % float(skill.remaining)
		var tint := Color("b8a1ff")
		if skill.ready:
			state = "GOTOWY"
			tint = Color("ffe190")
		if skill.casting:
			state = "UŻYWA"
			tint = Color("ffae64")
		if skill.passive: state = "PASYWNY"
		inspector_view.draw_string(ThemeDB.fallback_font,at+Vector2(14,y),str(skill.name),HORIZONTAL_ALIGNMENT_LEFT,222,13,Color("f4edda"))
		inspector_view.draw_string(ThemeDB.fallback_font,at+Vector2(246,y),state,HORIZONTAL_ALIGNMENT_LEFT,85,12,tint)
		if not skill.passive:
			inspector_view.draw_rect(Rect2(at+Vector2(14,y+8),Vector2(312,5)),Color("101e1e"))
			inspector_view.draw_rect(Rect2(at+Vector2(14,y+8),Vector2(312*float(skill.progress),5)),tint)
	inspector_view.draw_string(ThemeDB.fallback_font,at+Vector2(14,height-10),"Gotowy skill czeka na odpowiednią sytuację.",HORIZONTAL_ALIGNMENT_LEFT,314,10,Color("a8b9b5"))


func _show_teamfight_report() -> void:
	if balance_variant != "T" or sim == null: return
	if not is_instance_valid(teamfight_report):
		teamfight_report = AcceptDialog.new()
		teamfight_report.title = "Teamfight — wkład jednostek"
		teamfight_report.ok_button_text = "Wróć do walki"
		teamfight_report.min_size = Vector2i(650, 380)
		hud.add_child(teamfight_report)
		teamfight_report_text = RichTextLabel.new()
		teamfight_report_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		teamfight_report_text.offset_left = 16
		teamfight_report_text.offset_right = -16
		teamfight_report_text.offset_top = 14
		teamfight_report_text.offset_bottom = -54
		teamfight_report.add_child(teamfight_report_text)
	running = false
	_sync()
	var report: Dictionary = sim.summary()
	var lines: Array[String] = ["Czas %.1f s • wynik: %s" % [sim.time, "w toku" if sim.result == "running" else sim.result], "Leczenie liczy odzyskane HP; osłona tylko faktycznie pochłonięte obrażenia.", ""]
	for player in range(2):
		lines.append("DRUŻYNA " + ("A" if player == 0 else "B"))
		for row in report.units:
			if int(row.team) != player: continue
			lines.append("%s [%d] • obrażenia %.0f • leczenie %.0f • osłona %.0f" % [definitions[row.id].display_name, int(row.uid) + 1, row.damage_dealt, row.get("healing_done", 0.0), row.get("shield_absorbed", 0.0)])
			lines.append("   Przerwania: %d • odwroty: %d • %s" % [row.get("interrupts", 0), row.get("retreats", 0), ("żyje" if sim.result == "running" else "przeżył") if row.survived else "poległ"])
			var skills: Array[String] = []
			for skill in sim.definitions[row.id].skills:
				skills.append("%s ×%d" % [Readiness.skill_name(skill), int(row.skill_uses.get(skill.id, 0))])
			lines.append("   " + ", ".join(skills))
		lines.append("")
	teamfight_report_text.text = "\n".join(lines)
	teamfight_report.popup_centered(Vector2i(880, 560))


func _teamfight_role_label(value: String) -> String:
	return str({"hippo_tank":"Tank", "monkey_healer":"Leczenie", "hedgehog_shield":"Osłona", "cheetah_dps":"Obrażenia", "skunk_controller":"Kontrola", "eagle_assassin":"Asasyn"}.get(value, value))

func _teamfight_plan_label(value: String) -> String:
	return str({"engage":"Atak", "retreat":"Odwrót do osłony", "protect":"Osłona", "heal":"Leczenie", "support":"Podejście do sojusznika", "evade":"Unik", "watch":"Obserwuje zagrożenie", "pursue":"Pościg", "spawn":"Rozpoznanie"}.get(value, value))
