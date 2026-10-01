extends SceneTree
## Creates and destroys one real EOS lobby. Needs local config/eos.cfg.
var service: Node
var finished := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	service = load("res://scripts/network/eos_rooms.gd").new()
	root.add_child(service)
	if not service.configuration_error().is_empty():
		print("NOT RUN: local EOS configuration is incomplete.")
		quit(2)
		return
	service.failed.connect(func(_reason: String) -> void:
		finished = true
		print("FAIL: EOS setup/login/lobby operation. Check local configuration and client policy.")
		quit(1)
	)
	service.transport_ready.connect(_created)
	service.start(true)
	create_timer(60).timeout.connect(_timeout)

func _timeout() -> void:
	if not finished:
		print("FAIL: EOS operation timed out.")
		service.cancel()
		quit(1)

func _created(_peer: MultiplayerPeer, host_role: bool) -> void:
	assert(host_role)
	assert(not service.room_code.is_empty())
	print("PASS: real EOS device login, lobby creation and native P2P server initialization.")
	_cleanup.call_deferred()

func _cleanup() -> void:
	var old_lobby: RefCounted = service.lobby
	var lobbies_api: Node = root.get_node("HLobbies")
	var matches: Variant = await lobbies_api.search_by_lobby_id_async(old_lobby.lobby_id)
	assert(matches != null and matches.size() == 1)
	assert(matches[0].lobby_id == old_lobby.lobby_id)
	for result in matches:
		service._release_lobby_view(result)
	print("PASS: room is discoverable by its code.")
	await service.cancel()
	assert(not old_lobby.is_valid())
	old_lobby = null
	service.queue_free()
	service = null
	await process_frame
	finished = true
	print("EOS smoke completed. A second computer is still needed to verify joining and relay.")
	quit()
