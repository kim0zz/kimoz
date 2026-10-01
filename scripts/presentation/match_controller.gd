extends Node2D

const Art = preload("res://scripts/presentation/cartoon_art.gd")
const OnlineSession = preload("res://scripts/network/online_session.gd")
const MatchWire = preload("res://scripts/network/match_wire.gd")
const CombatWire = preload("res://scripts/network/combat_wire.gd")
const Model = preload("res://scripts/match/match_model.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const UnitInfo = preload("res://scripts/presentation/unit_info.gd")
const CombatScene = preload("res://scenes/combat/combat_prototype.tscn")

const BG := Color("183c40")
const PANEL := Color("214b50")
const TEXT := Color("f4edda")
const MUTED := Color("b8c6b8")
const TEAL := Color("55d6cb")
const CORAL := Color("ff9b79")
const DIM_TEXT := Color("87958a")

var online: Node
var network_button: Button
var network_label: Label
var lobby_join_button: Button
var lobby_host_button: Button
var network_dialog: AcceptDialog
var address_input: LineEdit
var port_input: SpinBox
var room_input: LineEdit
var room_host_button: Button
var room_join_button: Button
var room_copy_button: Button
var lobby_status: Label
var revision := 0
var ready_players: Array[bool] = [false, false]
var network_waiting := false
var command_pending := false
var network_elapsed := 0.0
var refresh_serial := 0
var displayed_phase := ""
var team_scrolls: Array[ScrollContainer] = []

var model := Model.new()
var definitions: Dictionary = {}
var arena: Node
var overlay: CanvasLayer
var match_panel: MarginContainer
var root_column: VBoxContainer
var content_scroll: ScrollContainer
var backdrop: ColorRect
var lab_exit_button: Button
var lab_button: Button
var lab_mode := false
var headline: Label
var subhead: Label
var message: Label
var buttons: VBoxContainer
var selected_tokens: Array = [[], []]
var pause_button: Button
var speed_picker: OptionButton
var seeded_match := 1
var last_battle_summary: Dictionary = {}
var info_dialog: AcceptDialog
var info_column: VBoxContainer
var info_scroll: ScrollContainer
var info_history: Array[String] = []
var info_player := 0

func _ready() -> void:
	definitions = Catalog.load_units()
	arena = CombatScene.instantiate()
	add_child(arena)
	arena.visible = false
	arena.set_process_unhandled_key_input(false)
	if arena.get("hud") != null: arena.get("hud").hide()
	overlay = CanvasLayer.new()
	add_child(overlay)
	_build_shell()
	online = OnlineSession.new()
	online.name = "OnlineSession"
	add_child(online)
	online.connected_match.connect(_online_connected)
	online.disconnected.connect(_online_disconnected)
	online.status_changed.connect(_online_status)
	online.command_received.connect(_receive_command)
	online.state_received.connect(_receive_state)
	online.combat_received.connect(_receive_combat)
	model.begin_match()
	_refresh()

func _build_shell() -> void:
	backdrop = ColorRect.new()
	backdrop.color = BG
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)
	var margin := MarginContainer.new()
	match_panel = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	overlay.add_child(margin)
	root_column = VBoxContainer.new()
	root_column.theme = Art.theme()
	root_column.add_theme_constant_override("separation", 12)
	margin.add_child(root_column)
	var top := HBoxContainer.new()
	root_column.add_child(top)
	var title := Label.new()
	title.text = "KIMOZ"
	title.add_theme_font_override("font",Art.DISPLAY_FONT)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	headline = Label.new()
	headline.add_theme_font_size_override("font_size", 18)
	headline.add_theme_color_override("font_color", TEAL)
	top.add_child(headline)
	lab_button = _make_button("Combat Lab", true)
	lab_button.pressed.connect(_enter_lab)
	top.add_child(lab_button)
	subhead = Label.new()
	subhead.add_theme_font_size_override("font_size", 14)
	subhead.add_theme_color_override("font_color", MUTED)
	root_column.add_child(subhead)
	network_label = _plain_label("Gra lokalna • obaj gracze na tym komputerze")
	root_column.add_child(network_label)
	network_button = _make_button("Graj online", true)
	network_button.pressed.connect(_open_network)
	top.add_child(network_button)
	message = Label.new()
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", TEXT)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message.custom_minimum_size.y = 28
	root_column.add_child(message)
	var divider := HSeparator.new()
	root_column.add_child(divider)
	content_scroll = ScrollContainer.new()
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_column.add_child(content_scroll)
	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.add_child(buttons)
	lab_exit_button = _make_button("← Powrót do meczu", true)
	lab_exit_button.position = Vector2(1030, 12)
	lab_exit_button.size = Vector2(225, 38)
	lab_exit_button.z_index = 100
	lab_exit_button.visible = false
	lab_exit_button.pressed.connect(_exit_lab)
	overlay.add_child(lab_exit_button)

func _refresh() -> void:
	if not is_instance_valid(buttons): return
	var phase_key := "%s:%d" % [model.phase, model.round_number]
	var scroll_y := content_scroll.scroll_vertical if displayed_phase == phase_key else 0
	var team_y: Array[int] = []
	for scroll in team_scrolls:
		team_y.append(scroll.scroll_vertical if is_instance_valid(scroll) and displayed_phase == phase_key else 0)
	team_scrolls.clear()
	displayed_phase = phase_key
	refresh_serial += 1
	var serial := refresh_serial
	if not lab_mode:
		backdrop.color.a = 0.0 if model.phase == "battle" else 1.0
		lab_button.disabled = model.phase == "battle" or _is_online() or network_waiting
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if model.phase in ["draft","initial_draft","prep"] else ScrollContainer.SCROLL_MODE_AUTO
	message.show()
	network_label.visible = model.phase != "battle"
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	message.text = ""
	if model.phase == "initial_draft" or model.phase == "draft":
		_show_draft()
	elif model.phase == "prep":
		_show_prep()
	elif model.phase == "battle":
		_show_battle()
	elif model.phase == "result":
		_show_result()
	elif model.phase == "match_over":
		_show_match_over()
	message.visible = not message.text.is_empty()
	_update_online_ui()
	_restore_scroll.call_deferred(serial, scroll_y, team_y)

func _show_draft() -> void:
	var player: int=model.turn_player
	headline.text="GRACZ %d — TWÓJ WYBÓR" % (player+1)
	headline.add_theme_font_size_override("font_size",22)
	headline.add_theme_color_override("font_color",TEAL if player==0 else CORAL)
	subhead.text="RUNDA %d • ŻYCIA %d : %d • Pozostałe akcje: %d" % [model.round_number,model.lives[0],model.lives[1],model.actions_left[player]]
	_add_development()

func _show_prep() -> void:
	headline.text="RUNDA %d • PRZYGOTOWANIE" % model.round_number
	subhead.text="Wybierz jednostkę i ustaw aktywny skład. Zmiany ustawienia są bezpłatne."
	_add_development()

func _add_development() -> void:
	var view := preload("res://scripts/presentation/development_view.gd").new()
	view.host=self
	buttons.add_child(view)

func _show_battle() -> void:
	message.hide()
	headline.text = "RUNDA %d   •   WALKA" % model.round_number
	subhead.text = "Starcie trwa do wybicia jednej drużyny.   •   Życia: %d : %d" % [model.lives[0], model.lives[1]]
	var controls := HBoxContainer.new()
	buttons.add_child(controls)
	pause_button = _make_button("Pauza" if arena.get("running") else "Wznów", true)
	pause_button.pressed.connect(_toggle_pause)
	controls.add_child(pause_button)
	speed_picker = OptionButton.new()
	for label in ["0,5×", "1×", "2×", "4×"]: speed_picker.add_item(label)
	speed_picker.select([0.5, 1.0, 2.0, 4.0].find(float(arena.get("speed"))))
	speed_picker.item_selected.connect(_set_speed)
	controls.add_child(speed_picker)
	var hint := _plain_label("Walka automatyczna • pauzę i tempo ustawia host" if _is_online() and not online.is_host else "Walka automatyczna • spacja: pauza")
	controls.add_child(hint)

func _show_result() -> void:
	headline.text = "WYNIK WALKI"
	headline.add_theme_color_override("font_color", TEXT)
	subhead.text = "RUNDA %d" % (model.round_number - 1)
	if model.last_result == "A":
		_add_result_banner("GRACZ A WYGRYWA RUNDĘ", "Gracz B traci 1 życie   •   Życia: %d : %d" % [model.lives[0], model.lives[1]], TEAL)
	elif model.last_result == "B":
		_add_result_banner("GRACZ B WYGRYWA RUNDĘ", "Gracz A traci 1 życie   •   Życia: %d : %d" % [model.lives[0], model.lives[1]], CORAL)
	else:
		_add_result_banner("REMIS", "Nikt nie traci życia   •   Życia: %d : %d   •   Pierwszy wybiera %s" % [model.lives[0], model.lives[1], _player_name(model.priority_player)], Color("e3c982"))
	_add_damage_summary()
	var next := _make_button("PRZEJDŹ DO NASTĘPNEGO DRAFTU", true)
	next.pressed.connect(_next_round)
	buttons.add_child(next)

func _show_match_over() -> void:
	headline.text = "KONIEC MECZU"
	headline.add_theme_color_override("font_color", TEXT)
	subhead.text = ""
	var winner := model.match_winner
	var loser := 1 - winner
	var winner_color := TEAL if winner == 0 else CORAL
	_add_result_banner("%s WYGRYWA CAŁY MECZ" % _player_name(winner).to_upper(), "%s traci ostatnie życie   •   Życia: %d : %d" % [_player_name(loser), model.lives[0], model.lives[1]], winner_color)
	_add_damage_summary()
	var again := _make_button("NOWY MECZ", true)
	again.pressed.connect(_new_match)
	buttons.add_child(again)

func _add_result_banner(title_text: String, detail_text: String, accent: Color) -> void:
	var banner := PanelContainer.new()
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.custom_minimum_size.y = 112
	var style := StyleBoxFlat.new()
	style.bg_color = Color("203630")
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	banner.add_theme_stylebox_override("panel", style)
	buttons.add_child(banner)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	banner.add_child(column)
	var title := _plain_label(title_text)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", accent)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(title)
	var detail := _plain_label(detail_text)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 18)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(detail)

func _add_teams(selectable: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	buttons.add_child(row)
	for player in range(2):
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var active_draft_player := model.phase in ["initial_draft", "draft"] and player == model.turn_player
		panel.add_theme_stylebox_override("panel", _panel_style(player, active_draft_player))
		if model.phase in ["initial_draft", "draft"] and player != model.turn_player:
			panel.modulate = Color(0.68, 0.71, 0.68, 1.0)
		row.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		panel.add_child(column)
		var title := _plain_label("%s   •   ♥ %d   •   aktywne %d/6   •   razem %d/9" % [
			_player_name(player), model.lives[player], model.active_count(player), model.owned_count(player)])
		title.add_theme_color_override("font_color", (TEAL if player == 0 else CORAL) if active_draft_player or model.phase not in ["initial_draft", "draft"] else DIM_TEXT)
		column.add_child(title)
		var scroll := ScrollContainer.new()
		team_scrolls.append(scroll)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.custom_minimum_size.y = 150
		column.add_child(scroll)
		var unit_column := VBoxContainer.new()
		unit_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		unit_column.add_theme_constant_override("separation", 4)
		scroll.add_child(unit_column)
		if model.teams[player].is_empty():
			unit_column.add_child(_plain_label("Brak jednostek"))
		for index in range(model.teams[player].size()):
			var unit: Dictionary = model.teams[player][index]
			var slot := "AKTYWNA" if unit.active else "REZERWA"
			var is_selected: bool = selected_tokens[player].has(unit.token)
			var marker := "  [WYBRANA]" if is_selected else "  [PASUJE DO PARY]" if _is_compatible_with_selection(player, int(unit.token)) else ""
			var compatible_highlight := _is_compatible_with_selection(player, int(unit.token))
			var can_select := selectable and _can_control(player) and (model.phase not in ["initial_draft", "draft"] or player == model.turn_player)
			var card := _make_card("%s   ·   %s%s" % [_unit_name(str(unit.id)), slot, marker], _level_text(str(unit.id)), can_select)
			card.icon = Art.texture(str(unit.id))
			card.expand_icon = true
			card.add_theme_constant_override("icon_max_width", 50)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.set_meta("unit_token", int(unit.token))
			card.set_meta("selected_unit", is_selected)
			if is_selected:
				var chosen := _card_style(Color("ffe18b"))
				chosen.bg_color = Color("65542c")
				chosen.set_border_width_all(3)
				for state in ["normal", "hover", "pressed", "focus"]:
					card.add_theme_stylebox_override(state, chosen)
			elif compatible_highlight:
				var color := Color("698f87")
				card.add_theme_stylebox_override("normal", _card_style(color))
				card.add_theme_stylebox_override("hover", _card_style(color.lightened(0.18)))
				card.add_theme_color_override("font_color", TEXT)
				card.add_theme_color_override("font_hover_color", TEXT)
			if can_select:
				card.pressed.connect(_select_unit.bind(player, int(unit.token)))
			var unit_row := HBoxContainer.new()
			unit_column.add_child(unit_row)
			unit_row.add_child(card)
			var inspect := _make_button("Info", true)
			inspect.tooltip_text = "Rola, skille i połączenia"
			inspect.pressed.connect(_open_info.bind(str(unit.id), player))
			unit_row.add_child(inspect)

func _add_section_title(value: String) -> void:
	var label := _plain_label(value)
	label.add_theme_color_override("font_color", MUTED)
	buttons.add_child(label)

func _plain_label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_font_size_override("font_size", 14)
	return label

func _make_button(value: String, enabled: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.disabled = not enabled
	button.custom_minimum_size.y = 34
	return button

func _make_card(title: String, detail: String, enabled: bool) -> Button:
	var button := Button.new()
	button.text = title + "\n" + detail
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(0, 58)
	button.add_theme_font_size_override("font_size", 14)
	return button

func _panel_style(player: int = -1, emphasized: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2a5b60") if emphasized else Color("203c40") if player >= 0 and model.phase in ["initial_draft", "draft"] else PANEL
	style.border_color = TEAL if player == 0 and emphasized else CORAL if player == 1 and emphasized else Color("528486")
	style.set_border_width_all(3 if emphasized else 1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _card_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("31514b")
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style

func _unit_name(id: String) -> String:
	if definitions.has(id): return str(definitions[id].display_name)
	return id

func _selected_pair_result(player: int) -> String:
	if selected_tokens[player].size() != 2: return ""
	var first := _id_for_token(player, int(selected_tokens[player][0]))
	var second := _id_for_token(player, int(selected_tokens[player][1]))
	return model.compatible_pair(first, second)

func _offer_fusion_hint(player: int, offer_id: String) -> String:
	var possible: Array[String] = []
	for unit in model.teams[player]:
		var owned_id := str(unit.id)
		var result := model.compatible_pair(owned_id, offer_id)
		if not result.is_empty():
			possible.append("%s + %s → %s" % [_unit_name(owned_id), _unit_name(offer_id), _unit_name(result)])
	if possible.is_empty(): return ""
	return "Możliwe połączenie po zdobyciu tej oferty:\n" + "\n".join(possible)

func _is_compatible_with_selection(player: int, token: int) -> bool:
	if selected_tokens[player].size() != 1 or selected_tokens[player].has(token): return false
	var first_id := _id_for_token(player, int(selected_tokens[player][0]))
	var second_id := _id_for_token(player, token)
	return not model.compatible_pair(first_id, second_id).is_empty()

func _fusion_preview(player: int, fusion_id: String) -> String:
	var first_id := _id_for_token(player, int(selected_tokens[player][0]))
	var second_id := _id_for_token(player, int(selected_tokens[player][1]))
	return "%s + %s  →  %s\n%s" % [_unit_name(first_id), _unit_name(second_id), _unit_name(fusion_id), UnitInfo.summary(definitions[fusion_id])]

func _id_for_token(player: int, token: int) -> String:
	for unit in model.teams[player]:
		if int(unit.token) == token: return str(unit.id)
	return ""

func _level_text(id: String) -> String:
	if Catalog.lvl3_ids().has(id): return "POZIOM III • forma końcowa"
	if Catalog.hybrid_ids().has(id): return "Poziom II • hybryda"
	return "Poziom I"

func _player_name(player: int) -> String:
	return "Gracz A" if player == 0 else "Gracz B"

func _management_player() -> int:
	if _is_online(): return online.local_player
	return int(get_meta("management_player", 0))

func _select_unit(player: int, token: int) -> void:
	if not _can_control(player): return
	if model.phase == "prep":
		set_meta("management_player", player)
	if model.phase == "initial_draft" or model.phase == "draft":
		if player != model.turn_player: return
	if selected_tokens[player].has(token): selected_tokens[player].erase(token)
	else:
		if selected_tokens[player].size() >= 2: selected_tokens[player].pop_front()
		selected_tokens[player].append(token)
	_refresh()

func _pick_offer(index: int) -> void:
	_request_action("pick", [index])

func _fuse_selected() -> void:
	var picks: Array = selected_tokens[model.turn_player]
	if picks.size() == 2: _request_action("fuse", picks.duplicate())

func _discard_selected() -> void:
	var player := model.turn_player if model.phase in ["initial_draft", "draft"] else _management_player()
	if selected_tokens[player].size() == 1: _request_action("discard", selected_tokens[player].duplicate())

func _pass() -> void:
	_request_action("pass")

func _toggle_selected() -> void:
	var picks: Array = selected_tokens[_management_player()]
	if picks.size() == 1: _request_action("toggle", picks.duplicate())

func _swap_selected() -> void:
	var picks: Array = selected_tokens[_management_player()]
	if picks.size() == 2: _request_action("swap", picks.duplicate())

func _move_selected(direction: int) -> void:
	var picks: Array = selected_tokens[_management_player()]
	if picks.size() == 1: _request_action("move", [picks[0], direction])

func _switch_management_player() -> void:
	if _is_online(): return
	set_meta("management_player", 1 - _management_player())
	selected_tokens = [[], []]
	_refresh()

func _start_battle() -> void:
	if _is_online(): _request_action("ready")
	else: _launch_battle()

func _launch_battle() -> void:
	if not model.start_battle(): return
	var runtime_ids: Array = arena.get("ids")
	for player in range(2):
		var selectors: Array = arena.get("selectors")[player]
		var active: Array[String] = model.active_ids(player)
		for slot in range(6):
			var selector: OptionButton = selectors[slot]
			var id: String = active[slot] if slot < active.size() else ""
			var position := runtime_ids.find(id)
			selector.select(position + 1 if position >= 0 else 0)
	arena.call("set_balance_variant", "B")
	if arena.get("hud") != null: arena.get("hud").hide()
	arena.visible = true
	arena.set("speed", 1.0)
	arena.call("_toggle")
	selected_tokens = [[], []]
	_refresh()

func _enter_lab() -> void:
	if model.phase == "battle" or _is_online() or network_waiting: return
	lab_mode = true
	match_panel.hide()
	backdrop.color.a = 0.0
	if arena.get("hud") != null: arena.get("hud").show()
	arena.visible = true
	arena.set_process_unhandled_key_input(true)
	lab_exit_button.show()

func _exit_lab() -> void:
	lab_mode = false
	if bool(arena.get("running")):
		arena.call("_toggle")
	if arena.get("hud") != null: arena.get("hud").hide()
	arena.visible = false
	arena.set_process_unhandled_key_input(false)
	backdrop.color.a = 1.0
	lab_exit_button.hide()
	match_panel.show()
	_refresh()

func _toggle_pause() -> void:
	_request_action("pause")

func _set_speed(index: int) -> void:
	_request_action("speed", [index])

func _new_match() -> void:
	if _is_online():
		_request_action("rematch")
		return
	_reset_match()

func _reset_match() -> void:
	last_battle_summary.clear()
	seeded_match += 1
	model.begin_match()
	set_meta("management_player", 0)
	selected_tokens = [[], []]
	ready_players = [false, false]
	_refresh()

func _next_round() -> void:
	_request_action("next")

func _unhandled_key_input(event: InputEvent) -> void:
	if model.phase == "battle" and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_toggle_pause()

func _physics_process(_delta: float) -> void:
	if network_waiting or (_is_online() and not online.is_host): return
	if _is_online() and model.phase == "battle":
		network_elapsed += _delta
		if network_elapsed >= 0.05:
			network_elapsed = 0.0
			_send_combat()
	if model.phase != "battle" or arena == null: return
	var simulation: Variant = arena.get("sim")
	if simulation == null or simulation.result == "running": return
	var result := "draw"
	if simulation.result == "A": result = "A"
	elif simulation.result == "B": result = "B"
	last_battle_summary = simulation.summary().duplicate(true)
	last_battle_summary["round"] = model.round_number
	model.finish_battle(result)
	ready_players = [false, false]
	revision += 1
	arena.visible = false
	_refresh()
	_publish_state()

func _wrapped_label(value: String) -> Label:
	var label := _plain_label(value)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _partners(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var next_level_ids: Array[String] = Catalog.hybrid_ids() if definitions[id].level == 1 else Catalog.lvl3_ids()
	for next_id in next_level_ids:
		var parents: Array[String] = definitions[next_id].parents
		if id in parents:
			result.append({"partner": parents[1] if parents[0] == id else parents[0], "hybrid": next_id})
	return result

func _partner_names(id: String) -> String:
	var names: Array[String] = []
	for pair in _partners(id): names.append(_unit_name(pair.partner))
	return ", ".join(names)

func _owns(player: int, id: String) -> bool:
	for unit in model.teams[player]:
		if str(unit.id) == id: return true
	return false

func _owned_partner_names(id: String, player: int) -> String:
	var names: Array[String] = []
	for pair in _partners(id):
		if _owns(player, pair.partner): names.append(_unit_name(pair.partner))
	return ", ".join(names)

func _open_info(id: String, player: int) -> void:
	info_history.clear()
	info_player = player
	if not is_instance_valid(info_dialog):
		info_dialog = AcceptDialog.new()
		info_dialog.title = "Zwierzęta i hybrydy"
		info_dialog.ok_button_text = "Wróć do wyboru"
		info_dialog.min_size = Vector2i(700, 420)
		add_child(info_dialog)
		info_scroll = ScrollContainer.new()
		info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		info_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		info_scroll.offset_left = 18
		info_scroll.offset_right = -18
		info_scroll.offset_top = 16
		info_scroll.offset_bottom = -58
		info_dialog.add_child(info_scroll)
		info_column = VBoxContainer.new()
		info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_column.add_theme_constant_override("separation", 12)
		info_scroll.add_child(info_column)
	_show_info(id)
	info_dialog.popup_centered(Vector2i(840, 600))

func _show_info(id: String, remember: bool = true) -> void:
	if remember: info_history.append(id)
	for child in info_column.get_children():
		info_column.remove_child(child)
		child.queue_free()
	if info_history.size() > 1:
		var back := _make_button("← Poprzednie zwierzę", true)
		back.pressed.connect(func() -> void:
			info_history.pop_back()
			_show_info(info_history.back(), false))
		info_column.add_child(back)
	var definition: Resource = definitions[id]
	var title := _wrapped_label(_unit_name(id) + " • " + _level_text(id))
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", TEAL)
	info_column.add_child(title)
	info_column.add_child(Art.portrait(id, 150))
	info_column.add_child(_wrapped_label(UnitInfo.role_text(definition) + "\n" + UnitInfo.summary(definition)))
	info_column.add_child(_wrapped_label(UnitInfo.details(definition)))
	info_column.add_child(HSeparator.new())
	if definition.level < 3:
		info_column.add_child(_wrapped_label("POŁĄCZENIA • partnerzy w składzie i na ławce " + _player_name(info_player)))
		for pair in _partners(id):
			var owned := _owns(info_player, pair.partner)
			var label := _wrapped_label("%s + %s → %s\n%s" % [_unit_name(id), _unit_name(pair.partner), _unit_name(pair.hybrid), "✓ Masz partnera" if owned else "Brakuje partnera"])
			label.add_theme_color_override("font_color", Color("e3c982") if owned else TEXT)
			info_column.add_child(label)
			info_column.add_child(Art.portrait(str(pair.hybrid), 100))
			info_column.add_child(_wrapped_label(UnitInfo.summary(definitions[pair.hybrid])))
			var inspect := _make_button("Zobacz skille: " + _unit_name(pair.hybrid), true)
			inspect.pressed.connect(_show_info.bind(str(pair.hybrid)))
			info_column.add_child(inspect)
		if definition.level == 1:
			info_column.add_child(_wrapped_label("Dobranie zwierzęcia i połączenie to osobne akcje. Fuzja zużywa oboje rodziców; dostępna od drugiej rundy."))
		else:
			info_column.add_child(_wrapped_label("Forma III powstaje przez połączenie dwóch kompatybilnych hybryd poziomu II."))
	else:
		var bases: Array[String] = []
		for base_id in Catalog.base_traits(id): bases.append(_unit_name(base_id))
		info_column.add_child(_wrapped_label("FORMA III • cechy bazowe: " + ", ".join(bases)))
		info_column.add_child(_wrapped_label("Powstaje z: %s + %s." % [_unit_name(definition.parents[0]), _unit_name(definition.parents[1])]))
	info_scroll.set_deferred("scroll_vertical", 0)

func _add_damage_summary() -> void:
	if last_battle_summary.is_empty():
		_add_teams(false)
		return
	var units: Array = last_battle_summary.units
	var maximum := 0.0
	for unit: Dictionary in units: maximum = maxf(maximum, float(unit.damage_dealt))
	_add_section_title("OBRAŻENIA • runda %d • czas %.1f s • faktycznie odebrane HP" % [int(last_battle_summary.round), float(last_battle_summary.duration)])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	buttons.add_child(row)
	for player in range(2):
		var members: Array = units.filter(func(u: Dictionary) -> bool: return int(u.team) == player)
		members.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.damage_dealt) > float(b.damage_dealt) if not is_equal_approx(float(a.damage_dealt), float(b.damage_dealt)) else int(a.uid) < int(b.uid))
		var total := 0.0
		for unit: Dictionary in members: total += float(unit.damage_dealt)
		var accent := TEAL if player == 0 else CORAL
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", _panel_style())
		row.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		panel.add_child(column)
		var title := _plain_label("%s • razem %.1f obrażeń" % [_player_name(player), total])
		title.add_theme_color_override("font_color", accent)
		title.add_theme_font_size_override("font_size", 18)
		column.add_child(title)
		# The whole result page already scrolls. A nested expanding scroll has
		# no minimum height here and collapses, hiding the individual unit rows.
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 12)
		column.add_child(list)
		for unit: Dictionary in members:
			var entry := VBoxContainer.new()
			entry.add_theme_constant_override("separation", 3)
			list.add_child(entry)
			var slot := 0
			for original: Dictionary in units:
				if int(original.team) == player:
					slot += 1
					if int(original.uid) == int(unit.uid): break
			var leader := maximum > 0.0 and is_equal_approx(float(unit.damage_dealt), maximum)
			var name_label := _wrapped_label("%s [%d] • %.1f obrażeń • %.0f%% drużyny%s" % [_unit_name(str(unit.id)), slot, float(unit.damage_dealt), 100.0 * float(unit.damage_dealt) / maxf(total,0.000001), " • TOP RUNDY" if leader else ""])
			if leader: name_label.add_theme_color_override("font_color", Color("e3c982"))
			var identity := HBoxContainer.new()
			entry.add_child(identity)
			identity.add_child(Art.portrait(str(unit.id),40))
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			identity.add_child(name_label)
			var bar := ProgressBar.new()
			bar.custom_minimum_size.y = 8
			bar.show_percentage = false
			bar.max_value = maxf(maximum, 1.0)
			bar.value = float(unit.damage_dealt)
			var fill := StyleBoxFlat.new()
			fill.bg_color = accent
			bar.add_theme_stylebox_override("fill", fill)
			entry.add_child(bar)
			var kinds: Dictionary = unit.damage_by_kind
			entry.add_child(_wrapped_label("Zwykłe %.1f  •  Skille %.1f  •  Smród %.1f  •  Kolce %.1f" % [float(kinds.get("basic",0.0)),float(kinds.get("skill",0.0)),float(kinds.get("dot",0.0)),float(kinds.get("thorns",0.0))]))
			var life := "Przeżył: %.1f HP" % float(unit.hp) if bool(unit.survived) else "Poległ po %.1f s" % float(unit.death_time)
			var detail := _wrapped_label("Otrzymane %.1f  •  %s" % [float(unit.damage_taken),life])
			detail.add_theme_color_override("font_color", MUTED)
			entry.add_child(detail)
	buttons.add_child(_wrapped_label("[numer] = miejsce w składzie walki. Ławka nie uczestniczy. Obrażenia nie obejmują nadmiaru ponad HP; kontrola i odciąganie wrogów również mają wartość."))

# Private online: match commands are validated and applied only by the host.
func _is_online() -> bool:
	return is_instance_valid(online) and online.active and online.peer_ready

func _can_control(player: int) -> bool:
	return not network_waiting and (not _is_online() or (player == online.local_player and not command_pending))

func _request_action(kind: String, args: Array = []) -> void:
	if network_waiting or command_pending: return
	var player := model.turn_player if model.phase in ["initial_draft", "draft"] else _management_player()
	if _is_online(): player = online.local_player
	var command := {"kind": kind, "args": args, "revision": revision}
	if _is_online() and not online.is_host:
		command_pending = true
		online.send_command(command)
		_refresh()
	else:
		_receive_command(player, command)

func _receive_command(player: int, command: Dictionary) -> void:
	if _is_online() and not online.is_host: return
	if not _valid_command(command) or int(command.revision) != revision:
		_publish_state()
		return
	var kind: String = command.kind
	var args: Array = command.args
	if player < 0 or player > 1: return
	if kind in ["pick", "fuse", "pass"] and player != model.turn_player:
		_publish_state()
		return
	var changed := false
	match kind:
		"pick": changed = model.pick(args[0])
		"fuse": changed = model.fuse(args[0], args[1])
		"pass": changed = model.pass_turn()
		"discard": changed = model.discard(player, args[0])
		"toggle": changed = model.toggle_active(player, args[0])
		"swap": changed = model.swap_active(player, args[0], args[1])
		"move":
			var index: int = model._team_index_for_token(player, args[0])
			if index >= 0 and absi(args[1]) == 1:
				changed = model.move_unit(player, index, clampi(index + args[1], 0, model.teams[player].size() - 1))
		"ready", "next", "rematch":
			var expected := "prep" if kind == "ready" else "result" if kind == "next" else "match_over"
			if model.phase == expected:
				changed = true
				ready_players[player] = true
				if not _is_online() or (ready_players[0] and ready_players[1]):
					ready_players = [false, false]
					if kind == "ready": _launch_battle()
					elif kind == "next": model.next_round()
					else: _reset_match()
		"pause":
			if model.phase == "battle" and (not _is_online() or player == 0):
				arena.call("_toggle")
				changed = true
		"speed":
			if model.phase == "battle" and args[0] >= 0 and args[0] < 4 and (not _is_online() or player == 0):
				arena.set("speed", [0.5, 1.0, 2.0, 4.0][args[0]])
				changed = true
	if changed:
		revision += 1
		if kind in ["pick", "fuse", "discard", "pass", "next", "rematch"]: selected_tokens[player].clear()
		if kind in ["discard", "toggle", "swap", "move"]: ready_players = [false, false]
		_refresh()
	_publish_state()

func _valid_command(command: Dictionary) -> bool:
	if not command.get("kind") is String or not command.get("args") is Array or not command.get("revision") is int: return false
	var sizes := {"pick": 1, "fuse": 2, "discard": 1, "pass": 0, "toggle": 1, "swap": 2, "move": 2, "ready": 0, "next": 0, "rematch": 0, "pause": 0, "speed": 1}
	if not sizes.has(command.kind) or command.args.size() != sizes[command.kind]: return false
	for arg in command.args:
		if not arg is int or absi(arg) > 100000: return false
	return true

func _publish_state() -> void:
	if not _is_online() or not online.is_host: return
	online.send_state({"match": MatchWire.capture(model), "revision": revision, "ready": ready_players.duplicate(), "summary": last_battle_summary.duplicate(true), "playing": bool(arena.get("running")), "speed": float(arena.get("speed"))})
	if model.phase == "battle": _send_combat()

func _receive_state(state: Dictionary) -> void:
	if not _is_online() or online.is_host: return
	var previous_phase: String = model.phase
	MatchWire.apply(model, state["match"])
	revision = int(state.revision)
	ready_players.assign(state.ready)
	last_battle_summary = state.summary.duplicate(true)
	command_pending = false
	if model.phase != previous_phase: selected_tokens = [[], []]
	for player in range(2):
		selected_tokens[player] = selected_tokens[player].filter(func(token: int) -> bool: return model._team_index_for_token(player, token) >= 0)
	if model.phase == "battle" and previous_phase != "battle":
		# The full match always uses B, even after a local laboratory comparison.
		arena.call("set_balance_variant", "B")
	arena.set("remote_mode", true)
	arena.set("running", bool(state.playing) if model.phase == "battle" else false)
	arena.set("speed", float(state.speed))
	arena.visible = model.phase == "battle"
	_refresh()

func _send_combat() -> void:
	if not _is_online() or not online.is_host or arena.get("sim") == null: return
	var frame: Dictionary = CombatWire.capture(arena.get("sim"))
	frame["round"] = model.round_number
	online.send_combat(frame, arena.call("drain_network_events"), bool(arena.get("running")), float(arena.get("speed")))

func _receive_combat(frame: Dictionary, events: Array, playing: bool, playback_speed: float) -> void:
	if not _is_online() or online.is_host or model.phase != "battle" or int(frame.get("round", -1)) != model.round_number: return
	arena.call("apply_remote_frame", frame, events, playing, playback_speed)

func _online_connected() -> void:
	network_waiting = false
	command_pending = false
	ready_players = [false, false]
	selected_tokens = [[], []]
	arena.set("remote_mode", not online.is_host)
	arena.set("network_capture", online.is_host)
	if online.is_host:
		_reset_match()
		revision = 0
		_publish_state()
	if is_instance_valid(network_dialog): network_dialog.hide()
	_refresh()

func _online_disconnected(reason: String) -> void:
	# Never resume the interrupted match as local play.
	network_waiting = true
	command_pending = false
	arena.set("running", false)
	arena.visible = false
	_open_network()
	_online_status(reason)
	_refresh()

func _online_status(value: String) -> void:
	if is_instance_valid(room_host_button): room_host_button.disabled = online.active
	if is_instance_valid(room_join_button): room_join_button.disabled = online.active
	if is_instance_valid(room_copy_button): room_copy_button.disabled = online.rooms.room_code.is_empty()
	if is_instance_valid(lobby_join_button): lobby_join_button.disabled = online.active
	if is_instance_valid(lobby_host_button): lobby_host_button.disabled = online.active
	if is_instance_valid(lobby_status): lobby_status.text = value
	if is_instance_valid(network_label): network_label.text = value

func _open_network() -> void:
	if lab_mode: _exit_lab()
	if not is_instance_valid(network_dialog):
		network_dialog = AcceptDialog.new()
		network_dialog.title = "Prywatny pojedynek online"
		network_dialog.min_size = Vector2i(680, 580)
		network_dialog.theme = preload("res://scripts/presentation/cartoon_art.gd").theme()
		network_dialog.get_ok_button().text = "Zamknij"
		overlay.add_child(network_dialog)
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.offset_left = 16
		scroll.offset_right = -16
		scroll.offset_top = 14
		scroll.offset_bottom = -54
		network_dialog.add_child(scroll)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 12)
		scroll.add_child(column)
		var status_panel := PanelContainer.new()
		status_panel.add_theme_stylebox_override("panel",preload("res://scripts/presentation/cartoon_art.gd").panel(Color("183e46"),Color("ffc366")))
		column.add_child(status_panel)
		lobby_status = _wrapped_label("POKÓJ ZE ZNAJOMYM\nUtwórz pokój lub wpisz kod. Bez ustawiania routera.")
		lobby_status.custom_minimum_size = Vector2(590,100)
		lobby_status.add_theme_font_size_override("font_size",19)
		lobby_status.add_theme_color_override("font_color",Color("fff1d4"))
		status_panel.add_child(lobby_status)
		column.add_child(_wrapped_label("Host tworzy nowy mecz jako Gracz A. Znajomy dołącza jako Gracz B. Obaj potrzebujecie tej samej wersji gry."))
		room_input = LineEdit.new()
		room_input.placeholder_text = "Kod pokoju, np. ABCD-EFGH-JKLM"
		room_input.max_length = 24
		room_input.text_submitted.connect(func(_value: String) -> void: _join_room())
		column.add_child(room_input)
		var room_controls := HBoxContainer.new()
		column.add_child(room_controls)
		room_host_button = _make_button("Utwórz pokój", true)
		room_host_button.pressed.connect(_host_room)
		room_controls.add_child(room_host_button)
		room_join_button = _make_button("Dołącz kodem", true)
		room_join_button.pressed.connect(_join_room)
		room_controls.add_child(room_join_button)
		room_copy_button = _make_button("Kopiuj kod", true)
		room_copy_button.disabled = true
		room_copy_button.pressed.connect(func() -> void: DisplayServer.clipboard_set(online.rooms.display_code()))
		room_controls.add_child(room_copy_button)
		var room_problem: String = online.rooms.configuration_error()
		if not room_problem.is_empty():
			column.add_child(_wrapped_label(room_problem))
		var direct_toggle := _make_button("Połączenie po IP / sieć lokalna ▾", true)
		column.add_child(direct_toggle)
		var direct := VBoxContainer.new()
		direct.hide()
		column.add_child(direct)
		direct_toggle.pressed.connect(func() -> void: direct.visible = not direct.visible)
		address_input = LineEdit.new()
		address_input.placeholder_text = "Adres IP hosta (np. 192.168.1.20)"
		address_input.text = ""
		address_input.text_submitted.connect(func(_value: String) -> void: _join_online())
		direct.add_child(address_input)
		var port_row := HBoxContainer.new()
		direct.add_child(port_row)
		port_row.add_child(_plain_label("Port UDP:"))
		port_input = SpinBox.new()
		port_input.min_value = 1024
		port_input.max_value = 65535
		port_input.value = 24567
		port_row.add_child(port_input)
		var controls := HBoxContainer.new()
		direct.add_child(controls)
		var host_button := _make_button("Utwórz mecz", true)
		lobby_host_button = host_button
		host_button.pressed.connect(_host_online)
		controls.add_child(host_button)
		var join_button := _make_button("Dołącz", true)
		lobby_join_button = join_button
		join_button.pressed.connect(_join_online)
		controls.add_child(join_button)
		var local_button := _make_button("Rozłącz / nowy lokalny", true)
		local_button.pressed.connect(_return_local)
		column.add_child(local_button)
		direct.add_child(_wrapped_label("Przez internet host musi udostępnić port UDP w routerze i zezwolić grze w zaporze. Za CGNAT bez dostępnego portu bezpośrednie połączenie nie zadziała. W sieci lokalnej użyj lokalnego IP hosta."))
	network_dialog.popup_centered(Vector2i(740, 620))

func _host_online() -> void:
	_begin_connection()
	var error: int = online.host(int(port_input.value))
	if error != OK: lobby_status.text = "Nie udało się otworzyć portu: %s" % error_string(error)
	else:
		var addresses: Array[String] = []
		for address in IP.get_local_addresses():
			if address.contains(".") and not address.begins_with("127.") and not address.begins_with("169.254."): addresses.append(address)
		lobby_status.text = "Czekam na znajomego • port UDP %d\nAdresy tego komputera w sieci lokalnej: %s" % [int(port_input.value), ", ".join(addresses)]
	_refresh()

func _join_online() -> void:
	if online.active: return
	if address_input.text.strip_edges().is_empty():
		_online_status("BRAKUJE ADRESU IP\nWpisz adres hosta w polu poniżej, a potem kliknij Dołącz.")
		address_input.grab_focus()
		return
	_begin_connection()
	var error: int = online.join(address_input.text.strip_edges(), int(port_input.value))
	if error != OK: _online_status("NIE ROZPOCZĘTO POŁĄCZENIA: %s\nSprawdź wpisany adres IP i port." % error_string(error))
	_refresh()

func _begin_connection() -> void:
	online.leave()
	network_waiting = true
	command_pending = false
	arena.set("running", false)
	arena.visible = false

func _return_local() -> void:
	online.leave()
	network_waiting = false
	command_pending = false
	arena.set("remote_mode", false)
	arena.set("network_capture", false)
	arena.set("running", false)
	arena.visible = false
	network_dialog.hide()
	_reset_match()

func _update_online_ui() -> void:
	if not is_instance_valid(online): return
	network_button.text = "Połączenie" if _is_online() or network_waiting else "Graj online"
	if network_waiting:
		for control in buttons.find_children("*", "BaseButton", true, false): control.disabled = true
		message.show()
		message.text = "Mecz wstrzymany — otwórz Połączenie, aby dołączyć lub wrócić do gry lokalnej."
		backdrop.color.a = 1.0
		return
	if not _is_online():
		network_label.text = "Gra lokalna • obaj gracze na tym komputerze"
		return
	var me: int = online.local_player
	network_label.text = "ONLINE • grasz jako %s • %s" % [_player_name(me), "host" if online.is_host else "gość"]
	if model.phase in ["initial_draft", "draft"]:
		headline.text = "TWÓJ WYBÓR" if model.turn_player == me else "WYBIERA PRZECIWNIK"
	for control in buttons.find_children("*", "BaseButton", true, false):
		if control is Button:
			var title: String = control.text
			if title.begins_with("Info") or control.has_meta("inspect_card"): continue
			if command_pending or (model.phase in ["initial_draft", "draft"] and model.turn_player != me): control.disabled = true
			if title.begins_with("Edytuj "): control.hide()
			if title == "ROZPOCZNIJ WALKĘ" or title == "PRZEJDŹ DO NASTĘPNEGO DRAFTU" or title == "NOWY MECZ":
				control.text = "Czekam na przeciwnika…" if ready_players[me] else "GOTOWY DO WALKI" if model.phase == "prep" else "GOTOWY — DALEJ"
				control.disabled = ready_players[me] or command_pending
	if model.phase in ["prep", "result", "match_over"]:
		message.text = "Gotowość: A — %s, B — %s. Obaj zatwierdzacie przejście dalej." % ["TAK" if ready_players[0] else "czeka", "TAK" if ready_players[1] else "czeka"]
	if model.phase == "battle":
		subhead.text += "   •   ONLINE: " + _player_name(me) + (" (host)" if online.is_host else " (gość)")
		pause_button.disabled = not online.is_host
		speed_picker.disabled = not online.is_host
		pause_button.text = "Pauza" if arena.get("running") else "Wznów"
		speed_picker.select([0.5, 1.0, 2.0, 4.0].find(float(arena.get("speed"))))

func _restore_scroll(serial: int, page_y: int, team_y: Array[int]) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if serial != refresh_serial or not is_instance_valid(content_scroll): return
	content_scroll.scroll_vertical = page_y
	for index in range(mini(team_y.size(), team_scrolls.size())):
		team_scrolls[index].scroll_vertical = team_y[index]


func _host_room() -> void:
	if online.active: return
	_begin_connection()
	online.create_room()
	_refresh()

func _join_room() -> void:
	if online.active: return
	if not online.rooms.valid_code(room_input.text):
		_online_status("NIEPEŁNY KOD\nWklej cały 12-znakowy kod otrzymany od znajomego.")
		room_input.grab_focus()
		return
	_begin_connection()
	online.join_room(room_input.text)
	_refresh()
