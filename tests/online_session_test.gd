extends SceneTree

const Session = preload("res://scripts/network/online_session.gd")

class MismatchGuest:
	extends "res://scripts/network/online_session.gd"

	func _fingerprint() -> String:
		return "incompatible-test-build"


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var results := {
		"host_connected": false,
		"guest_connected": false,
		"command": false,
		"state": false,
		"combat": false,
	}
	var port := _available_port()
	if port < 1:
		_fail("Could not reserve a local ENet test port.")
		return
	var pair := _make_pair("OnlineTest", Session)
	var host: ZooOnlineSession = pair.host
	var guest: ZooOnlineSession = pair.guest
	host.connected_match.connect(func() -> void: results.host_connected = true)
	guest.connected_match.connect(func() -> void: results.guest_connected = true)
	host.command_received.connect(func(player: int, command: Dictionary) -> void:
		results.command = player == 1 and command.get("revision") is int and command.revision == 7 and command.args == [4, 9]
		host.send_state({"revision": command.revision, "teams": [{"tokens": [4, 9]}]})
		host.send_combat({"position": Vector2(3.5, -2.0)}, [{0: Vector2(1.25, 8.5), "kind": "impact"}], true, 2.0)
	)
	guest.state_received.connect(func(state: Dictionary) -> void:
		results.state = state.get("revision") is int and state.revision == 7 and state.teams[0].tokens == [4, 9]
	)
	guest.combat_received.connect(func(frame: Dictionary, events: Array, playing: bool, speed: float) -> void:
		var event: Dictionary = events[0] if not events.is_empty() else {}
		results.combat = frame.get("position") is Vector2 and frame.position == Vector2(3.5, -2.0) and event.get(0) is Vector2 and event[0] == Vector2(1.25, 8.5) and playing and is_equal_approx(speed, 2.0)
	)
	await process_frame
	if host.host(port) != OK or guest.join("127.0.0.1", port) != OK:
		_fail("Could not start the two ENet sessions.")
		return
	if not await _wait_for_both(results, 4.0):
		_fail("Compatible peers did not finish the handshake.")
		return
	guest.send_command({"kind": "swap", "args": [4, 9], "revision": 7})
	if not await _wait_for_payloads(results, 4.0):
		_fail("Command/state/combat transport did not preserve their Variant types.")
		return
	host.leave()
	guest.leave()
	await process_frame
	
	var mismatch_results := {"host_disconnected": false, "guest_disconnected": false, "guest_reason": ""}
	port = _available_port()
	if port < 1:
		_fail("Could not reserve a mismatch test port.")
		return
	var mismatch_pair := _make_pair("MismatchTest", MismatchGuest, Session)
	host = mismatch_pair.host
	guest = mismatch_pair.guest
	host.disconnected.connect(func(_reason: String) -> void: mismatch_results.host_disconnected = true)
	guest.disconnected.connect(func(reason: String) -> void:
		mismatch_results.guest_disconnected = true
		mismatch_results.guest_reason = reason
	)
	await process_frame
	if host.host(port) != OK or guest.join("127.0.0.1", port) != OK:
		_fail("Could not start the mismatch ENet sessions.")
		return
	if not await _wait_for_mismatch(mismatch_results, 4.0) or not str(mismatch_results.guest_reason).contains("Wersja gry"):
		_fail("An incompatible peer was not rejected with a disconnect.")
		return
	host.leave()
	guest.leave()
	print("OK: online session handshake, typed packets, and incompatibility rejection.")
	quit(0)


func _make_pair(prefix: String, host_script: Script, guest_script: Script = null) -> Dictionary:
	var host_root := Node.new()
	host_root.name = prefix + "HostRoot"
	var guest_root := Node.new()
	guest_root.name = prefix + "GuestRoot"
	root.add_child(host_root)
	root.add_child(guest_root)
	var host_api := MultiplayerAPI.create_default_interface()
	var guest_api := MultiplayerAPI.create_default_interface()
	set_multiplayer(host_api, host_root.get_path())
	set_multiplayer(guest_api, guest_root.get_path())
	var host_session := _add_session(host_root, host_script)
	var guest_session := _add_session(guest_root, guest_script if guest_script != null else host_script)
	return {"host": host_session, "guest": guest_session}


func _add_session(parent: Node, session_script: Script) -> ZooOnlineSession:
	var match_root := Node.new()
	match_root.name = "Match"
	parent.add_child(match_root)
	var session := session_script.new() as ZooOnlineSession
	session.name = "OnlineSession"
	match_root.add_child(session)
	# Exercise EOS-sized framing through a real local transport without EOS credentials.
	session.use_fragmentation = OS.get_cmdline_user_args().has("--chunks")
	return session


func _available_port() -> int:
	var probe := TCPServer.new()
	if probe.listen(0) != OK:
		return -1
	var port := probe.get_local_port()
	probe.stop()
	return port


func _wait_for_both(results: Dictionary, timeout: float) -> bool:
	return await _wait_for(results, ["host_connected", "guest_connected"], timeout)


func _wait_for_payloads(results: Dictionary, timeout: float) -> bool:
	return await _wait_for(results, ["command", "state", "combat"], timeout)


func _wait_for_mismatch(results: Dictionary, timeout: float) -> bool:
	return await _wait_for(results, ["host_disconnected", "guest_disconnected"], timeout)


func _wait_for(results: Dictionary, keys: Array, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		var complete := true
		for key: String in keys:
			complete = complete and bool(results.get(key, false))
		if complete:
			return true
		await create_timer(0.01).timeout
		elapsed += 0.01
	return false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
