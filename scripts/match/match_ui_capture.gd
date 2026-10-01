extends SceneTree

const MatchScene = preload("res://scenes/match/match.tscn")
const OUTPUT_DIR := "C:/Users/gorsk/OneDrive/Dokumenty/kimoz/reports"

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func() -> void: push_error("Match UI capture timed out"); quit(1))
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var screen: Node = MatchScene.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	await _capture("match_initial.png")
	var lab_button := _find_button(screen, "Combat Lab")
	_assert(lab_button != null, "Combat Lab navigation button exists")
	lab_button.emit_signal("pressed")
	_assert(screen.arena.visible and screen.arena.get("hud").visible, "Combat Lab button opens the lab")
	var lab_start := _find_button(screen, "Start")
	_assert(lab_start != null, "Combat Lab start control is visible")
	lab_start.emit_signal("pressed")
	_assert(screen.arena.get("running"), "Combat Lab can run independently")
	var return_button := _find_button(screen, "← Powrót do meczu")
	_assert(return_button != null, "Lab offers a return button")
	return_button.emit_signal("pressed")
	_assert(not screen.arena.visible, "return button closes the lab")
	_assert(not screen.arena.get("running"), "leaving Combat Lab pauses its simulation")
	for _pick in range(4):
		var offers_row := _find_offers_row(screen)
		_assert(offers_row != null and offers_row.get_child_count() > 0, "shared offer cards are visible")
		if offers_row == null or offers_row.get_child_count() == 0:
			quit(1)
			return
		offers_row.get_child(0).emit_signal("pressed")
		await process_frame
	_assert(screen.model.phase == "prep", "clicking four real offer cards opens preparation")
	screen.model.teams[0].append({"id": "rabbit", "active": false, "token": 999})
	screen.call("_refresh")
	await process_frame
	var reserve_card := _find_button_containing(screen, "REZERWA")
	_assert(reserve_card != null, "bench units are selectable in preparation")
	reserve_card.emit_signal("pressed")
	await process_frame
	var toggle_button := _find_button(screen, "Aktywna / rezerwa")
	_assert(toggle_button != null and not toggle_button.disabled, "selected unit can change active or reserve status")
	toggle_button.emit_signal("pressed")
	await process_frame
	_assert(screen.model.active_count(0) == 3, "preparation click promotes the selected reserve")
	await _capture("match_prep.png")
	var start_button := _find_button(screen, "ROZPOCZNIJ WALKĘ")
	_assert(start_button != null and not start_button.disabled, "preparation exposes a valid start button")
	start_button.emit_signal("pressed")
	await process_frame
	await process_frame
	_assert(screen.model.phase == "battle", "start button launches combat")
	_assert(screen.arena.get("sim").result == "running", "combat uses a fresh running simulation")
	_assert(screen.lab_button.disabled, "Lab entry is disabled while match combat runs")
	await _capture("match_battle.png")
	# Return through the round-result control, then exercise a known legal draft pair.
	screen.model.phase = "result"
	screen.call("_refresh")
	await process_frame
	var next_draft := _find_button(screen, "PRZEJDŹ DO NASTĘPNEGO DRAFTU")
	_assert(next_draft != null, "round result offers a return to draft")
	if next_draft == null:
		quit(1)
		return
	next_draft.emit_signal("pressed")
	await process_frame
	await process_frame
	screen.model.turn_player = 0
	screen.model.actions_left[0] = 1
	screen.model.actions_left[1] = 0
	screen.model.offers.clear()
	screen.model.offers.append("rabbit")
	screen.model.teams[0] = [
		{"id": "bear", "active": true, "token": 1001},
		{"id": "cheetah", "active": false, "token": 1002},
	]
	screen.call("_refresh")
	await process_frame
	var bear_card := _find_button_containing(screen, screen.call("_unit_name", "bear"))
	_assert(bear_card != null, "draft player can select an owned unit")
	bear_card.emit_signal("pressed")
	await process_frame
	await process_frame
	await _capture("match_draft_partner_highlight.png")
	var cheetah_card := _find_button_containing(screen, screen.call("_unit_name", "cheetah"))
	_assert(cheetah_card != null, "draft player can select a compatible bench unit")
	var cheetah_style: StyleBox = cheetah_card.get_theme_stylebox("normal")
	_assert(cheetah_style is StyleBoxFlat and (cheetah_style as StyleBoxFlat).border_width_left > 0, "compatible bench partner is visibly highlighted")
	cheetah_card.emit_signal("pressed")
	await process_frame
	await process_frame
	await _capture("match_draft_fusion_preview.png")
	_assert(str(screen.message.text).contains("→") and str(screen.message.text).contains("Niedźwiedź-Gepard"), "fusion preview names parents and hybrid")
	var fuse_button := _find_button_containing(screen, "Połącz →")
	_assert(fuse_button != null and not fuse_button.disabled, "compatible result is shown before fusion")
	if fuse_button == null:
		quit(1)
		return
	_assert(fuse_button.text.contains(screen.call("_unit_name", "bear_cheetah")), "button names the resulting hybrid")
	fuse_button.emit_signal("pressed")
	_assert(screen.model.teams[0].size() == 1 and screen.model.teams[0][0].id == "bear_cheetah", "fusion button consumes parents and creates the hybrid")
	_assert(screen.selected_tokens[0].is_empty(), "fusion clears selection on the actor who chose it")
	if failure_count > 0:
		quit(1)
		return
	print("MATCH_UI_CAPTURE_OK reports/match_initial.png reports/match_prep.png reports/match_battle.png reports/match_draft_partner_highlight.png reports/match_draft_fusion_preview.png")
	quit(0)

var failure_count := 0

func _find_button(node: Node, value: String) -> Button:
	if node is Button and not node.is_queued_for_deletion() and node.is_visible_in_tree() and node.text == value: return node
	for child in node.get_children():
		var found := _find_button(child, value)
		if found != null: return found
	return null

func _find_button_containing(node: Node, value: String) -> Button:
	if node is Button and not node.is_queued_for_deletion() and node.is_visible_in_tree() and node.text.contains(value): return node
	for child in node.get_children():
		var found := _find_button_containing(child, value)
		if found != null: return found
	return null

func _find_offers_row(node: Node) -> HBoxContainer:
	if node is HBoxContainer and node.get_child_count() > 0:
		var has_offer := false
		for child in node.get_children():
			if child is Button and child.text.contains("Poziom 1"):
				has_offer = true
				break
		if has_offer: return node
	for child in node.get_children():
		var found := _find_offers_row(child)
		if found != null: return found
	return null

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var result := image.save_png(OUTPUT_DIR + "/" + filename)
	_assert(result == OK, "screenshot saves: " + filename)

func _assert(condition: bool, description: String) -> void:
	if not condition:
		failure_count += 1
		push_error("Match UI capture failed: " + description)
