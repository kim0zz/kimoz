class_name ZooEOSRooms
extends Node

signal status_changed(text: String)
signal failed(reason: String)
signal transport_ready(peer: MultiplayerPeer, host_role: bool)
signal room_changed(code: String)

const CONFIG_PATH := "res://config/eos.cfg"
const CODE_ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LENGTH := 12
const BUCKET := "kimoz-private-v1"

var busy := false
var room_code := ""
var lobby: HLobby
var peer: EOSGMultiplayerPeer
var _generation := 0
var _host := false
static var _platform_ready := false

static func normalize_code(value: String) -> String:
	return value.strip_edges().to_upper().replace("-", "").replace(" ", "")

static func valid_code(value: String) -> bool:
	var code := normalize_code(value)
	if code.length() != CODE_LENGTH:
		return false
	for character in code:
		if not CODE_ALPHABET.contains(character):
			return false
	return true

static func configuration_error() -> String:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return "Pokoje online czekają na konfigurację projektu Epic. Szczegóły: docs/EOS_SETUP.md."
	for key in ["product_id", "sandbox_id", "deployment_id", "client_id", "client_secret"]:
		if str(config.get_value("eos", key, "")).strip_edges().is_empty():
			return "Konfiguracja Epic jest niepełna. Uzupełnij pole: " + key
	return ""

func start(host_role: bool, code: String = "") -> void:
	if busy or lobby != null:
		failed.emit("Poprzednie połączenie jest jeszcze zamykane. Spróbuj za chwilę.")
		return
	var problem := configuration_error()
	if not problem.is_empty():
		failed.emit(problem)
		return
	if not host_role and not valid_code(code):
		failed.emit("Wpisz pełny, 12-znakowy kod pokoju znajomego.")
		return
	busy = true
	_generation += 1
	var generation := _generation
	_host = host_role
	status_changed.emit("Łączenie z usługą pokoi…")
	var authenticated := await _authenticate()
	if generation != _generation:
		busy = false
		return
	if not authenticated:
		_finish_error("Nie udało się połączyć z Epic. Sprawdź internet i konfigurację usługi.")
		return
	HLobbies.presence_enabled = false
	var selected: HLobby
	var selected_code := normalize_code(code)
	if host_role:
		status_changed.emit("Tworzenie pokoju…")
		var options := EOS.Lobby.CreateLobbyOptions.new()
		selected_code = _new_code()
		options.lobby_id = "KIMOZ" + selected_code
		options.bucket_id = BUCKET
		options.max_lobby_members = 2
		options.presence_enabled = false
		options.enable_join_by_id = false
		options.allow_invites = false
		options.disable_host_migration = true
		options.enable_rtc_room = false
		selected = await HLobbies.create_lobby_async(options)
	else:
		status_changed.emit("Szukanie pokoju…")
		var matches: Variant = await HLobbies.search_by_lobby_id_async("KIMOZ" + selected_code)
		if generation != _generation:
			busy = false
			return
		if matches == null or matches.is_empty():
			_finish_error("Nie znaleziono pokoju. Sprawdź kod; gospodarz musi zostawić grę otwartą.")
			return
		var candidate: HLobby = matches[0]
		if candidate.bucket_id != BUCKET or candidate.available_slots < 1:
			_release_lobby_view(candidate)
			_finish_error("Pokój jest pełny albo nie pasuje do tej gry.")
			return
		if candidate.owner_product_user_id == HAuth.product_user_id:
			_release_lobby_view(candidate)
			_finish_error("To twój własny pokój. Do testu użyj drugiego komputera lub konta Windows.")
			return
		selected = await HLobbies.join_async(candidate)
		_release_lobby_view(candidate)
	if generation != _generation:
		await _dispose_lobby(selected)
		busy = false
		return
	if selected == null:
		_finish_error("Nie udało się otworzyć pokoju. Może być pełny lub już zamknięty. Spróbuj ponownie.")
		return
	lobby = selected
	room_code = selected_code
	room_changed.emit(room_code)
	lobby.lobby_updated.connect(_check_members)
	lobby.kicked_from_lobby.connect(_room_closed)
	lobby.lobby_owner_changed.connect(_room_closed)
	peer = EOSGMultiplayerPeer.new()
	peer.set_auto_accept_connection_requests(false)
	var socket_id := "Kimoz" + lobby.lobby_id.sha256_text().substr(0, 24)
	var error: int
	if host_role:
		error = peer.create_server(socket_id)
	else:
		error = peer.create_client(socket_id, lobby.owner_product_user_id)
	busy = false
	if error != OK:
		failed.emit("Nie udało się uruchomić połączenia z graczem: " + error_string(error))
		cancel()
		return
	transport_ready.emit(peer, host_role)
	if host_role:
		status_changed.emit("POKÓJ: %s\nWyślij kod znajomemu. Czekam na dołączenie…" % display_code())
	else:
		status_changed.emit("Pokój znaleziony. Łączenie z gospodarzem…")

func display_code() -> String:
	return "%s-%s-%s" % [room_code.substr(0, 4), room_code.substr(4, 4), room_code.substr(8, 4)] if not room_code.is_empty() else ""

func _authenticate() -> bool:
	HLog.log_level = HLog.LogLevel.ERROR
	if not _platform_ready:
		var config := ConfigFile.new()
		if config.load(CONFIG_PATH) != OK:
			return false
		var credentials := HCredentials.new()
		credentials.product_name = "Kimoz"
		credentials.product_version = "1.0"
		for key in ["product_id", "sandbox_id", "deployment_id", "client_id", "client_secret"]:
			credentials.set(key, str(config.get_value("eos", key, "")))
		HPlatform.flags = EOS.Platform.PlatformFlags.DisableOverlay | EOS.Platform.PlatformFlags.DisableSocialOverlay
		HPlatform.task_network_timeout_seconds = 15.0
		_platform_ready = await HPlatform.setup_eos_async(credentials)
		if not _platform_ready:
			return false
		get_node("/root/KimozEOSLifecycle").initialized = true
	if HAuth.product_user_id.is_empty():
		# Preserve the device identity; the helper's anonymous login deletes it each time.
		var create_options := EOS.Connect.CreateDeviceIdOptions.new()
		create_options.device_model = "Kimoz Windows"
		EOS.Connect.ConnectInterface.create_device_id(create_options)
		var result: Dictionary = await IEOS.connect_interface_create_device_id_callback
		if not EOS.is_success(result) and result.result_code != EOS.Result.DuplicateNotAllowed:
			return false
		var login_options := EOS.Connect.LoginOptions.new()
		login_options.credentials = EOS.Connect.Credentials.new()
		login_options.credentials.type = EOS.ExternalCredentialType.DeviceidAccessToken
		login_options.credentials.token = null
		login_options.user_login_info = EOS.Connect.UserLoginInfo.new()
		login_options.user_login_info.display_name = "Gracz Kimoz"
		if not await HAuth.login_game_services_async(login_options):
			return false
		# On first use CreateUser completes without a successful Login callback.
		# EOSG's native P2P mediator and runtime ID are initialized by that callback.
		if EOSGRuntime.local_product_user_id != HAuth.product_user_id:
			if not await HAuth.login_game_services_async(login_options):
				return false
	return EOS.is_success(HP2P.set_relay_control(EOS.P2P.RelayControl.AllowRelays))

func _process(_delta: float) -> void:
	if peer == null or lobby == null or not _host:
		return
	# Membership notification may arrive after the P2P request. Wait for membership.
	for user_id: String in peer.get_all_connection_requests():
		if lobby.get_member_by_product_user_id(user_id) != null:
			peer.accept_connection_request(user_id)

func _check_members() -> void:
	if lobby == null or peer == null:
		return
	if not _host and lobby.get_member_by_product_user_id(lobby.owner_product_user_id) == null:
		_room_closed()

func _room_closed() -> void:
	failed.emit("Pokój został zamknięty lub utracono połączenie z usługą.")
	cancel()

func cancel() -> void:
	_generation += 1
	room_code = ""
	room_changed.emit("")
	if peer != null:
		peer.close()
		peer = null
	var old_lobby := lobby
	lobby = null
	if old_lobby != null:
		old_lobby.lobby_updated.disconnect(_check_members)
		old_lobby.kicked_from_lobby.disconnect(_room_closed)
		old_lobby.lobby_owner_changed.disconnect(_room_closed)
		busy = true
		await _dispose_lobby(old_lobby)
		busy = false

func _dispose_lobby(old_lobby: HLobby) -> void:
	if old_lobby == null:
		return
	if old_lobby.is_valid():
		if old_lobby.is_owner():
			await old_lobby.destroy_async()
		else:
			await old_lobby.leave_async()
	_release_lobby_view(old_lobby)

func _release_lobby_view(view: HLobby) -> void:
	# EOSG 2.3.1 stores strong references in both lobby and members.
	# Break that cycle after use without modifying the third-party addon.
	view._disconnect_from_signals()
	for member in view.members:
		member._lobby = null
	view.members.clear()

func _finish_error(reason: String) -> void:
	busy = false
	failed.emit(reason)

static func _new_code() -> String:
	var bytes := Crypto.new().generate_random_bytes(CODE_LENGTH)
	var code := ""
	for value in bytes:
		code += CODE_ALPHABET[value % CODE_ALPHABET.length()]
	return code
