extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	var screen: Node=load("res://scenes/match/match.tscn").instantiate()
	root.add_child(screen)
	screen._open_network()
	screen._join_online()
	assert(screen.lobby_status.text.contains("BRAKUJE"))
	assert(not screen.online.active)
	screen.address_input.text="192.0.2.1"
	screen._join_online()
	assert(screen.online.active)
	assert(screen.lobby_status.text.contains("ŁĄCZENIE"))
	assert(screen.lobby_join_button.disabled)
	screen.online._process(3.0)
	assert(screen.lobby_status.text.contains("3 / 10"))
	screen.online._process(7.1)
	assert(not screen.online.active)
	assert(screen.lobby_status.text.contains("Host nie odpowiedział"))
	assert(not screen.lobby_join_button.disabled)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/network-feedback.png")
	screen._join_online()
	assert(screen.online.active)
	screen.online.leave()
	print("PASS: blank address, immediate status, countdown, timeout, retry, rendered error panel")
	quit()
