class_name ZooUnitDefinition
extends Resource

## Shared data only: never store current HP, cooldowns or targets here.
@export var id: String = ""
@export var display_name: String = ""
@export var level: int = 1
@export var parents: Array[String] = []
@export var visual_scale: float = 1.0
@export_enum("front", "melee", "ranged", "diver", "utility", "mobile") var role: String = "melee"
@export var max_hp: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_interval: float = 1.0
@export var attack_enabled: bool = true
@export var move_speed: float = 85.0
## World pixels measured between collision-circle edges.
@export var attack_range: float = 8.0
@export var radius: float = 24.0
@export var preferred_min: float = 0.0
@export var preferred_max: float = 8.0
## Ranged stops retreating once caught; a wider release distance prevents jitter.
@export var engage_distance: float = 12.0
@export var disengage_distance: float = 40.0
@export var color: Color = Color.WHITE
@export var projectile_color: Color = Color(1.0, 0.85, 0.3, 1.0)
@export var skills: Array[ZooSkillDefinition] = []

func basic_dps() -> float:
	return attack_damage / attack_interval if attack_interval > 0.0 else 0.0

func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty() or display_name.is_empty() or role not in ["front", "melee", "ranged", "diver", "utility", "mobile"]:
		errors.append("Invalid unit identity: %s" % id)
	if level < 1 or visual_scale <= 0.0:
		errors.append("Invalid level or visual scale: %s" % id)
	if level == 1 and not parents.is_empty():
		errors.append("Lvl1 cannot have parents: %s" % id)
	if level >= 2 and parents.size() != 2:
		errors.append("Hybrid requires two parents: %s" % id)
	if max_hp <= 0.0 or attack_damage <= 0.0 or attack_interval <= 0.0 or move_speed <= 0.0 or radius <= 0.0 or attack_range < 0.0:
		errors.append("Invalid positive stat: %s" % id)
	if preferred_min < 0.0 or preferred_max < preferred_min or preferred_max > attack_range:
		errors.append("Invalid preferred distance: %s" % id)
	if engage_distance < 0.0 or disengage_distance <= engage_distance:
		errors.append("Invalid engagement distance: %s" % id)
	var seen: Array[String] = []
	for skill in skills:
		if skill == null:
			errors.append("Null skill: %s" % id)
			continue
		if skill.id in seen:
			errors.append("Duplicate skill: %s/%s" % [id, skill.id])
		seen.append(skill.id)
		errors.append_array(skill.validate())
	return errors
