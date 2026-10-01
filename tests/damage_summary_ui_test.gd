extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	var screen: Node = load("res://scenes/match/match.tscn").instantiate()
	root.add_child(screen)
	screen.set_physics_process(false)
	screen.arena.set_physics_process(false)
	var rosters := [["skunk","skunk","hedgehog_skunk","monkey","bear","rabbit"],["bear_monkey","skunk_rabbit","eagle","hippo","monkey","cheetah"]]
	for team in range(2):
		screen.model.teams[team] = []
		for i in range(6): screen.model.teams[team].append({"id":rosters[team][i],"active":true,"token":team*10+i})
	screen.model.phase = "prep"
	screen._start_battle()
	while screen.arena.sim.result == "running" and screen.arena.sim.time < 120: screen.arena.sim.step()
	assert(screen.arena.sim.result != "running")
	screen._physics_process(0.0)
	assert(screen.last_battle_summary.units.size() == 12)
	var saved: String = var_to_str(screen.last_battle_summary)
	screen.arena.sim.units[0].damage_dealt = -100
	assert(var_to_str(screen.last_battle_summary) == saved,"Snapshot remains independent")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert_damage_rows(screen)
	root.get_texture().get_image().save_png("user://damage_summary_round.png")
	screen.model.phase = "match_over"
	screen.model.match_winner = 0
	screen._refresh()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert_damage_rows(screen)
	root.get_texture().get_image().save_png("user://damage_summary_final.png")
	screen._new_match()
	assert(screen.last_battle_summary.is_empty())
	print("ROUND DAMAGE PASS: actual12units, independent snapshot, round/final views, newmatch reset")
	screen.queue_free()
	await process_frame
	quit()

func damage_labels(node: Node) -> Array[Label]:
	var result: Array[Label] = []
	if node is Label and node.text.contains("] • ") and node.text.contains("obrażeń"):
		result.append(node)
	for child in node.get_children(): result.append_array(damage_labels(child))
	return result

func assert_damage_rows(screen: Node) -> void:
	var labels := damage_labels(screen.buttons)
	assert(labels.size() == 12, "Every combatant, including duplicate animals, has a damage row")
	for label in labels:
		assert(label.size.y > 0.0 and label.get_parent().size.y > 0.0, "Damage entries have positive height")
		var parent := label.get_parent()
		while parent != screen.content_scroll:
			assert(not parent is ScrollContainer, "No collapsing nested scroll around unit rows")
			parent = parent.get_parent()
	var first := labels[0].get_global_rect()
	assert(screen.content_scroll.get_global_rect().intersects(first), "First unit damage is visible without scrolling")
	assert(screen.content_scroll.get_v_scroll_bar().max_value > screen.content_scroll.size.y, "Full roster remains reachable by page scrolling")
