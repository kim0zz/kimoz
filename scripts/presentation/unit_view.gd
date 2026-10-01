extends Node2D
## Presentation only. All authoritative state comes from CombatSimulation.
const INK = Color("263044")
const FeedbackStyle = preload("res://scripts/presentation/skill_feedback_style.gd")
const Art = preload("res://scripts/presentation/cartoon_art.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
var unit: Dictionary = {}
const HippoRig = preload("res://scenes/units/hippo_rig.tscn")
var hippo_rig: Node2D
var hippo_audio: Node
var overhead: Node2D

func _ready() -> void:
	overhead = Node2D.new()
	overhead.z_index = 100
	overhead.position = Vector2(0,-115)
	overhead.draw.connect(_draw_overhead)
	add_child(overhead)

var clock: float = 0.0
var previous_position: Vector2
var moving: bool = false
var feedback_skill_id := ""
var feedback_skill_label := ""
var feedback_prep_target := -1
var feedback_started_at := -100.0
var feedback_impact_at := -100.0
var feedback_display_hp := 0.0
var feedback_trail_hp := 0.0
var feedback_trail_at := -100.0
var feedback_recoil_direction := Vector2.UP
var feedback_impact_strength := 1.0
var feedback_action_remaining := -1
var feedback_strike_at := -100.0
var passive_feedback_at := -100.0
const STUN_GOLD := Color("ffe07a")
var celebrating := false
var last_facing := 1.0
var attack_at := -100.0
var died_at := -1.0
var previous_shield_hp := 0.0
var shield_break_at := -100.0

func refresh(data: Dictionary, elapsed: float) -> void:
	var shield_now := float(data.get("shield_hp", 0.0))
	if previous_shield_hp > 0.0 and shield_now <= 0.0 and bool(data.alive): shield_break_at = elapsed
	previous_shield_hp = shield_now
	if not bool(data.alive) and died_at < 0.0: died_at = elapsed
	if bool(data.alive): died_at = -1.0
	unit = data
	clock = elapsed
	moving = position.distance_to(data.pos) > 0.1
	position = data.pos
	var action: Dictionary = data.get("action", {})
	var active_skill := ""
	if not action.is_empty() and action.get("skill") != null:
		active_skill = str(action.skill.id)
	if not active_skill.is_empty():
		if active_skill != feedback_skill_id:
			feedback_skill_id = active_skill
			feedback_started_at = elapsed
			feedback_action_remaining = int(action.get("remaining", -1))
		else:
			var remaining := int(action.get("remaining", -1))
			if feedback_action_remaining >= 0 and remaining >= 0 and remaining < feedback_action_remaining:
				feedback_strike_at = elapsed
				feedback_action_remaining = remaining
	elif not feedback_skill_id.is_empty():
		feedback_skill_id = ""
		feedback_action_remaining = -1
	if feedback_display_hp <= 0.0:
		feedback_display_hp = float(data.get("hp", 0.0))
		feedback_trail_hp = feedback_display_hp
	else:
		feedback_display_hp = float(data.get("hp", 0.0))
	if is_instance_valid(overhead):
		overhead.position = Vector2(0,maxf(-115.0, 2.0-position.y-30.0))
		overhead.queue_redraw()
	if str(data.id) == "hippo":
		if not is_instance_valid(hippo_rig):
			hippo_rig = HippoRig.instantiate()
			add_child(hippo_rig)
			if is_instance_valid(hippo_audio): hippo_rig.cue.connect(hippo_audio.cue)
		hippo_rig.show()
		hippo_rig.sample(data, elapsed, celebrating)
	elif is_instance_valid(hippo_rig):
		hippo_rig.hide()
	queue_redraw()

func receive_source_feedback(event: Dictionary, elapsed: float) -> void:
	if is_instance_valid(hippo_rig) and hippo_rig.visible: hippo_rig.source_event(event, elapsed)

## Called by the presentation controller for each simulation event routed to this unit.
func receive_feedback(event: Dictionary, elapsed: float) -> void:
	if is_instance_valid(hippo_rig) and hippo_rig.visible: hippo_rig.target_event(event, elapsed)
	if event.get("kind", "") in ["attack", "projectile", "skill_start"]: attack_at = elapsed
	var skill_id := str(event.get("skill", ""))
	if event.get("kind", "") == "skill_start" and not skill_id.is_empty():
		feedback_skill_id = skill_id
		feedback_skill_label = str(event.get("skill_label", ""))
		feedback_prep_target = int(event.get("prep_target", -1))
		feedback_started_at = elapsed
		return
	if event.get("kind", "") != "damage" or skill_id.is_empty():
		return
	var amount := float(event.get("amount", 0.0))
	if amount <= 0.0:
		return
	var damage_kind := str(event.get("damage_kind", ""))
	if damage_kind not in ["skill", "dot", "thorns"]: return
	var behavior := str(event.get("skill_behavior", ""))
	if behavior.is_empty(): behavior = "thorns" if damage_kind == "thorns" else ("cloud" if damage_kind == "dot" else "")
	if behavior.is_empty() and skill_id.ends_with("_banana"): behavior = "projectile"
	var passive := damage_kind in ["dot", "thorns"]
	if passive and elapsed - passive_feedback_at < 0.4: return
	if passive: passive_feedback_at = elapsed
	feedback_impact_at = elapsed
	feedback_impact_strength = 0.32 if passive else (0.68 if behavior == "multi" else 1.0)
	if elapsed - feedback_trail_at >= (0.5 if passive else 0.32):
		feedback_trail_hp = feedback_display_hp
	feedback_trail_at = elapsed
	feedback_trail_hp = maxf(feedback_trail_hp, feedback_display_hp)
	var impact_direction: Vector2 = event.get("impact_direction", Vector2.ZERO)
	if impact_direction.length_squared() > 0.01:
		feedback_recoil_direction = impact_direction.normalized()
	else:
		var facing: Vector2 = unit.get("facing", Vector2.UP)
		feedback_recoil_direction = -facing.normalized() if facing.length_squared() > 0.01 else Vector2.UP
	queue_redraw()

func reset_feedback() -> void:
	feedback_skill_id = ""
	feedback_skill_label = ""
	feedback_prep_target = -1
	feedback_started_at = -100.0
	feedback_impact_at = -100.0
	feedback_trail_at = -100.0
	feedback_action_remaining = -1
	feedback_strike_at = -100.0
	feedback_impact_strength = 1.0
	passive_feedback_at = -100.0
	feedback_display_hp = 0.0
	feedback_trail_hp = 0.0
	queue_redraw()

func disk(p: Vector2, r: float, color: Color) -> void:
	draw_circle(p, r + 2.0, INK)
	draw_circle(p, r, color)

func shape(points: Array, color: Color) -> void:
	var polygon := PackedVector2Array(points)
	draw_colored_polygon(polygon, color)
	polygon.append(polygon[0])
	draw_polyline(polygon, INK, 3.0, true)

func _draw_cone(origin: Vector2, direction: Vector2, radius: float, angle_degrees: float, color: Color) -> void:
	var facing := direction.normalized()
	if facing.length_squared() < 0.01: return
	var half_angle := deg_to_rad(angle_degrees * 0.5)
	var start_angle := facing.angle() - half_angle
	var segments := 24
	var points := PackedVector2Array([origin])
	for index in range(segments + 1):
		var angle := start_angle + deg_to_rad(angle_degrees) * float(index) / float(segments)
		points.append(origin + Vector2.from_angle(angle) * radius)
	points.append(origin)
	draw_colored_polygon(points, color)
	draw_polyline(points, Color(color.r, color.g, color.b, 0.82), 2.5, true)

func _draw() -> void:
	if unit.is_empty(): return
	var team_color := Color("55d6cb") if unit.team == 0 else Color("ff9b79")
	if not unit.alive:
		if str(unit.id) == "hippo": return
		var age := clock - died_at
		if age < 0.65:
			var tex := Art.texture(str(unit.id))
			var dimensions := tex.get_size() * (65.0 / maxf(tex.get_width(), tex.get_height()))
			draw_set_transform(Vector2(0,8), minf(age * 3.0, 1.3), Vector2(last_facing, 1.0 - age * 0.7))
			draw_texture_rect(tex, Rect2(Vector2(-dimensions.x/2,-dimensions.y),dimensions),false,Color(1,1,1,1.0-age/0.65))
			draw_set_transform(Vector2.ZERO)
		return
	var definition: Resource = unit.definition
	var body: Color = definition.color
	var id: String = unit.id
	var traits: Array = Catalog.base_traits(id)
	var bob := sin(clock * 12.0 + unit.uid) * 2.0 if moving else sin(clock * 2.0 + unit.uid) * 0.7
	var facing: Vector2 = unit.get("facing", Vector2.UP)
	var action: Dictionary = unit.get("action", {})
	var skill: Resource = action.get("skill") if not action.is_empty() else null
	var action_direction: Vector2 = action.get("direction", facing)
	var turn_skunk: bool = "skunk" in traits and skill != null and skill.behavior in ["cloud", "trail"]
	if turn_skunk:
		facing = Vector2(unit.get("velocity", facing)).normalized() if skill.behavior == "trail" and moving else -action_direction
	if not definition.attack_enabled and moving:
		facing = Vector2(unit.get("velocity", facing)).normalized()
	var orientation := Vector2.UP.angle_to(facing.normalized()) if facing.length_squared() > 0.01 else 0.0
	if skill != null and skill.behavior == "cone" and int(action.get("remaining", 0)) > 0 and clock < float(action.get("next", 0)) / 60.0:
		var windup_origin: Vector2 = action.get("origin", unit.pos)
		var cone_radius := float(unit.definition.radius) + float(skill.range)
		var cone_angle := float(skill.cone_angle)
		_draw_cone(windup_origin - unit.pos, action_direction, cone_radius, cone_angle, Color(0.98,0.74,0.31,0.21))
	_draw_skill_prep(action)
	draw_set_transform(Vector2(0,10), 0, Vector2(1.25,0.4))
	draw_circle(Vector2.ZERO, 22, Color(0.08,0.17,0.15,0.23))
	draw_set_transform(Vector2.ZERO)
	draw_arc(Vector2(0,8), 26, 0, TAU, 28, team_color, 3.0, true)
	var offset := Vector2(0, bob - 7) + _feedback_recoil() + _skill_pose_offset(action)
	if unit.state == "dive": offset.y -= 14
	if "rabbit" in traits and bool(unit.get("motion_dive", false)):
		offset.y -= 12.0 + sin(clock * 25.0) * 2.0
	draw_set_transform(offset + Vector2(0,-20))
	var shield_hp := float(unit.get("shield_hp", 0.0))
	if shield_hp > 0.0:
		var shield_pulse := 0.5 + 0.5 * sin(clock * 4.0)
		draw_circle(Vector2.ZERO, 35.0 + shield_pulse * 1.5, Color(0.36,0.72,1.0,0.10))
		draw_arc(Vector2.ZERO, 35.0 + shield_pulse * 1.5, 0.0, TAU, 36, Color(0.48,0.82,1.0,0.72), 2.5, true)
	if float(unit.get("status_remaining", 0)) > 0:
		draw_arc(Vector2.ZERO, 32, clock, clock+4.5, 28, Color("b6df70"), 3, true)
	draw_set_transform(Vector2.ZERO)
	_draw_cartoon(action, facing, offset)
	_draw_skill_marks(action)
	if unit.state == "cast":
		draw_arc(Vector2.ZERO, 29, PI*1.05, PI*1.95, 18, Color("ffe190"), 4, true)
		draw_line(Vector2(23,-26),Vector2(29,-33),Color("ffe190"),3)
	if float(unit.get("flash",0)) > 0:
		draw_arc(Vector2.ZERO, 25, 0, TAU, 20, Color("fff5bd"), 4, true)
	draw_set_transform(Vector2.ZERO)
	_draw_shield_break()
	var name_text: String = definition.display_name
	if definition.level >= 2:
		var level_badge := "III" if definition.level >= 3 else "II"
		var badge_width := 21.0 if definition.level >= 3 else 16.0
		draw_style_box(_bar_style(Color("ffe190")),Rect2(-48,-61,badge_width,14))
		draw_string(ThemeDB.fallback_font,Vector2(-45,-50),level_badge,HORIZONTAL_ALIGNMENT_LEFT,-1,11,INK)
	var skill_bottom := 38.0
	draw_string(ThemeDB.fallback_font,Vector2(-ThemeDB.fallback_font.get_string_size(name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x/2,skill_bottom+12),name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,INK)
	var stun_left := float(unit.get("stun_remaining", 0.0))
	if float(unit.get("slow_multiplier", 1.0)) < 1.0:
		draw_arc(Vector2(0,12), 31, 0, TAU, 24, Color("91ad55"), 3.0)
	if float(unit.get("stagger_remaining", 0.0)) > 0:
		draw_string(ThemeDB.fallback_font,Vector2(-30,-50),"ZACHWIANIE",HORIZONTAL_ALIGNMENT_LEFT,-1,9,INK)
	if stun_left > 0.0:
		var star_center := Vector2(0,-45)
		for index in range(5):
			var angle := clock * 4.5 + TAU * float(index) / 5.0
			var star_position := star_center + Vector2.from_angle(angle) * (9.0 + sin(clock * 9.0 + index) * 2.0)
			draw_colored_polygon(_star_points(star_position, 5.0, 2.4), STUN_GOLD)
			draw_arc(star_position, 5.2, 0, TAU, 12, INK, 1.1, true)
		var stun_label := "OGŁUSZONY  %.1f s" % stun_left
		draw_style_box(_bar_style(Color("263044")), Rect2(-58,-72,116,18))
		draw_string(ThemeDB.fallback_font, Vector2(-54,-59), stun_label, HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff0af"))
	if clock - feedback_impact_at < 0.18:
		var recoil_mix := clampf(1.0 - (clock - feedback_impact_at) / 0.18, 0.0, 1.0)
		var recoil := feedback_recoil_direction * sin(recoil_mix * PI) * 8.0 * feedback_impact_strength
		draw_arc(recoil, 26.0 + (1.0 - recoil_mix) * 7.0, 0, TAU, 28, Color(1.0,0.91,0.58,recoil_mix*0.68*feedback_impact_strength), 2.0, true)

func _feedback_recoil() -> Vector2:
	var age := clock - feedback_impact_at
	if age < 0.0 or age >= 0.18: return Vector2.ZERO
	return feedback_recoil_direction * sin((1.0 - age / 0.18) * PI) * 8.0 * feedback_impact_strength

func _draw_skill_prep(action: Dictionary) -> void:
	var behavior := ""
	if not action.is_empty() and action.get("skill") != null:
		behavior = str(action.skill.behavior)
	if behavior.is_empty() and not feedback_skill_id.is_empty():
		behavior = FeedbackStyle.behavior([unit], 0, feedback_skill_id)
	if behavior.is_empty(): return
	var elapsed := maxf(0.0, clock - feedback_started_at)
	var pulse := 0.5 + 0.5 * sin(elapsed * 15.0)
	var tint := FeedbackStyle.color(behavior)
	match behavior:
		"dive":
			draw_arc(Vector2(0,9), 29.0 + pulse * 6.0, 0, TAU, 36, Color(1.0,0.76,0.30,0.65), 3.0, true)
			draw_arc(Vector2(0,9), 37.0 + pulse * 4.0, 0, TAU, 36, Color(1.0,0.91,0.59,0.32), 2.0, true)
			draw_line(Vector2(0,-52),Vector2(0,-37),Color(1.0,0.90,0.58,0.55+0.35*pulse),3.0)
		"heavy", "projectile":
			draw_arc(Vector2(0,-31), 16.0 + pulse * 4.0, 0, TAU, 24, Color(tint.r,tint.g,tint.b,0.4+0.3*pulse), 3.0, true)
			draw_circle(Vector2(0,-43), 3.0 + pulse*1.5, Color(1.0,0.96,0.68,0.6+0.35*pulse))
		"cone", "multi":
			draw_arc(Vector2.ZERO, 29.0 + pulse * 4.0, 0, TAU, 32, Color(tint.r,tint.g,tint.b,0.48+0.2*pulse), 3.0, true)
			if clock - feedback_strike_at < 0.16:
				var hit_mix := clampf(1.0 - (clock - feedback_strike_at) / 0.16, 0.0, 1.0)
				draw_arc(Vector2.ZERO, 34.0 + (1.0-hit_mix)*11.0, 0, TAU, 28, Color(1.0,0.95,0.68,hit_mix), 3.0, true)
		"dash":
			for index in range(3):
				var y := -14.0 - float(index)*8.0
				draw_line(Vector2(-12.0,y),Vector2(-3.0,y-3.0),Color(tint.r,tint.g,tint.b,0.35+0.45*pulse),2.0)
		"cloud", "debuff", "trail":
			draw_arc(Vector2.ZERO, 31.0 + pulse * 5.0, 0, TAU, 32, Color(tint.r,tint.g,tint.b,0.35+0.2*pulse), 2.5, true)

func _draw_skill_marks(action: Dictionary) -> void:
	var behavior := ""
	var remaining := feedback_action_remaining
	if not action.is_empty() and action.get("skill") != null:
		behavior = str(action.skill.behavior)
		remaining = int(action.get("remaining", remaining))
	if behavior in ["cone", "multi", "dive", "dash"]:
		var hit_count := 3
		if not action.is_empty() and action.get("skill") != null:
			if behavior == "dive": hit_count = int(action.skill.airborne_hits)
			elif behavior == "dash": hit_count = int(action.skill.followup_hits)
			else: hit_count = int(action.skill.hits)
		for index in range(3):
			var done := remaining >= 0 and index >= remaining
			var p := Vector2(-10.0 + float(index)*10.0, -37.0)
			if index >= hit_count: continue
			draw_circle(p, 3.0, Color("fff0af") if done else Color(1.0,0.65,0.25,0.85))

func _star_points(center: Vector2, outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(10):
		var radius := outer_radius if index % 2 == 0 else inner_radius
		points.append(center + Vector2.from_angle(-PI * 0.5 + TAU * float(index) / 10.0) * radius)
	return points

func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style

func _draw_overhead() -> void:
	if unit.is_empty() or not unit.alive: return
	var definition: Resource = unit.definition
	var team_color := Color("55d6cb") if unit.team == 0 else Color("ff9b79")
	var show_feedback_bar: bool = clock - feedback_impact_at < 0.52
	var hp_width := 56.0
	var hp_left := -hp_width * 0.5
	overhead.draw_style_box(_bar_style(INK), Rect2(hp_left,30,hp_width,9))
	var shield := float(unit.get("shield_hp", 0.0))
	var bar_max := maxf(float(definition.max_hp), float(unit.hp) + shield)
	var fraction := clampf(float(unit.hp) / bar_max,0,1)
	var hp_inset := 2.0
	var hp_inner_width := hp_width - hp_inset * 2.0
	var bar_y := 32.0
	var bar_height := 5.0
	var trail_fraction := clampf(feedback_trail_hp / bar_max, 0.0, 1.0)
	if show_feedback_bar and clock - feedback_trail_at < 0.52:
		var trail_mix := clampf(1.0 - (clock - feedback_trail_at) / 0.52, 0.0, 1.0)
		var eased_trail := lerpf(fraction, trail_fraction, trail_mix)
		if eased_trail > fraction:
			overhead.draw_style_box(_bar_style(Color("fff0a8")), Rect2(hp_left+hp_inset+hp_inner_width*fraction,bar_y,hp_inner_width*(eased_trail-fraction),bar_height))
	overhead.draw_style_box(_bar_style(team_color), Rect2(hp_left+hp_inset,bar_y,hp_inner_width*fraction,bar_height))
	if shield > 0.0:
		overhead.draw_style_box(_bar_style(Color("9de5ff")), Rect2(hp_left+hp_inset+hp_inner_width*fraction,bar_y,hp_inner_width*shield/bar_max,bar_height))


func _skill_pose_offset(action: Dictionary) -> Vector2:
	if action.is_empty() or action.get("skill") == null: return Vector2.ZERO
	if int(action.get("remaining", 0)) <= 0: return Vector2.ZERO
	var start := float(action.get("start", 0)) / 60.0
	var impact := float(action.get("next", 0)) / 60.0
	if clock >= impact or impact <= start: return Vector2.ZERO
	var progress := clampf((clock - start) / (impact - start), 0.0, 1.0)
	var direction: Vector2 = action.get("direction", unit.facing)
	return -direction.normalized() * progress * 6.0 + Vector2(0, -sin(progress * PI) * 3.0)

func _draw_shield_break() -> void:
	var age := clock - shield_break_at
	if age < 0.0 or age > 0.35: return
	var progress := age / 0.35
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		draw_arc(Vector2(0,-7), 36.0 + progress * 16.0, angle, angle + 0.55, 6, Color(0.48,0.82,1.0,1.0-progress), 3.0, true)

func _draw_cartoon(action: Dictionary, facing: Vector2, offset: Vector2) -> void:
	if str(unit.id) == "hippo": return
	if absf(facing.x) > 0.15: last_facing = 1.0 if facing.x > 0 else -1.0
	var pose := 0
	var windup := false
	if not action.is_empty():
		windup = clock < float(action.get("next", 0)) / 60.0
		pose = 1 if windup else 2
	if unit.state == "dive" or bool(unit.get("motion_dive", false)): pose = 2
	if clock - attack_at < 0.22 and not windup: pose = 2
	if celebrating: pose = 3
	var tex := Art.texture(str(unit.id), pose)
	var idle := Art.texture(str(unit.id))
	var level := int(unit.definition.level)
	var size_limit := 74.0 + (level - 1) * 9.0
	if str(unit.id) in ["hippo", "bear"]: size_limit = 82.0
	var ratio := size_limit / maxf(idle.get_width(), idle.get_height())
	var dimensions := tex.get_size() * ratio
	var bounce := absf(sin(clock * 11.0 + unit.uid)) if moving else 0.0
	var stretch := sin(clock * 11.0 + unit.uid) * 0.055 if moving else sin(clock * 2.8 + unit.uid) * 0.018
	var lean := sin(clock * 11.0 + unit.uid) * 0.045 if moving else 0.0
	if not action.is_empty() and action.skill.behavior == "shield_jump" and bool(action.get("flying", false)):
		var progress := clampf((clock * 60.0 - float(action.start)) / maxf(1.0, float(action.travel_end - action.start)), 0.0, 1.0)
		offset.y -= sin(progress * PI) * 28.0
	if windup:
		stretch = -0.10
		lean = -0.09 * last_facing
	if unit.state == "dive":
		stretch = 0.12
		lean = 0.18 * last_facing
	var hit_age := clock - attack_at
	if hit_age >= 0.0 and hit_age < 0.24:
		offset.x += last_facing * sin(hit_age / 0.24 * PI) * 7.0
	if float(unit.get("stun_remaining",0.0)) > 0.0:
		lean += sin(clock*8.0)*0.065
	var tint := Color.WHITE
	if float(unit.get("flash", 0)) > 0: tint = Color(1.25,0.8,0.65)
	draw_set_transform(Vector2(offset.x, 17.0 + offset.y - bounce * 4.0), lean, Vector2(last_facing * (1.0-stretch),1.0+stretch))
	draw_texture_rect(tex, Rect2(Vector2(-dimensions.x/2,-dimensions.y),dimensions),false,tint)
	draw_set_transform(Vector2.ZERO)
