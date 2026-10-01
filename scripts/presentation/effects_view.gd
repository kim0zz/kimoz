extends Node2D
const FeedbackStyle = preload("res://scripts/presentation/skill_feedback_style.gd")

var effects: Array = []
var clock := 0.0
const LIFE := 0.72
const FEEDBACK_LIFE := 0.62
const TEAMFIGHT_FEEDBACK_LIFE := 0.92
const PREP_FEEDBACK_LIFE := 2.4
var feedback_audio: Node
var hippo_audio: Node
var hippo_contact: Node2D
var passive_feedback_at: Dictionary = {}
var series_tick: Dictionary = {}
var series_count: Dictionary = {}
var series_time: Dictionary = {}

func _ready() -> void:
	feedback_audio = preload("res://scripts/presentation/skill_feedback_audio.gd").new()
	add_child(feedback_audio)
	hippo_audio = preload("res://scripts/presentation/hippo_audio.gd").new()
	add_child(hippo_audio)
	hippo_contact = preload("res://scripts/presentation/hippo_contact_fx.gd").new()
	hippo_contact.z_index = 20
	add_child(hippo_contact)

func reset_feedback() -> void:
	effects.clear()
	hippo_audio.reset_feedback()
	hippo_contact.hits.clear()
	hippo_contact.advance(0.0)
	passive_feedback_at.clear()
	series_tick.clear()
	series_count.clear()
	series_time.clear()
	clock = 0.0
	if feedback_audio != null:
		feedback_audio.reset_feedback()
	queue_redraw()

func set_playback(active: bool, speed: float) -> void:
	hippo_audio.set_playback(active, speed)
	if feedback_audio != null:
		feedback_audio.set_playback(active, speed)

func ingest(events: Array, units: Array, elapsed: float) -> void:
	clock = elapsed
	hippo_contact.advance(elapsed)
	for event in events:
		var kind: String = event.get("kind", "")
		var point: Vector2 = event.get("pos", Vector2.ZERO)
		var source := int(event.get("source", -1))	
		if not event.has("pos") and source >= 0 and source < units.size(): point = units[source].pos
		if kind == "cone_hit":
			var behavior := str(event.get("skill_behavior", "cone"))
			effects.append({"type":"cone", "pos":point, "direction":event.get("direction", Vector2.RIGHT),
				"radius":float(event.get("radius", 0)), "angle":float(event.get("angle", 100)), "color":FeedbackStyle.color(behavior), "at":clock})
		elif kind == "stun":
			effects.append({"type":"stun", "pos":point, "color":Color("ffe07a"), "at":clock})
		elif kind == "aggro_break":
			effects.append({"type":"break", "pos":point, "color":Color("b6df70"), "at":clock})
		elif kind == "damage":
			var damage_kind := str(event.get("damage_kind", ""))
			var skill_id := str(event.get("skill", ""))
			var behavior := str(event.get("skill_behavior", ""))
			if damage_kind == "thorns":
				_add_passive_feedback(event, units, "thorns")
			elif damage_kind == "dot":
				_add_passive_feedback(event, units, "dot")
			elif damage_kind == "skill" and not skill_id.is_empty() and float(event.get("amount", 0.0)) > 0.0:
				if behavior.is_empty(): behavior = FeedbackStyle.behavior(units, source, skill_id)
				if behavior.is_empty() and skill_id.ends_with("_banana"): behavior = "projectile"
				if not behavior.is_empty(): _add_skill_impact(event, behavior)
			else:
				effects.append({"type":"text", "pos":point, "color":Color("a94741"),
					"text":"−%.0f" % float(event.get("amount", 0)), "at":clock})
		elif kind == "cloud":
			var behavior := str(event.get("skill_behavior", "cloud"))
			effects.append({"type":"pulse", "pos":point, "radius":float(event.get("radius", 55)),
				"color":FeedbackStyle.color(behavior), "behavior":behavior, "at":clock})
		elif kind == "skill_start":
			var behavior: String = event.get("behavior", "")
			var label := str(event.get("skill_label", ""))
			var prep_target := int(event.get("prep_target", -1))
			var target_pos := _unit_position(units, prep_target, point)
			effects.append({"type":"cast", "pos":point, "target_pos":target_pos,
				"has_target":label != "" and prep_target >= 0, "color":Color("ffe190"),
				"text":label if not label.is_empty() else FeedbackStyle.label(behavior),
				"behavior":behavior, "teamfight":not label.is_empty(), "at":clock})
			if feedback_audio != null and behavior in ["dash", "cloud", "debuff", "trail"]:
				feedback_audio.play_skill(str(event.get("skill", "")), behavior, clock)
		elif kind in ["heal", "shield", "guard", "shield_absorb"]:
			var target := int(event.get("target", -1))
			var target_pos := _unit_position(units, target, point)
			var amount := float(event.get("amount", 0.0))
			var is_heal := kind == "heal"
			if kind == "shield_absorb":
				effects.append({"type":"absorb", "pos":target_pos, "text":"TARCZA −%.0f" % amount,
					"color":Color("82caff"), "at":clock})
			else:
				var source_pos := _unit_position(units, source, point)
				effects.append({"type":"support", "pos":target_pos, "start":source_pos, "finish":target_pos,
					"color":Color("70e88b") if is_heal else Color("65baff"),
					"text":("+%.0f" % amount) if is_heal else ("TARCZA +%.0f" % amount),
					"at":clock})
		elif kind == "taunt":
			var taunt_target := int(event.get("target", -1))
			effects.append({"type":"taunt", "pos":_unit_position(units, taunt_target, point),
				"start":_unit_position(units, source, point), "text":"PROWOKACJA", "color":Color("ffad63"), "at":clock})
		elif kind in ["retreat_start", "retreat_end", "interrupt", "decision"]:
			if kind == "decision": continue
			var target := int(event.get("plan_target", event.get("target", -1)))
			var label := str(event.get("reason", event.get("state", "")))
			if kind == "retreat_start": label = "ODWRÓT"
			elif kind == "retreat_end": label = "POWRÓT"
			elif kind == "interrupt": label = "PRZERWANIE"
			elif label.is_empty(): label = "DECISION"
			effects.append({"type":"decision", "pos":point, "target_pos":_unit_position(units,target,point),
				"has_target":target >= 0, "text":label.replace("_", " ").to_upper().left(18),
				"color":Color("b7d8ff") if kind == "decision" else Color("ffcf83"), "at":clock})
	effects = effects.filter(func(effect: Dictionary) -> bool:
		return clock - float(effect.at) < _effect_lifetime(effect))
	queue_redraw()

func _effect_lifetime(effect: Dictionary) -> float:
	if effect.type == "skill_impact": return FEEDBACK_LIFE
	if effect.type == "cast" and bool(effect.get("teamfight", false)): return PREP_FEEDBACK_LIFE
	if effect.type in ["support", "absorb", "taunt", "decision"]: return TEAMFIGHT_FEEDBACK_LIFE
	return LIFE

func _unit_position(units: Array, uid: int, fallback: Vector2) -> Vector2:
	if uid >= 0 and uid < units.size():
		var unit_data: Dictionary = units[uid]
		return Vector2(unit_data.get("pos", fallback))
	return fallback

func _add_passive_feedback(event: Dictionary, units: Array, effect_type: String) -> void:
	var source := int(event.get("source", -1))
	var target := int(event.get("target", -1))
	var skill_id := str(event.get("skill", ""))
	var key := "%s:%s:%s" % [effect_type, source, target]
	var interval := 0.4 if effect_type == "thorns" else 0.55
	if clock - float(passive_feedback_at.get(key, -100.0)) < interval: return
	passive_feedback_at[key] = clock
	var point: Vector2 = event.get("pos", Vector2.ZERO)
	var start: Vector2 = units[source].pos if source >= 0 and source < units.size() else point
	var finish: Vector2 = units[target].pos if target >= 0 and target < units.size() else point
	var behavior := str(event.get("skill_behavior", "thorns" if effect_type == "thorns" else "cloud"))
	if behavior.is_empty(): behavior = FeedbackStyle.behavior(units, source, skill_id, "thorns" if effect_type == "thorns" else "cloud")
	effects.append({"type":effect_type, "pos":finish, "start":start, "finish":finish,
		"color":FeedbackStyle.color(behavior), "text":"KOLCE" if effect_type == "thorns" else "", "at":clock})

func _add_skill_impact(event: Dictionary, behavior: String) -> void:
	var skill_id := str(event.skill)
	var source := int(event.get("source", -1))
	var series_key := "%s:%s" % [source, skill_id]
	var tick := int(round(clock * 60.0))
	var sequence := int(series_count.get(series_key, 0))
	if int(series_tick.get(series_key, -1)) != tick:
		var previous_time := float(series_time.get(series_key, -100.0))
		sequence = sequence + 1 if clock - previous_time < 0.9 else 1
		series_count[series_key] = sequence
		series_tick[series_key] = tick
		series_time[series_key] = clock
	var total := maxi(1, int(event.get("skill_hits", 1)))
	effects.append({"type":"skill_impact", "skill":skill_id, "source":source,
		"pos":event.get("pos", Vector2.ZERO), "amount":float(event.get("amount", 0.0)),
		"behavior":behavior, "sequence":sequence, "total":total,
		"direction":Vector2(event.get("impact_direction", Vector2.UP)),
		"color":FeedbackStyle.color(behavior), "at":clock})
	if skill_id == "hippo_heavy":
		var direction := Vector2(event.get("impact_direction",Vector2.RIGHT)).normalized()
		hippo_contact.impact(Vector2(event.get("pos",Vector2.ZERO))-direction*18.0+Vector2(0,-28),direction,clock)
	elif feedback_audio != null:
		feedback_audio.play_skill(skill_id, behavior, clock, total > 1)

func _draw() -> void:
	for effect in effects:
		var age: float = clock - float(effect.at)
		var fade := clampf(1.0 - age / _effect_lifetime(effect), 0.0, 1.0)
		var color: Color = effect.color
		color.a *= fade
		var point: Vector2 = effect.pos
		match effect.type:
			"skill_impact": _draw_skill_impact(effect, color, age)
			"cone": _draw_cone(point, effect.direction, float(effect.radius), float(effect.angle), color, 1.0 + age * 0.2)
			"thorns": _draw_thorns(effect, color, age)
			"dot": _draw_dot(point, color, age)
			"stun": _draw_stun(point, color, age)
			"break":
				draw_arc(point, 15 + age * 36, 0, TAU, 28, color, 3.0, true)
				draw_string(ThemeDB.fallback_font, point + Vector2(13,-15-age*22), "ZGUBIONY CEL", HORIZONTAL_ALIGNMENT_LEFT,-1,10,color)
			"support": _draw_support(effect, color, age)
			"absorb": _draw_absorb(effect, color, age)
			"taunt": _draw_taunt(effect, color, age)
			"decision": _draw_decision(effect, color, age)
			"pulse":
				draw_circle(point, float(effect.radius) * (0.2 + age * 0.5), Color(color.r,color.g,color.b,color.a*0.14))
				draw_arc(point, float(effect.radius) * (0.55 + age * 0.35), 0, TAU, 32, color, 2.0, true)
			"cast", "text":
				var rise := 23.0 if effect.type == "cast" else 35.0
				if effect.type == "cast" and bool(effect.get("has_target", false)):
					var target_pos: Vector2 = effect.target_pos
					draw_line(point, target_pos, Color(color.r,color.g,color.b,color.a*0.72), 2.0)
					draw_arc(target_pos, 13.0+age*5.0, 0, TAU, 24, color, 2.5, true)
				var label_size := 10 if bool(effect.get("teamfight", false)) else 12
				draw_string(ThemeDB.fallback_font, point + Vector2(-20,-48-age*rise), effect.text, HORIZONTAL_ALIGNMENT_LEFT,-1,label_size,color)

func _draw_support(effect: Dictionary, color: Color, age: float) -> void:
	var start: Vector2 = effect.start
	var finish: Vector2 = effect.finish
	var axis := finish - start
	var mix := clampf(age / TEAMFIGHT_FEEDBACK_LIFE, 0.0, 1.0)
	if axis.length_squared() > 1.0:
		var normal := axis.normalized().orthogonal()
		var wobble := normal * sin(age * 22.0) * 3.0
		draw_line(start, finish, Color(color.r,color.g,color.b,color.a*0.26), 7.0)
		draw_line(start, finish, color, 2.0)
		for i in range(3):
			var p := start.lerp(finish, fposmod(mix + float(i)*0.22,1.0)) + wobble
			draw_circle(p, 3.0, Color(color.r,color.g,color.b,color.a*0.95))
	draw_arc(finish, 12.0+age*8.0, 0, TAU, 24, color, 2.5, true)
	var text_color := Color("baffc3",color.a) if color.g > color.b else Color("c6e8ff",color.a)
	draw_string(ThemeDB.fallback_font,finish+Vector2(16,-22-age*13),str(effect.text),HORIZONTAL_ALIGNMENT_LEFT,-1,11,text_color)

func _draw_absorb(effect: Dictionary, color: Color, age: float) -> void:
	var point: Vector2 = effect.pos
	var radius := 13.0 + age * 16.0
	draw_arc(point, radius, 0.0, TAU, 24, color, 2.2, true)
	draw_string(ThemeDB.fallback_font,point+Vector2(14,-18-age*12),str(effect.text),HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)

func _draw_taunt(effect: Dictionary, color: Color, age: float) -> void:
	var point: Vector2 = effect.pos
	var start: Vector2 = effect.start
	draw_arc(point, 18.0+age*18.0, 0, TAU, 28, color, 3.0, true)
	if start.distance_squared_to(point) > 1.0:
		draw_line(start, point, Color(color.r,color.g,color.b,color.a*0.68), 2.0)
	draw_string(ThemeDB.fallback_font,point+Vector2(14,-18-age*10),str(effect.get("text", "PROWOKACJA")),HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)

func _draw_decision(effect: Dictionary, color: Color, age: float) -> void:
	var point: Vector2 = effect.pos
	if bool(effect.get("has_target", false)):
		var target_pos: Vector2 = effect.target_pos
		draw_line(point, target_pos, Color(color.r,color.g,color.b,color.a*0.45), 1.4)
		draw_arc(target_pos, 8.0+age*3.0, 0, TAU, 20, color, 1.7, true)
	draw_string(ThemeDB.fallback_font,point+Vector2(13,-37-age*7),str(effect.text),HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)

func _draw_skill_impact(effect: Dictionary, color: Color, age: float) -> void:
	var point: Vector2 = effect.pos
	var p := clampf(age / FEEDBACK_LIFE, 0.0, 1.0)
	var direction: Vector2 = effect.direction.normalized()
	if direction.length_squared() < 0.01: direction = Vector2.UP
	if effect.get("skill", "") == "hippo_heavy":
		_draw_damage_label(point, effect.amount, "ŁUP!", color, p)
		return
	match effect.behavior:
		"dive":
			var radius := 12.0 + p * 48.0
			draw_circle(point, 19.0 * (1.0-p) + 4.0, Color(color.r,color.g,color.b,color.a*0.18*(1.0-p)))
			draw_arc(point, radius, 0, TAU, 40, color, 4.5 * (1.0-p)+1.2, true)
			draw_arc(point, radius * 0.64, 0, TAU, 32, Color(1.0,0.92,0.67,color.a*0.9), 2.2, true)
			for index in range(8):
				var angle := TAU * float(index) / 8.0
				var radial := Vector2.from_angle(angle)
				draw_line(point+radial*(radius*0.55),point+radial*(radius+8.0*(1.0-p)),color,2.3)
			var caption := _series_caption(effect, "DESANT")
			_draw_damage_label(point, effect.amount, caption, color, p)
		"projectile", "heavy":
			var radius := 13.0 + p * 38.0
			draw_circle(point, radius * 0.52, Color(1.0,0.77,0.17,color.a*0.15*(1.0-p)))
			draw_arc(point, radius, -0.15, PI*1.85, 32, color, 4.2 * (1.0-p)+1.2, true)
			if effect.behavior == "projectile":
				draw_arc(point, radius*0.63, PI*0.1, PI*1.1, 24, Color(1.0,0.97,0.64,color.a*0.95), 3.0, true)
				draw_arc(point + direction * 3.0, 10.0*(1.0-p)+4.0, PI*1.1, PI*1.9, 16, Color(1.0,0.88,0.27,color.a), 4.0, true)
			else:
				draw_line(point-direction*18.0,point+direction*18.0,color,4.0)
				draw_line(point-direction.orthogonal()*13.0,point+direction.orthogonal()*13.0,color,3.0)
			_draw_damage_label(point, effect.amount, _series_caption(effect, FeedbackStyle.label(effect.behavior)), color, p)
		"cone", "multi":
			var center := point + direction * p * 9.0
			var blade_count := 3 if effect.behavior == "multi" else 1
			for slash in range(blade_count):
				var spread := (float(slash) - float(blade_count - 1) * 0.5) * 9.0
				var start := center - direction*16.0 + direction.orthogonal()*spread
				var finish := center + direction*23.0 + direction.orthogonal()*spread
				draw_line(start,finish,Color(1.0,0.91,0.62,color.a),4.0 if effect.behavior == "cone" else 3.2)
			draw_arc(point, 15.0 + p*26.0, -0.9, 0.9, 20, color, 3.0*(1.0-p)+1.0, true)
			if effect.behavior == "multi":
				_draw_small_damage_label(point, effect.amount, color, p)
				draw_string(ThemeDB.fallback_font,point+Vector2(24,-42.0-14.0*p),_series_caption(effect,"SERIA"),HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)
			else:
				_draw_damage_label(point, effect.amount, _series_caption(effect, FeedbackStyle.label(effect.behavior)), color, p)
		"dash":
			draw_arc(point, 10.0 + p*27.0, direction.angle()-1.4, direction.angle()+1.4, 24, color, 3.0*(1.0-p)+1.0, true)
			_draw_small_damage_label(point, effect.amount, color, p)
			draw_string(ThemeDB.fallback_font,point+Vector2(24,-42.0-14.0*p),_series_caption(effect,"DOSKOK"),HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)

func _series_caption(effect: Dictionary, fallback: String) -> String:
	if int(effect.get("total", 1)) <= 1: return fallback
	return "%d / %d" % [int(effect.get("sequence", 1)), int(effect.total)]

func _draw_damage_label(point: Vector2, amount: float, caption: String, color: Color, progress: float) -> void:
	var rise := 18.0 * progress
	var damage_text := "−%.0f" % amount
	var font := ThemeDB.fallback_font
	# Place the burst beside the unit so it stays clear of the stun stars above its head.
	var baseline := point + Vector2(34.0, -21.0-rise)
	for shadow_offset in [Vector2(2,2),Vector2(-2,1),Vector2(1,-2),Vector2(-1,-2)]:
		draw_string(font,baseline+shadow_offset,damage_text,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("263044",color.a))
	draw_string(font,baseline,damage_text,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("fff3c7",color.a))
	if not caption.is_empty():
		draw_string(font,point+Vector2(34.0,-45.0-rise),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10,color)

func _draw_small_damage_label(point: Vector2, amount: float, color: Color, progress: float) -> void:
	var baseline := point + Vector2(23.0, -25.0 - 14.0 * progress)
	var label := "−%.0f" % amount
	draw_string(ThemeDB.fallback_font, baseline + Vector2(1,1), label, HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("263044",color.a))
	draw_string(ThemeDB.fallback_font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff3c7",color.a))

func _draw_cone(origin: Vector2, direction: Vector2, radius: float, angle_degrees: float, color: Color, scale: float) -> void:
	if direction.length_squared() < 0.01: return
	var start_angle := direction.angle() - deg_to_rad(angle_degrees * 0.5)
	var points := PackedVector2Array([origin])
	for index in range(25):
		var angle := start_angle + deg_to_rad(angle_degrees) * float(index) / 24.0
		points.append(origin + Vector2.from_angle(angle) * radius * scale)
	points.append(origin)
	draw_colored_polygon(points, Color(color.r,color.g,color.b,color.a*0.19))
	draw_polyline(points, color, 3.0, true)
	var slash_center := origin + direction.normalized() * radius * 0.72 * scale
	var tangent := direction.normalized().orthogonal() * radius * 0.48
	draw_line(slash_center - tangent, slash_center + tangent, Color("fff0b1"), 4.0)

func _draw_thorns(effect: Dictionary, color: Color, age: float) -> void:
	var start: Vector2 = effect.start
	var finish: Vector2 = effect.finish
	var axis := finish - start
	if axis.length_squared() > 0.01:
		var normal := axis.normalized().orthogonal()
		var middle := start.lerp(finish, 0.56)
		var spike := middle + axis.normalized() * 5.0
		draw_line(start, middle, color, 2.5)
		draw_line(middle, finish, color, 2.5)
		draw_line(middle - normal * 8.0, spike, color, 2.5)
		draw_line(middle + normal * 8.0, spike, color, 2.5)
	if not str(effect.text).is_empty():
		draw_string(ThemeDB.fallback_font, finish + Vector2(-11,-18-age*14), effect.text, HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)

func _draw_dot(point: Vector2, color: Color, age: float) -> void:
	var radius := 6.0 + age * 10.0
	draw_arc(point, radius, 0.0, TAU, 20, color, 1.7, true)
	draw_circle(point, 2.5, Color(color.r,color.g,color.b,color.a*0.42))

func _draw_stun(point: Vector2, color: Color, age: float) -> void:
	for index in range(5):
		var angle := age * 10.0 + TAU * float(index) / 5.0
		var center := point + Vector2.from_angle(angle) * (15.0 + sin(age * 20.0 + index) * 3.0)
		var star := PackedVector2Array()
		for vertex in range(10):
			var radius := 5.0 if vertex % 2 == 0 else 2.2
			star.append(center + Vector2.from_angle(-PI*0.5 + TAU*float(vertex)/10.0) * radius)
		draw_colored_polygon(star, color)
