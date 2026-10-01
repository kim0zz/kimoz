extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var screen: Node = load("res://scenes/match/match.tscn").instantiate()
	root.add_child(screen)
	screen.set_physics_process(false)
	screen.model.begin_match(7)
	var owner: int = screen.model.turn_player
	var command := {"kind": "pick", "args": [0], "revision": screen.revision}
	screen._receive_command(1 - owner, command)
	assert(screen.model.owned_count(1 - owner) == 0, "Opponent cannot choose out of turn")
	screen._receive_command(owner, command)
	assert(screen.model.owned_count(owner) == 1)
	screen._receive_command(screen.model.turn_player, command)
	assert(screen.model.next_token == 2, "Stale/replayed decision cannot consume another action")
	assert(not screen._valid_command({"kind": "fuse", "args": [1], "revision": 1}))
	assert(not screen._valid_command({"kind": "pick", "args": ["1"], "revision": 1}))
	screen.model.phase = "prep"
	screen.model.teams = [[{"id":"bear", "active":true,"token":1},{"id":"cheetah","active":true,"token":2}], [{"id":"monkey","active":true,"token":3}]]
	screen._receive_command(1, {"kind":"discard","args":[1],"revision":screen.revision})
	assert(screen.model.teams[0].size() == 2, "Cannot discard opponent's token")
	screen._receive_command(1, {"kind":"toggle","args":[1],"revision":screen.revision})
	assert(screen.model.teams[0][0].active, "Cannot bench opponent's token")
	var wire = load("res://scripts/network/match_wire.gd")
	var copy = load("res://scripts/match/match_model.gd").new()
	wire.apply(copy, bytes_to_var(var_to_bytes(wire.capture(screen.model))))
	assert(wire.capture(copy) == wire.capture(screen.model), "Typed state roundtrip")
	copy.teams[0][0].active = false
	assert(screen.model.teams[0][0].active, "Snapshot has no shared mutable state")
	# A previous local laboratory variant must not leak into guest presentation.
	screen.arena.set_balance_variant("A")
	screen.online.active = true
	screen.online.peer_ready = true
	screen.online.is_host = false
	screen.online.local_player = 1
	var incoming: Dictionary = wire.capture(screen.model)
	incoming.phase = "battle"
	screen._receive_state({"match":incoming,"revision":7,"ready":[false,false],"summary":{},"playing":true,"speed":1.0})
	assert(screen.arena.balance_variant == "B" and screen.arena.remote_mode, "Guest always uses full-match B")
	screen.online.active = false
	print("ONLINE COMMANDS PASS: ownership, replay, malformed input, typed state, independent snapshot")
	screen.queue_free()
	await process_frame
	quit()
