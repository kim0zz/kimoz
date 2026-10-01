extends SceneTree

const Chunks = preload("res://scripts/network/packet_chunks.gd")
const Session = preload("res://scripts/network/online_session.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var assembler := Chunks.new()
	var original := Crypto.new().generate_random_bytes(90000)
	var packed := original.compress(FileAccess.COMPRESSION_DEFLATE)
	var count := ceili(float(packed.size()) / Chunks.CHUNK_BYTES)
	var result: Dictionary
	for index in count:
		result = assembler.accept(2, index, count, original.size(), packed.slice(index * Chunks.CHUNK_BYTES, (index + 1) * Chunks.CHUNK_BYTES))
		if index < count - 1: assert(result.is_empty())
	assert(result.bytes == original)
	assert(assembler.accept(2, 1, 2, 1000, PackedByteArray([1])).has("error"))
	assert(assembler.accept(2, 0, 100000, 1000, PackedByteArray([1])).has("error"))
	assert(assembler.accept(2, 0, 1, 999999999, PackedByteArray([1])).has("error"))
	assert(assembler.accept(99, 0, 1, 100, PackedByteArray([1])).has("error"))
	var rooms_script: Script = load("res://scripts/network/eos_rooms.gd")
	assert(rooms_script.valid_code("abcd-efgh-jklm"))
	assert(not rooms_script.valid_code("ABCD"))
	assert(not rooms_script.valid_code("ABCD-EFGH-I0O1"))
	for iteration in 100:
		assert(rooms_script.valid_code(rooms_script._new_code()))
	# Full compressed >1-packet payload through Godot RPCs with authority checks.
	var roots: Array[Node] = []
	var sessions: Array[Node] = []
	for index in 2:
		var branch := Node.new()
		branch.name = "ChunkTest" + str(index)
		root.add_child(branch)
		set_multiplayer(MultiplayerAPI.create_default_interface(), branch.get_path())
		var session := Session.new()
		session.name = "Session"
		branch.add_child(session)
		session.use_fragmentation = true
		roots.append(branch)
		sessions.append(session)
	var host: Node = sessions[0]
	var guest: Node = sessions[1]
	var probe := TCPServer.new()
	assert(probe.listen(0) == OK)
	var port := probe.get_local_port()
	probe.stop()
	assert(host.host(port) == OK)
	assert(guest.join("127.0.0.1", port) == OK)
	var deadline := Time.get_ticks_msec() + 5000
	while not (host.peer_ready and guest.peer_ready) and Time.get_ticks_msec() < deadline:
		await create_timer(0.01).timeout
	assert(host.peer_ready and guest.peer_ready)
	var payload: Array = []
	for index in 900:
		payload.append(Vector2(randf(), randf()))
	var received := {"state": false, "combat": false, "order": []}
	guest.state_received.connect(func(state: Dictionary) -> void:
		received.state = state.positions == payload
		received.order.append("state")
	)
	guest.combat_received.connect(func(frame: Dictionary, _events: Array, _playing: bool, _speed: float) -> void:
		received.combat = frame.positions == payload
		received.order.append("combat")
	)
	host.send_state({"positions": payload})
	host.send_combat({"positions": payload}, [], true, 1.0)
	deadline = Time.get_ticks_msec() + 5000
	while not received.combat and Time.get_ticks_msec() < deadline:
		await create_timer(0.01).timeout
	assert(received.state and received.combat)
	assert(received.order == ["state", "combat"])
	host.leave()
	guest.leave()
	print("PASS: EOS room codes, bounded fragments, large RPC payloads, state/combat ordering. No live EOS connection tested.")
	quit()
