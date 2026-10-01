class_name ZooOnlineSession
extends Node

## A small ENet session layer for two peers. Gameplay authority stays in the
## match controller; packets use bounded Variant serialization with objects disabled.

signal connected_match()
signal disconnected(reason: String)
signal status_changed(text: String)
signal command_received(player: int, command: Dictionary)
signal state_received(state: Dictionary)
signal combat_received(frame: Dictionary, events: Array, playing: bool, speed: float)

## Bump this identifier when gameplay resources, match packets, or simulation rules
## change. Runtime script source is not reliably available in exported builds.
const PROTOCOL_FINGERPRINT := "kimoz-match-v5-eos-rooms-rabbit-shield-2026-09-27"
const HANDSHAKE_TIMEOUT_SECONDS := 10.0
const Chunks = preload("res://scripts/network/packet_chunks.gd")
const WIRE_METHODS := ["_rpc_handshake", "_rpc_command", "_rpc_state", "_rpc_combat"]
var rooms: Node
var use_fragmentation := false
var _chunks := Chunks.new()
var _chunk_elapsed := 0.0
const MAX_PACKET_BYTES := 131072
const MAX_COMMAND_KEYS := 32
const MAX_CONTAINER_ITEMS := 1024
const MAX_VALUE_DEPTH := 10
const MAX_STRING_BYTES := 8192
const MAX_COMBAT_EVENTS := 512
const HOST_PEER_ID := 1
const REJECT_NOTICE_GRACE_SECONDS := 0.2

var connection_target := ""
var transport_connected := false
var _status_second := -1
var active: bool = false
var is_host: bool = false
var local_player: int = -1
var peer_ready: bool = false

var _handshake_elapsed: float = 0.0
var _handshake_in_progress: bool = false
var _handshake_hello_received: bool = false
var _reject_notice_pending: bool = false
var _reject_notice_elapsed: float = 0.0
var _reject_notice_reason: String = ""
var _expected_peer_id: int = 0
var _session_connected_emitted: bool = false


func _ready() -> void:
	# Load after autoloads exist, also when started by a SceneTree test script.
	rooms = load("res://scripts/network/eos_rooms.gd").new()
	add_child(rooms)
	rooms.status_changed.connect(func(value: String) -> void: status_changed.emit(value))
	rooms.failed.connect(_room_failed)
	rooms.transport_ready.connect(_room_transport_ready)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(delta: float) -> void:
	if _chunks.expected_index > 0:
		_chunk_elapsed += delta
		if _chunk_elapsed > 15.0:
			_abort("Nie udało się odebrać pełnych danych meczu.")
			return
	if active and _reject_notice_pending:
		_reject_notice_elapsed += delta
		if _reject_notice_elapsed >= REJECT_NOTICE_GRACE_SECONDS:
			_abort(_reject_notice_reason)
		return
	if not active or peer_ready or not _handshake_in_progress:
		return
	_handshake_elapsed += delta
	if not is_host and not transport_connected and not use_fragmentation:
		var second := int(_handshake_elapsed)
		if second != _status_second:
			_status_second = second
			status_changed.emit("ŁĄCZENIE z %s • %d / 10 s\nPróba trwa — czekam na odpowiedź hosta." % [connection_target,second])
	if _handshake_elapsed >= (30.0 if use_fragmentation else HANDSHAKE_TIMEOUT_SECONDS):
		_abort("Host odpowiedział, ale nie ukończył sprawdzania wersji gry. Uruchomcie tę samą paczkę i spróbujcie ponownie." if transport_connected or is_host else _unreachable_reason())


func host(port: int) -> Error:
	if active:
		return ERR_ALREADY_IN_USE
	if port < 1 or port > 65535:
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, 1, 2)
	if error != OK:
		return error
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	_begin_session(peer, true)
	local_player = 0
	status_changed.emit("Oczekiwanie na drugiego gracza…")
	return OK


func join(address: String, port: int) -> Error:
	if active:
		return ERR_ALREADY_IN_USE
	if address.strip_edges().is_empty() or port < 1 or port > 65535:
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address.strip_edges(), port, 2)
	if error != OK:
		return error
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	_begin_session(peer, false)
	local_player = 1
	connection_target = "%s:%d (UDP)" % [address.strip_edges(),port]
	status_changed.emit("ŁĄCZENIE z %s • 0 / 10 s\nPróba trwa — czekam na odpowiedź hosta." % connection_target)
	return OK


## Intentional leave is silent on disconnected(); callers already know they left.
func leave() -> void:
	# Stop callbacks before closing a peer, which can emit disconnection synchronously.
	active = false
	_chunks.clear()
	use_fragmentation = false
	if is_instance_valid(rooms):
		rooms.cancel()
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	active = false
	transport_connected = false
	_status_second = -1
	is_host = false
	local_player = -1
	peer_ready = false
	_handshake_elapsed = 0.0
	_handshake_in_progress = false
	_handshake_hello_received = false
	_reject_notice_pending = false
	_reject_notice_elapsed = 0.0
	_reject_notice_reason = ""
	_expected_peer_id = 0
	_session_connected_emitted = false
	status_changed.emit("Offline")


## Guest submits a player decision to the host using the reliable control channel.
func send_command(command: Dictionary) -> void:
	if not _is_ready_guest() or command.is_empty() or not _valid_dictionary(command, MAX_COMMAND_KEYS, false):
		return
	var packet_text := _encode_packet({"command": command})
	if not packet_text.is_empty():
		_send_wire("_rpc_command", HOST_PEER_ID, packet_text)


## Host sends the authoritative match state to the guest.
func send_state(state: Dictionary) -> void:
	if not _is_ready_host() or not _valid_dictionary(state, MAX_CONTAINER_ITEMS):
		return
	var packet_text := _encode_packet({"state": state})
	if not packet_text.is_empty():
		_send_wire("_rpc_state", _expected_peer_id, packet_text)


## Host sends an authoritative presentation frame on the same reliable channel
## as match state, preserving event delivery order across phase changes.
func send_combat(frame: Dictionary, events: Array, playing: bool, speed: float) -> void:
	if not _is_ready_host():
		return
	if not _valid_dictionary(frame, MAX_CONTAINER_ITEMS) or events.size() > MAX_COMBAT_EVENTS:
		return
	if not _valid_value(events, 0) or not _valid_number(speed) or speed < 0.0 or speed > 8.0:
		return
	var packet_text := _encode_packet({
		"frame": frame,
		"events": events,
		"playing": playing,
		"speed": speed,
	})
	if not packet_text.is_empty():
		_send_wire("_rpc_combat", _expected_peer_id, packet_text)


func _begin_session(peer: MultiplayerPeer, host_role: bool) -> void:
	multiplayer.multiplayer_peer = peer
	active = true
	is_host = host_role
	local_player = 0 if host_role else 1
	peer_ready = false
	_handshake_elapsed = 0.0
	_handshake_in_progress = not host_role
	_handshake_hello_received = false
	_expected_peer_id = 0
	_session_connected_emitted = false


func _on_peer_connected(peer_id: int) -> void:
	if not active or not is_host:
		return
	if _expected_peer_id != 0 or peer_id == HOST_PEER_ID:
		var peer := multiplayer.multiplayer_peer
		if peer != null:
			peer.disconnect_peer(peer_id, true)
		return
	_expected_peer_id = peer_id
	multiplayer.multiplayer_peer.refuse_new_connections = true
	_handshake_elapsed = 0.0
	transport_connected = true
	_handshake_in_progress = true
	status_changed.emit("HOST ODPOWIEDZIAŁ • sprawdzanie wersji gry…")


func _on_connected_to_server() -> void:
	if not active or is_host:
		return
	_handshake_elapsed = 0.0
	transport_connected = true
	_handshake_in_progress = true
	status_changed.emit("HOST ODPOWIEDZIAŁ • sprawdzanie wersji gry…")
	_send_wire("_rpc_handshake", HOST_PEER_ID, _encode_packet({"kind": "hello", "fingerprint": _fingerprint()}))


func _on_peer_disconnected(peer_id: int) -> void:
	if not active:
		return
	if is_host and peer_id == _expected_peer_id:
		_abort("Drugi gracz rozłączył się.")


func _on_connection_failed() -> void:
	if active and not is_host:
		_abort(_unreachable_reason())


func _on_server_disconnected() -> void:
	if active and not is_host:
		_abort("Host rozłączył się.")


@rpc("any_peer", "call_remote", "reliable")
func _rpc_handshake(packet_bytes: PackedByteArray) -> void:
	if not active:
		return
	var sender := multiplayer.get_remote_sender_id()
	var packet := _decode_packet(packet_bytes)
	if packet.is_empty():
		_abort("Otrzymano nieprawidłowy pakiet uzgadniania.")
		return
	var kind: String = str(packet.get("kind", ""))
	if is_host:
		if sender != _expected_peer_id or sender == 0:
			_abort("Nieautoryzowany lub nieoczekiwany pakiet uzgadniania.")
			return
		if kind not in ["hello", "ack"]:
			_abort("Nieoczekiwany pakiet uzgadniania.")
			return
		if packet.get("fingerprint", "") != _fingerprint():
			_reject_remote(sender, "Wersja gry hosta i gościa jest niezgodna.")
			return
		if kind == "hello":
			_handshake_hello_received = true
			_send_wire("_rpc_handshake", sender, _encode_packet({"kind": "ready", "fingerprint": _fingerprint()}))
			status_changed.emit("Wersja zgodna, kończenie połączenia…")
			return
		if not _handshake_hello_received:
			_abort("Pakiet gotowości gościa pojawił się poza kolejnością.")
			return
		_send_wire("_rpc_handshake", sender, _encode_packet({"kind": "confirm", "fingerprint": _fingerprint()}))
		_mark_peer_ready()
		return

	if sender != HOST_PEER_ID:
		_abort("Pakiet uzgadniania pochodzi od nieznanego gracza.")
		return
	if kind == "ready":
		if packet.get("fingerprint", "") != _fingerprint():
			_abort("Wersja gry hosta i gościa jest niezgodna.")
			return
		_send_wire("_rpc_handshake", HOST_PEER_ID, _encode_packet({"kind": "ack", "fingerprint": _fingerprint()}))
		return
	if kind == "confirm":
		if packet.get("fingerprint", "") != _fingerprint():
			_abort("Wersja gry hosta i gościa jest niezgodna.")
			return
		_mark_peer_ready()
		return
	if kind == "reject":
		_abort(str(packet.get("reason", "Host odrzucił połączenie.")))
		return
	_abort("Nieoczekiwany pakiet uzgadniania od hosta.")


@rpc("any_peer", "call_remote", "reliable")
func _rpc_command(packet_bytes: PackedByteArray) -> void:
	if not active:
		return
	if not is_host:
		_abort("Gość otrzymał komendę w niewłaściwym kierunku.")
		return
	if not peer_ready:
		_abort("Komenda pojawiła się przed zakończeniem uzgadniania.")
		return
	if multiplayer.get_remote_sender_id() != _expected_peer_id:
		_abort("Nieautoryzowany nadawca komendy.")
		return
	var packet := _decode_packet(packet_bytes)
	var command: Variant = packet.get("command")
	if packet.is_empty() or not command is Dictionary or not _valid_dictionary(command, MAX_COMMAND_KEYS, false):
		_abort("Otrzymano nieprawidłową komendę.")
		return
	command_received.emit(1, command)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_state(packet_bytes: PackedByteArray) -> void:
	if not active:
		return
	if is_host:
		_abort("Host otrzymał stan w niewłaściwym kierunku.")
		return
	if not peer_ready:
		_abort("Stan meczu pojawił się przed zakończeniem uzgadniania.")
		return
	if multiplayer.get_remote_sender_id() != HOST_PEER_ID:
		_abort("Stan meczu pochodzi od nieautoryzowanego nadawcy.")
		return
	var packet := _decode_packet(packet_bytes)
	var state: Variant = packet.get("state")
	if packet.is_empty() or not state is Dictionary or not _valid_dictionary(state, MAX_CONTAINER_ITEMS):
		_abort("Otrzymano nieprawidłowy stan meczu.")
		return
	state_received.emit(state)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_combat(packet_bytes: PackedByteArray) -> void:
	if not active:
		return
	if is_host:
		_abort("Host otrzymał klatkę walki w niewłaściwym kierunku.")
		return
	if not peer_ready:
		_abort("Klatka walki pojawiła się przed zakończeniem uzgadniania.")
		return
	if multiplayer.get_remote_sender_id() != HOST_PEER_ID:
		_abort("Klatka walki pochodzi od nieautoryzowanego nadawcy.")
		return
	var packet := _decode_packet(packet_bytes)
	var frame: Variant = packet.get("frame")
	var events: Variant = packet.get("events")
	var playing: Variant = packet.get("playing")
	var speed: Variant = packet.get("speed")
	if packet.is_empty() or not frame is Dictionary or not events is Array or not playing is bool or not _valid_number(speed):
		_abort("Otrzymano nieprawidłową klatkę walki.")
		return
	if not _valid_dictionary(frame, MAX_CONTAINER_ITEMS) or events.size() > MAX_COMBAT_EVENTS or not _valid_value(events, 0) or speed < 0.0 or speed > 8.0:
		_abort("Klatka walki przekracza dozwolone granice.")
		return
	combat_received.emit(frame, events, playing, speed)


func _mark_peer_ready() -> void:
	if peer_ready:
		return
	peer_ready = true
	_handshake_elapsed = 0.0
	_handshake_in_progress = false
	status_changed.emit("Połączono")
	if not _session_connected_emitted:
		_session_connected_emitted = true
		connected_match.emit()


func _abort(reason: String) -> void:
	if not active:
		return
	leave()
	disconnected.emit(reason)


func _reject_remote(peer_id: int, reason: String) -> void:
	_send_wire("_rpc_handshake", peer_id, _encode_packet({"kind": "reject", "reason": reason}))
	_reject_notice_pending = true
	_reject_notice_elapsed = 0.0
	_reject_notice_reason = reason


func _is_ready_host() -> bool:
	return active and is_host and peer_ready and _expected_peer_id > HOST_PEER_ID


func _is_ready_guest() -> bool:
	return active and not is_host and peer_ready


func _encode_packet(packet: Dictionary) -> PackedByteArray:
	var bytes := var_to_bytes(packet)
	if bytes.size() > MAX_PACKET_BYTES:
		return PackedByteArray()
	return bytes


func _fingerprint() -> String:
	return "%s|godot-%s" % [PROTOCOL_FINGERPRINT, Engine.get_version_info().get("string", "unknown")]


func _decode_packet(packet_bytes: PackedByteArray) -> Dictionary:
	if packet_bytes.is_empty() or packet_bytes.size() > MAX_PACKET_BYTES:
		return {}
	var parsed: Variant = bytes_to_var(packet_bytes)
	if not parsed is Dictionary or not _valid_dictionary(parsed, MAX_CONTAINER_ITEMS):
		return {}
	return parsed


func _valid_dictionary(value: Dictionary, max_keys: int, allow_integer_keys: bool = true) -> bool:
	if value.size() > max_keys:
		return false
	for key: Variant in value.keys():
		if not _valid_dictionary_key(key, allow_integer_keys):
			return false
		if not _valid_value(value[key], 1):
			return false
	return true


func _valid_value(value: Variant, depth: int) -> bool:
	if depth > MAX_VALUE_DEPTH:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT:
			return true
		TYPE_FLOAT:
			return _valid_number(value)
		TYPE_VECTOR2:
			return _valid_number(value.x) and _valid_number(value.y)
		TYPE_STRING:
			return value.to_utf8_buffer().size() <= MAX_STRING_BYTES
		TYPE_ARRAY:
			if value.size() > MAX_CONTAINER_ITEMS:
				return false
			for item: Variant in value:
				if not _valid_value(item, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			if value.size() > MAX_CONTAINER_ITEMS:
				return false
			for key: Variant in value.keys():
				if not _valid_dictionary_key(key):
					return false
				if not _valid_value(value[key], depth + 1):
					return false
			return true
		_:
			return false


func _valid_number(value: Variant) -> bool:
	return (value is float or value is int) and not is_nan(float(value)) and not is_inf(float(value))


func _valid_dictionary_key(key: Variant, allow_integer: bool = true) -> bool:
	if key is String:
		return not key.is_empty() and key.to_utf8_buffer().size() <= 128
	return allow_integer and key is int and absi(key) <= 2147483647

func _unreachable_reason() -> String:
	if use_fragmentation:
		return "Nie udało się połączyć z graczem przez usługę Epic. Sprawdźcie internet i spróbujcie utworzyć nowy pokój."
	return "BRAK POŁĄCZENIA z %s\nHost nie odpowiedział. Nie da się ustalić przyczyny z samego braku odpowiedzi.\n1. Host musi kliknąć „Utwórz mecz” i zostawić grę otwartą.\n2. Z innych mieszkań użyj publicznego IP hosta.\n3. Sprawdźcie zaporę Windows oraz przekierowanie wybranego portu UDP na routerze hosta. CGNAT może blokować takie połączenie.\nMożesz poprawić adres i ponowić próbę." % connection_target


func create_room() -> void:
	if active: return
	active = true
	rooms.start(true)

func join_room(code: String) -> void:
	if active: return
	active = true
	rooms.start(false, code)

func _room_failed(reason: String) -> void:
	if active:
		_abort(reason)
	else:
		status_changed.emit(reason)

func _room_transport_ready(peer: MultiplayerPeer, host_role: bool) -> void:
	use_fragmentation = true
	_begin_session(peer, host_role)
	local_player = 0 if host_role else 1
	connection_target = "pokój " + rooms.display_code()

func _send_wire(method: String, target: int, bytes: PackedByteArray) -> void:
	if not use_fragmentation:
		rpc_id(target, method, bytes)
		return
	var compressed := bytes.compress(FileAccess.COMPRESSION_DEFLATE)
	if compressed.is_empty() or compressed.size() > MAX_PACKET_BYTES:
		_abort.call_deferred("Dane meczu przekraczają limit połączenia.")
		return
	var count := ceili(float(compressed.size()) / Chunks.CHUNK_BYTES)
	for index in count:
		var part := compressed.slice(index * Chunks.CHUNK_BYTES, (index + 1) * Chunks.CHUNK_BYTES)
		var error := rpc_id(target, "_rpc_chunk", WIRE_METHODS.find(method), index, count, bytes.size(), part)
		if error != OK:
			_abort.call_deferred("Nie udało się wysłać danych meczu.")
			return

@rpc("any_peer", "call_remote", "reliable")
func _rpc_chunk(kind: int, index: int, count: int, raw_size: int, part: PackedByteArray) -> void:
	if not active: return
	var sender := multiplayer.get_remote_sender_id()
	if sender != (_expected_peer_id if is_host else HOST_PEER_ID) or sender == 0:
		return
	var result := _chunks.accept(kind, index, count, raw_size, part)
	_chunk_elapsed = 0.0
	if result.has("error"):
		_abort("Otrzymano nieprawidłowe fragmenty danych.")
	elif result.has("bytes"):
		# Synchronous dispatch retains the RPC sender for the existing authority checks.
		call(WIRE_METHODS[kind], result.bytes)
