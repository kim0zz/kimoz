extends SceneTree
## Run two OS processes: --script res://tests/online_match_test.gd -- host|guest.
var screen: Node
var role := "host"
var elapsed := 0.0
var action_delay := 0.0
var seen_results: Dictionary = {}
var tested_pause := false
var tested_fusion := false
var frames_seen := 0
var connected := false
var leaving := false
var reached_end := false
var rematched := false
var captured_combat := false
var captured_result := false
var prep_stage := 0
var errors: Array[String] = []
func _initialize() -> void:
	role = OS.get_cmdline_user_args()[0]
	call_deferred("start")
func start() -> void:
	root.size = Vector2i(1280, 720)
	screen = load("res://scenes/match/match.tscn").instantiate()
	root.add_child(screen)
	if not screen.has_method("_open_network"):
		quit(1)
		return
	screen._open_network()
	screen.port_input.value = 24678
	screen.address_input.text = "127.0.0.1"
	screen.online.connected_match.connect(on_connected)
	screen.online.combat_received.connect(func(_f: Dictionary, _e: Array, _p: bool, _s: float) -> void: frames_seen += 1)
	if role == "host": screen._host_online()
	else: screen._join_online()
	screen.online.use_fragmentation = OS.get_cmdline_user_args().has("--chunks")
func _process(delta: float) -> bool:
	if screen == null: return false
	elapsed += delta
	action_delay += delta
	if elapsed > 90:
		push_error("ONLINE TIMEOUT %s phase=%s connected=%s" % [role, screen.model.phase, connected])
		quit(1)
		return false
	if role == "guest" and connected and not screen.online.active:
		check(screen.network_waiting and not screen.arena.running, "Disconnect aborts play")
		check(seen_results.size() >= 2 and frames_seen > 20 and rematched, "Rounds, streamed frames and rematch")
		finish()
		return false
	if not screen._is_online() or screen.network_waiting or screen.command_pending or action_delay < 0.12: return false
	action_delay = 0.0
	var me: int = screen.online.local_player
	match screen.model.phase:
		"initial_draft", "draft":
			if reached_end:
				rematched = true
				check(screen.last_battle_summary.is_empty(), "Rematch clears summary")
				if role == "host" and not leaving:
					leaving = true
					call_deferred("leave_after_result")
				return false
			if screen.model.turn_player != me: return false
			if screen.model.phase == "draft" and not tested_fusion:
				var owned: Array = screen.model.teams[me]
				for left in owned:
					for right in owned:
						if not screen.model.compatible_pair(left.id, right.id).is_empty():
							screen._request_action("fuse", [left.token, right.token])
							tested_fusion = true
							return false
			var preferred := ["bear", "cheetah"] if me == 0 else ["monkey", "hippo"]
			var pick := 0
			for id in preferred:
				if screen.model.offers.has(id):
					pick = screen.model.offers.find(id)
					break
			screen._pick_offer(pick)
		"prep":
			if prep_stage < 3:
				var token: int = screen.model.teams[me][0].token
				if prep_stage < 2: screen._request_action("toggle", [token])
				else: screen._request_action("move", [token, 1])
				prep_stage += 1
				return false
			if not screen.ready_players[me]: screen._start_battle()
		"battle":
			if not captured_combat and screen.arena.sim.time > 3.0:
				captured_combat = true
				check(screen.arena.views.size() == screen.arena.sim.units.size(), "No stale unit views")
				capture.call_deferred("combat")
			if role == "host" and float(screen.arena.speed) != 4.0: screen._set_speed(3)
		"result", "match_over":
			if not captured_result:
				captured_result = true
				capture.call_deferred("result")
			var round_id: int = screen.last_battle_summary.round
			if not seen_results.has(round_id):
				seen_results[round_id] = screen.last_battle_summary.duplicate(true)
				print("ONLINE_RESULT %s %s" % [role, JSON.stringify(screen.last_battle_summary)])
				check(not screen.last_battle_summary.units.is_empty(), "Per-animal damage delivered")
			if screen.model.phase == "match_over":
				reached_end = true
				if not screen.ready_players[me]: screen._new_match()
			elif not screen.ready_players[me]: screen._next_round()
	return false
func on_connected() -> void:
	connected = true
	if role == "host":
		# Shorten this transport regression only, without altering game balance.
		screen.model.lives.assign([2, 2])
		screen._publish_state()
func leave_after_result() -> void:
	await create_timer(1.0).timeout
	screen.online.leave()
	finish()
func check(value: bool, label: String) -> void:
	if not value: errors.append(label)
func finish() -> void:
	check(tested_fusion, "Fusion submitted")
	var report := {"role": role, "errors": errors, "rounds": seen_results, "frames": frames_seen}
	var file := FileAccess.open("user://online_test_%s.json" % role, FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	print("ONLINE MATCH %s %s" % [role, "PASS" if errors.is_empty() else str(errors)])
	screen.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://online_%s_%s.png" % [role, label])
