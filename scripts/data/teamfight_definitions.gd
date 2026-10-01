class_name TeamfightDefinitions
extends RefCounted
## Isolated Combat Lab roster. Every returned unit and skill is a deep clone.

const Catalog = preload("res://scripts/data/catalog.gd")

const ROLE_BY_ID := {
	"hippo": "hippo_tank",
	"monkey": "monkey_healer",
	"hedgehog": "hedgehog_shield",
	"cheetah": "cheetah_dps",
	"skunk": "skunk_controller",
	"eagle": "eagle_assassin",
}

const SKILL_SPECS := {
	"tf_hippo_taunt": {"kind": "taunt", "label": "Wezwanie + osłona", "display": "Zew frontu", "cooldown": 7.0, "initial": 1.2, "windup": 0.35, "range": 185.0},
	"tf_hippo_guard": {"kind": "guard", "label": "Osłona", "display": "Ciało za drużynę", "cooldown": 9.0, "initial": 3.0, "windup": 0.35, "range": 130.0},
	"tf_monkey_heal": {"kind": "heal", "label": "Leczenie", "display": "Bananowa apteczka", "cooldown": 5.0, "initial": 1.0, "windup": 0.45, "range": 260.0},
	"tf_monkey_cry": {"kind": "interrupt", "label": "Krzyk przerywający", "display": "Pisk", "cooldown": 8.0, "initial": 2.5, "windup": 0.25, "range": 150.0},
	"tf_hedgehog_shield": {"kind": "shield", "label": "Tarcza z kolców", "display": "Kolczasta osłona", "cooldown": 6.5, "initial": 1.5, "windup": 0.3, "range": 130.0},
	"tf_hedgehog_peel": {"kind": "peel", "label": "Odpędzenie", "display": "Zostaw ich!", "cooldown": 7.5, "initial": 3.0, "windup": 0.25, "range": 105.0},
	"tf_cheetah_flurry": {"kind": "flurry", "label": "Seria pazurów", "display": "Cztery łapy", "cooldown": 5.5, "initial": 1.0, "windup": 0.25, "range": 18.0},
	"tf_cheetah_finisher": {"kind": "finisher", "label": "Dobitka", "display": "Dobitka", "cooldown": 8.0, "initial": 3.2, "windup": 0.55, "range": 22.0},
	"tf_skunk_cloud": {"kind": "trail", "label": "Spowalniający ślad", "display": "Strefa smrodu", "cooldown": 6.0, "initial": 1.5, "windup": 0.3, "range": 155.0},
	"tf_skunk_stun": {"kind": "area_stun", "label": "Ogłuszająca chmura", "display": "Nosowy nokaut", "cooldown": 10.0, "initial": 4.0, "windup": 0.45, "range": 140.0},
	"tf_eagle_dive": {"kind": "dive", "label": "Nurkowanie", "display": "Zrzut z nieba", "cooldown": 7.5, "initial": 1.5, "windup": 0.3, "range": 8.0},
	"tf_eagle_evade": {"kind": "evade", "label": "Unik w bok", "display": "Unik w bok", "cooldown": 6.0, "initial": 0.8, "windup": 0.25, "range": 120.0},
}

# Effect strengths live with the prototype data, independently of AI decisions.
const EFFECTS := {
	"tf_hippo_taunt": {"shield":18.0, "duration":2.2},
	"tf_hippo_guard": {"self_shield":16.0, "shield":24.0},
	"tf_monkey_heal": {"heal":27.0},
	"tf_monkey_cry": {"stun":0.35},
	"tf_hedgehog_shield": {"shield":28.0},
	"tf_hedgehog_peel": {"stun":0.4},
	"tf_cheetah_flurry": {"damage":7.5},
	"tf_cheetah_finisher": {"damage":19.0, "bonus":10.0},
	"tf_skunk_stun": {"stun":0.55},
}

static func strength(skill_id: String, key: String) -> float:
	return float(EFFECTS.get(skill_id, {}).get(key, 0.0))

static func definitions() -> Dictionary:
	var source: Dictionary = Catalog.load_units()
	var result: Dictionary = {}
	for unit_id: String in ROLE_BY_ID:
		var original: Resource = source.get(unit_id)
		if original == null:
			continue
		var unit: Resource = original.duplicate(true)
		unit.skills.clear()
		for spec_id: String in _skill_ids_for(unit_id):
			unit.skills.append(_make_skill(spec_id))
		_configure_unit(unit)
		result[unit_id] = unit
	return result

static func presets() -> Array[Dictionary]:
	return [
		{"name": "Teamfight • front i leczenie", "teamfight": true, "a": ["hippo", "monkey", "cheetah"], "b": ["hippo", "skunk", "eagle"]},
		{"name": "Teamfight • asasyni kontra osłona", "teamfight": true, "a": ["hippo", "monkey", "hedgehog"], "b": ["eagle", "cheetah", "skunk"]},
		{"name": "Teamfight • lustrzane drużyny", "teamfight": true, "a": ["hippo", "cheetah", "skunk"], "b": ["hippo", "cheetah", "skunk"]},
	]

static func descriptions() -> Dictionary:
	var result: Dictionary = {}
	for skill_id: String in SKILL_SPECS:
		result[skill_id] = SKILL_SPECS[skill_id].duplicate(true)
	return result

static func skill_spec(skill_id: String) -> Dictionary:
	return SKILL_SPECS.get(skill_id, {}).duplicate(true)

static func role(unit_id: String) -> String:
	return str(ROLE_BY_ID.get(unit_id, ""))

static func skill_ids_for(unit_id: String) -> Array[String]:
	return _skill_ids_for(unit_id)

static func _skill_ids_for(unit_id: String) -> Array[String]:
	match unit_id:
		"hippo": return ["tf_hippo_taunt", "tf_hippo_guard"]
		"monkey": return ["tf_monkey_heal", "tf_monkey_cry"]
		"hedgehog": return ["tf_hedgehog_shield", "tf_hedgehog_peel"]
		"cheetah": return ["tf_cheetah_flurry", "tf_cheetah_finisher"]
		"skunk": return ["tf_skunk_cloud", "tf_skunk_stun"]
		"eagle": return ["tf_eagle_dive", "tf_eagle_evade"]
	return []

static func _make_skill(skill_id: String) -> Resource:
	var spec: Dictionary = SKILL_SPECS[skill_id]
	var skill := preload("res://scripts/data/skill_definition.gd").new()
	skill.id = skill_id
	skill.set_meta("teamfight_label", str(spec.label))
	# The mode simulation owns effects; Resource behaviors only provide valid timing/readiness data.
	skill.behavior = "heavy"
	skill.cooldown = float(spec.cooldown)
	skill.initial_cooldown = float(spec.initial)
	skill.windup = float(spec.windup)
	skill.recovery = 0.3
	skill.damage = 0.0
	skill.hits = 1
	skill.hit_interval = 0.15
	skill.range = float(spec.range)
	if skill_id == "tf_eagle_dive":
		skill.behavior = "dive"
		skill.target_rule = "farthest"
		skill.speed = 480.0
		skill.damage = 25.0
		skill.stun_duration = 0.15
	elif skill_id == "tf_cheetah_flurry":
		skill.hits = 4
		skill.hit_interval = 0.11
	elif skill_id == "tf_skunk_cloud":
		skill.behavior = "trail"
		skill.duration = 3.5
		skill.cloud_duration = 2.7
		skill.puff_interval = 0.45
		skill.range = 100.0
		skill.hit_interval = 0.55
		skill.cloud_tick_interval = 0.55
		skill.area_radius = 78.0
		skill.slow_multiplier = 0.68
		skill.cloud_damage = 5.0
	return skill

static func _configure_unit(unit: Resource) -> void:
	match unit.id:
		"hippo":
			unit.role = "front"
			unit.max_hp = 240.0
			unit.attack_damage = 7.0
			unit.attack_interval = 1.2
			unit.move_speed = 57.0
			unit.attack_range = 8.0
			unit.radius = 32.0
		"monkey":
			unit.role = "ranged"
			unit.max_hp = 92.0
			unit.attack_damage = 4.5
			unit.attack_interval = 1.15
			unit.move_speed = 72.0
			unit.attack_range = 230.0
			unit.preferred_min = 130.0
			unit.preferred_max = 200.0
		"hedgehog":
			unit.role = "front"
			unit.max_hp = 145.0
			unit.attack_damage = 3.0
			unit.attack_interval = 1.2
			unit.move_speed = 78.0
		"cheetah":
			unit.role = "melee"
			unit.max_hp = 82.0
			unit.attack_damage = 5.0
			unit.attack_interval = 0.55
			unit.move_speed = 132.0
		"skunk":
			unit.role = "mobile"
			unit.max_hp = 94.0
			unit.attack_damage = 3.2
			unit.attack_interval = 1.2
			unit.move_speed = 95.0
			unit.attack_enabled = false
			unit.attack_range = 155.0
			unit.preferred_min = 65.0
			unit.preferred_max = 105.0
		"eagle":
			unit.role = "diver"
			unit.max_hp = 78.0
			unit.attack_damage = 4.0
			unit.attack_interval = 0.72
			unit.move_speed = 112.0
