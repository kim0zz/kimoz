extends Node2D
signal cue(kind: String, at: float)
var swish_start := -1
var smear := 0.0
## Cutout animation. Samples simulation time; never moves the gameplay body.
const SHEET = preload("res://assets/cartoon/hippo/parts.png")
const FACES = preload("res://assets/cartoon/hippo/faces.png")
const FACE_REGIONS = [Rect2(194,177,675,522), Rect2(987,177,674,524)]
const REGIONS = [Rect2(54,91,423,319),Rect2(550,109,339,268),Rect2(943,116,361,277),Rect2(1376,99,347,320),Rect2(149,493,218,319),Rect2(544,491,250,321),Rect2(1033,556,146,188),Rect2(1430,601,253,117)]
var pieces: Dictionary = {}
var textures: Array[AtlasTexture] = []
var torso: Node2D
var head: Node2D
var head_sprite: Sprite2D
var elapsed := 0.0
var facing_sign := 1.0
var gait := 0.0
var walk_blend := 0.0
var previous_time := -1.0
var previous_position := Vector2.ZERO
var strike_at := -100.0
var strike_heavy := false
var hurt_at := -100.0
var death_at := -1.0
var last_skill_start := -1
var impact_fx_at := -100.0
var phase_name := "Spoczynek"
var dust_steps: Array[Vector3] = []
var last_step := -1

func _ready() -> void:
	for rect: Rect2 in REGIONS:
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		atlas.region = rect
		atlas.filter_clip = true
		textures.append(atlas)
	for rect: Rect2 in FACE_REGIONS:
		var atlas := AtlasTexture.new()
		atlas.atlas = FACES
		atlas.region = rect
		atlas.filter_clip = true
		textures.append(atlas)
	# Far legs and tail behind the barrel; near legs overlap the shoulder.
	_part("far_rear",5,Vector2(20,33),Vector2(10,4),Color("b8a5c5"))
	_part("far_front",4,Vector2(19,34),Vector2(8,4),Color("b8a5c5"))
	_part("tail",7,Vector2(23,12),Vector2(21,6))
	torso = _part("torso",0,Vector2(69,49),Vector2(34,24))
	_part("rear",5,Vector2(25,35),Vector2(12,5))
	_part("front",4,Vector2(22,35),Vector2(9,5))
	head = _part("head",1,Vector2(56,45),Vector2(14,32))
	head_sprite = head.get_child(0)

func _part(key: String, index: int, size_px: Vector2, pivot: Vector2, tint: Color = Color.WHITE) -> Node2D:
	var joint := Node2D.new()
	joint.name = key
	add_child(joint)
	var sprite := Sprite2D.new()
	sprite.texture = textures[index]
	sprite.centered = false
	sprite.position = -pivot
	sprite.scale = size_px / textures[index].get_size()
	sprite.modulate = tint
	joint.add_child(sprite)
	pieces[key] = joint
	return joint

func source_event(event: Dictionary, at: float) -> void:
	if event.get("kind", "") != "damage" or float(event.get("amount",0)) <= 0: return
	if event.get("damage_kind", "") not in ["basic", "skill"]: return
	strike_at = at
	strike_heavy = event.get("damage_kind", "") == "skill"
	if strike_heavy:
		impact_fx_at = at
		cue.emit("impact", at)

func target_event(event: Dictionary, at: float) -> void:
	if event.get("kind", "") == "damage" and float(event.get("amount",0)) > 0:
		# DOT remains a subtle flinch instead of restarting the full hit reaction.
		if event.get("damage_kind", "") != "dot" or at-hurt_at > 0.5:
			hurt_at = at
			cue.emit("hurt", at)

func sample(unit: Dictionary, at: float, winner: bool = false) -> void:
	if not is_node_ready(): return
	var dt := clampf(at-previous_time,0.0,0.1) if previous_time >= 0 else 0.0
	if previous_time > at:
		strike_at = -100.0
		hurt_at = -100.0
		impact_fx_at = -100.0
		death_at = -1.0
		last_skill_start = -1
		swish_start = -1
		dust_steps.clear()
		gait = 0.0
	previous_time = at
	elapsed = at
	smear = 0.0
	var pos: Vector2 = unit.get("pos",Vector2.ZERO)
	var distance := pos.distance_to(previous_position) if dt > 0.0 else 0.0
	previous_position = pos
	var direction: Vector2 = unit.get("facing",Vector2.RIGHT)
	var action: Dictionary = unit.get("action",{})
	var stunned := float(unit.get("stun_remaining",0.0)) > 0.0
	var alive := bool(unit.get("alive",true))
	z_index = 2 if alive and not stunned and not action.is_empty() else 0
	if action.is_empty() and absf(direction.x)>0.2: facing_sign = signf(direction.x)
	if not action.is_empty():
		var heading: Vector2 = action.get("direction",direction)
		if absf(heading.x)>0.2: facing_sign = signf(heading.x)
	var walking := alive and not stunned and action.is_empty() and distance>0.02
	walk_blend = move_toward(walk_blend,1.0 if walking else 0.0,dt*8.0)
	# Stride follows travelled distance instead of a free-running sine wave.
	if walking: gait += minf(distance,12.0)*0.15
	phase_name = "Chód" if walking else "Spoczynek"
	var step := int(gait / PI)
	if walking and step != last_step:
		last_step = step
		cue.emit("step", at)
		dust_steps.append(Vector3(-22 if step%2==0 else 17,8,at))
	dust_steps = dust_steps.filter(func(p: Vector3) -> bool: return at-p.z<0.38)
	var breath := sin(at*2.3)
	var body_pos := Vector2(-10,-29 + breath*0.65 - absf(sin(gait))*1.7*walk_blend)
	var body_scale := Vector2(1.0+breath*0.014,1.0-breath*0.011)
	var body_angle := sin(gait)*0.028*walk_blend
	var head_pos := Vector2(12,-37 + sin(at*2.3-0.45)*0.5)
	var head_angle := sin(gait-0.6)*0.045*walk_blend
	var front_lift := 0.0
	var front_swing := 0.0
	var face := 1
	var head_scale := Vector2.ONE
	var body_shift := Vector2.ZERO
	var cast_is_support := false
	if not action.is_empty() and action.get("skill") != null and alive and not stunned:
		var skill: Resource = action.skill
		cast_is_support = str(skill.id).begins_with("tf_")
		var start := float(action.get("start",0))/60.0
		var impact := start + float(skill.windup)
		var progress := clampf((at-start)/maxf(float(skill.windup),0.001),0.0,1.0)
		if at < impact:
			phase_name = "Osłona / zew" if cast_is_support else "Zamach"
			face = 3 if cast_is_support else 2
			var load_up := smoothstep(0.0,0.72,progress)
			var launch := pow(clampf((progress-0.78)/0.22,0.0,1.0),3.0)
			body_shift = Vector2(-7.0*load_up + 16.0*launch,4.0*load_up - 2.0*launch)
			body_scale = Vector2(1.0+0.07*load_up,1.0-0.11*load_up)
			body_angle = -0.07*load_up + 0.11*launch
			head_pos += Vector2(-5.0*load_up+15.0*launch,-5.0*load_up+9.0*launch)
			head_angle = -0.20*load_up+0.42*launch
			front_lift = sin(progress*PI)*14.0
			front_swing = -0.70*sin(progress*PI)
			if cast_is_support:
				body_shift *= 0.35
				head_angle = -0.12*load_up
				head_pos.y -= 3.0*load_up
			if int(action.get("start",0)) != last_skill_start:
				last_skill_start = int(action.get("start",0))
				if not cast_is_support: cue.emit("grunt", at)
			if not cast_is_support and progress > 0.78:
				smear = sin((progress-0.78)/0.22*PI)
				if swish_start != last_skill_start:
					swish_start = last_skill_start
					cue.emit("swish", at)
		elif int(action.get("remaining",0)) == 0:
			# Recovery also exists for misses; hit sparks only use confirmed damage.
			var recovery_age := at-impact
			var recoil := exp(-recovery_age*7.0)*sin(recovery_age*24.0)
			body_shift = Vector2(8.0*exp(-recovery_age*9.0),recoil*2.0)
			body_scale = Vector2(1.0+recoil*0.09,1.0-recoil*0.10)
			head_pos += Vector2(7.0*exp(-recovery_age*10.0),recoil*2.5)
			head_angle = 0.16*exp(-recovery_age*8.0)
			phase_name = "Powrót po ciosie"
	var hit_age := at-strike_at
	if strike_heavy and hit_age>=0.0: hit_age=maxf(0.0,hit_age-0.045)
	if hit_age>=0.0 and hit_age<0.36 and alive and not stunned:
		var punch := exp(-hit_age*10.0)
		phase_name = "Ciężki cios" if strike_heavy else "Zwykły cios"
		face = 2
		head_pos.x += punch*(8.0 if strike_heavy else 5.0)
		head_angle += punch*0.12
		if strike_heavy:
			body_scale += Vector2(0.10,-0.10)*punch
			body_shift.y += 4.0*punch
		else:
			front_swing -= punch*0.5
			front_lift += punch*5.0
	var hurt_age := at-hurt_at
	if hurt_age>=0.0 and hurt_age<0.30 and alive:
		var flinch := sin(hurt_age/0.30*PI)*exp(-hurt_age*4.0)
		body_shift.x -= flinch*4.0
		head_angle -= flinch*0.16
		head_pos.x -= flinch*3.0
		if hit_age>0.36 and action.is_empty(): face = 9
		phase_name = "Oberwanie" if action.is_empty() else phase_name
	if stunned and alive:
		phase_name = "Ogłuszenie"
		face = 9
		body_angle = sin(at*4.0)*0.035
		head_angle = 0.16+sin(at*6.0)*0.04
		head_pos.y += 5.0
		walk_blend = 0.0
	if winner and alive:
		phase_name = "Radość"
		face = 3
		body_shift.y -= absf(sin(at*7.0))*4.0
		head_angle = -0.12
		front_lift = 10.0+sin(at*7.0)*3.0
		front_swing = -0.5
	if not alive:
		if death_at<0.0: death_at=at
		phase_name = "Porażka"
		var fall := clampf((at-death_at)/0.6,0.0,1.0)
		rotation = -smoothstep(0.0,1.0,fall)*0.95*facing_sign
		position = Vector2(-fall*13.0*facing_sign,fall*18.0)
		modulate.a = 1.0-smoothstep(0.6,1.2,at-death_at)
		face = 3
		walk_blend=0.0
	else:
		death_at=-1.0
		rotation=0.0
		position=Vector2.ZERO
		modulate=Color.WHITE
	scale = Vector2(facing_sign,1.0)
	_set_leg("far_rear",Vector2(-24,-25),gait+PI,walk_blend,body_shift,0.0,0.0)
	_set_leg("far_front",Vector2(15,-25),gait,walk_blend,body_shift,front_lift*0.4,front_swing*0.4)
	_set_leg("rear",Vector2(-29,-22),gait,walk_blend,body_shift,0.0,0.0)
	_set_leg("front",Vector2(9,-22),gait+PI,walk_blend,body_shift,front_lift,front_swing)
	torso.position=body_pos+body_shift
	torso.scale=body_scale
	torso.rotation=body_angle
	head.position=head_pos+body_shift
	head.rotation=head_angle
	head.scale=head_scale
	if face == 1 and fmod(at+0.6,3.7)<0.13: face = 8
	head_sprite.texture=textures[face]
	head_sprite.scale=Vector2(56,45)/textures[face].get_size()
	var tail: Node2D=pieces.tail
	tail.position=Vector2(-38,-31)+body_shift*0.7
	tail.rotation=0.2+sin(at*5.0-0.6)*0.20+body_angle*1.8
	queue_redraw()

func _set_leg(key: String, rest: Vector2, phase: float, blend: float, shift: Vector2, lift: float, swing: float) -> void:
	var joint: Node2D = pieces[key]
	var cycle := sin(phase)
	joint.position = rest+Vector2(cycle*3.0,-maxf(0.0,cos(phase))*5.0)*blend+shift*0.45-Vector2(0,lift)
	joint.rotation = cycle*0.25*blend+swing

func _draw() -> void:
	for puff: Vector3 in dust_steps:
		var age := (elapsed-puff.z)/0.38
		for i in range(3):
			draw_circle(Vector2(puff.x-age*(5+i*3),puff.y-age*(2+i)),1.5+age*2.5,Color(0.85,0.73,0.48,(1.0-age)*0.30))
	if smear > 0.0:
		for i in range(3):
			draw_arc(Vector2(5,-28),35.0+i*4.0,-1.0,0.65,20,Color(1,0.94,0.74,smear*(0.65-i*0.15)),3.5-i,true)
