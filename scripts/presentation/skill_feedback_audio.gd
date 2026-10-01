extends Node
## Small procedural one-voice sound set mapped to skill behavior families.
## Samples are synthesized locally so the project has no external audio dependency.

const SAMPLE_RATE := 22050
const BEHAVIORS := ["heavy", "multi", "projectile", "dive", "dash", "thorns", "debuff", "cone", "cloud"]
var player: AudioStreamPlayer
var streams: Dictionary = {}
var last_global_time := -100.0
var last_skill_time: Dictionary = {}
var enabled := false
var simulation_active := false
var simulation_speed := 1.0

func _ready() -> void:
	enabled = not OS.has_feature("headless") and DisplayServer.get_name() != "headless"
	player = AudioStreamPlayer.new()
	player.volume_db = -12.0
	player.max_polyphony = 1
	add_child(player)
	if not enabled:
		player.stream_paused = true

func play_skill(skill_id: String, behavior: String, simulation_time: float, is_series: bool = false) -> void:
	var family := "multi" if is_series else ("cloud" if behavior == "trail" else behavior)
	if not enabled or family not in BEHAVIORS or family == "thorns" or not simulation_active:
		return
	if simulation_time - last_global_time < 0.1:
		return
	var skill_cooldown := 0.6 if family in ["cloud", "debuff", "dash"] else (0.12 if family in ["multi", "cone"] else 0.4)
	if simulation_time - float(last_skill_time.get(family, -100.0)) < skill_cooldown:
		return
	last_global_time = simulation_time
	last_skill_time[family] = simulation_time
	if not streams.has(family):
		streams[family] = _make_stream(family)
	player.stream = streams[family]
	player.pitch_scale = clampf(simulation_speed, 0.5, 4.0)
	player.stream_paused = false
	player.play()

func set_playback(active: bool, speed: float) -> void:
	simulation_active = active
	simulation_speed = clampf(speed, 0.5, 4.0)
	if player == null:
		return
	player.pitch_scale = clampf(simulation_speed, 0.5, 4.0)
	player.stream_paused = not enabled or not active

func reset_feedback() -> void:
	last_global_time = -100.0
	last_skill_time.clear()
	if player != null:
		player.stop()
		player.stream_paused = not enabled or not simulation_active

func _make_stream(behavior: String) -> AudioStreamWAV:
	var duration := 0.2
	if behavior in ["projectile", "multi", "cone"]: duration = 0.16
	if behavior in ["cloud", "debuff", "dash"]: duration = 0.24
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var phase := 0.0
	var seed := 9173 + BEHAVIORS.find(behavior) * 811
	for index in range(frame_count):
		var t := float(index) / SAMPLE_RATE
		var progress := t / duration
		var envelope := pow(1.0 - progress, 2.0)
		var frequency := 72.0
		var noise_gain := 0.22
		var body_gain := 0.6
		if behavior in ["dive", "heavy"]:
			frequency = lerpf(118.0, 48.0, progress)
			noise_gain = 0.4
			body_gain = 0.78
		elif behavior == "projectile":
			frequency = lerpf(420.0, 255.0, progress) + sin(progress * PI) * 85.0
			noise_gain = 0.09
			body_gain = 0.42
		elif behavior in ["cone", "multi"]:
			frequency = lerpf(310.0, 170.0, progress)
			noise_gain = 0.38
			body_gain = 0.35
		elif behavior in ["cloud", "debuff"]:
			frequency = lerpf(520.0, 300.0, progress)
			noise_gain = 0.14
			body_gain = 0.24
		elif behavior == "dash":
			frequency = lerpf(240.0, 420.0, progress)
			noise_gain = 0.42
			body_gain = 0.32
		else:
			frequency = lerpf(156.0, 92.0, progress)
			noise_gain = 0.52
			body_gain = 0.4
		phase += TAU * frequency / SAMPLE_RATE
		seed = int((seed * 1103515245 + 12345) & 0x7fffffff)
		var noise := float(seed % 20001) / 10000.0 - 1.0
		var tone := sin(phase) * body_gain
		if behavior == "projectile":
			tone += sin(phase * 1.49) * 0.2
		var sample := int(clampf((tone + noise * noise_gain * (1.0 - progress * 0.5)) * envelope * 0.72, -1.0, 1.0) * 30000.0)
		var byte_index := index * 2
		data[byte_index] = sample & 0xff
		data[byte_index + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
