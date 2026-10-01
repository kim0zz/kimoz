extends Node
## Shared budget for all hippos. Quiet foley can never steal an impact voice.
const COUNTS = {"impact":3,"step":3,"swish":2,"grunt":2,"hurt":2,"win":1,"stun":1}
const LEVELS = {"impact":-6.0,"step":-24.0,"swish":-16.0,"grunt":-17.0,"hurt":-21.0,"win":-17.0,"stun":-22.0}
const GAPS = {"impact":0.06,"step":0.15,"swish":0.12,"grunt":0.28,"hurt":0.28,"win":0.6,"stun":0.2}
var streams: Dictionary = {}
var last: Dictionary = {}
var counters: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var active := false
var speed := 1.0
var muted := false
var played: Dictionary = {}

func _ready() -> void:
	for kind: String in COUNTS:
		var variants: Array[AudioStreamWAV] = []
		for i in range(COUNTS[kind]): variants.append(load("res://assets/audio/hippo/%s_%d.wav" % [kind,i]))
		streams[kind]=variants
	for i in range(4):
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)

func cue(kind: String, at: float) -> void:
	if not active or muted or not COUNTS.has(kind): return
	if at-float(last.get(kind,-100.0))<float(GAPS[kind]): return
	var index := 0 if kind=="impact" else 1 if kind=="swish" else 2 if kind in ["grunt","hurt","win"] else 3
	var player := players[index]
	if index==3 and player.playing: return
	last[kind]=at
	var count := int(counters.get(kind,0))
	counters[kind]=count+1
	player.stream=streams[kind][count%int(COUNTS[kind])]
	player.volume_db=float(LEVELS[kind])
	player.pitch_scale=clampf(speed,0.35,4.0)
	player.stream_paused=false
	player.play()
	played[kind]=int(played.get(kind,0))+1

func set_playback(value: bool, rate: float) -> void:
	active=value
	speed=rate
	for player in players:
		player.stream_paused=not active or muted
		player.pitch_scale=clampf(speed,0.35,4.0)

func reset_feedback() -> void:
	last.clear()
	counters.clear()
	for player in players: player.stop()
