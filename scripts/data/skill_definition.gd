class_name ZooSkillDefinition
extends Resource

@export var id: String = ""
## Optional next phase; runs only after natural completion with the original living target.
@export var followup_skill: ZooSkillDefinition
@export var landing_cone: bool = false
@export var landing_cloud: bool = false
@export var stun_last_hit_only: bool = false
## Reactive dash may cancel a grounded cast, but never an airborne leg.
@export var interrupt_on_hit: bool = false
## Zero preserves historical use of hit_interval for cloud pulses.
@export var cloud_tick_interval: float = 0.0
@export_enum("heavy", "multi", "projectile", "dive", "dash", "thorns", "debuff", "cone", "cloud", "trail", "shield_jump") var behavior: String = "heavy"
@export var cone_angle: float = 100.0
@export var area_radius: float = 55.0
@export var stun_duration: float = 0.0
@export var aggro_duration: float = 1.0
@export var stagger_duration: float = 0.0
@export var slow_multiplier: float = 1.0
@export var cone_projectile_damage: float = 0.0
@export var impact_cloud: bool = false
@export var cloud_damage: float = 0.0
@export var cloud_stagger: float = 0.0
## Lifetime of each puff cloud; trail uptime/dash flight uses duration.
@export var cloud_duration: float = 3.0
## Spacing between clouds emitted along resolved movement.
@export var puff_interval: float = 0.5
@export_enum("rear", "farthest", "side") var dash_mode: String = "rear"
@export var followup_hits: int = 0
@export var followup_damage: float = 0.0
@export var followup_stun: float = 0.0
@export var followup_interval: float = 0.15
@export var target_rule: String = "nearest"
@export var airborne_hits: int = 1
@export var cooldown: float = 5.0
## Per-skill delay before the first use. Recurring uses still follow cooldown.
@export var initial_cooldown: float = 2.0
@export var windup: float = 0.3
@export var recovery: float = 0.3
@export var shield_amount: float = 0.0
@export var shield_duration: float = 4.0
@export var damage: float = 0.0
@export var hits: int = 1
@export var hit_interval: float = 0.15
## Ranges are edge-to-edge world pixels, including cloud/trigger radii.
@export var range: float = 8.0
@export var duration: float = 0.0
@export var distance: float = 0.0
@export var speed: float = 0.0
@export var status: ZooStatusDefinition

func validate() -> Array[String]:
	var errors: Array[String] = []
	if behavior == "shield_jump" and (shield_amount <= 0.0 or shield_duration <= 0.0 or duration <= 0.0):
		errors.append("Shield jump requires positive shield, lifetime and flight duration")
	if id.is_empty() or behavior not in ["heavy", "multi", "projectile", "dive", "dash", "thorns", "debuff", "cone", "cloud", "trail", "shield_jump"]:
		errors.append("Invalid skill identity: %s" % id)
	if cooldown < 0.0 or initial_cooldown < 0.0 or windup < 0.0 or recovery < 0.0 or damage < 0.0 or range < 0.0 or duration < 0.0 or distance < 0.0 or speed < 0.0:
		errors.append("Negative skill parameter: %s" % id)
	if hits < 1 or (hits > 1 and hit_interval <= 0.0):
		errors.append("Invalid hit sequence: %s" % id)
	if behavior in ["heavy", "multi", "projectile", "dive", "dash", "debuff", "cone", "cloud", "trail", "shield_jump"] and cooldown <= 0.0:
		errors.append("Repeated/conditional skill requires cooldown: %s" % id)
	if behavior in ["projectile", "dive", "dash"] and speed <= 0.0:
		errors.append("Movement/projectile requires speed: %s" % id)
	if behavior == "debuff" and status == null:
		errors.append("Debuff requires status: %s" % id)
	if status != null:
		errors.append_array(status.validate())
	if cone_angle <= 0 or cone_angle > 360 or area_radius <= 0 or stun_duration < 0 or aggro_duration < 0:
		errors.append("Invalid area/control parameter: %s" % id)
	if behavior == "cloud" and (duration <= 0 or hit_interval <= 0):
		errors.append("Cloud requires lifetime and pulse interval")
	if behavior == "trail" and (duration <= 0.0 or cloud_duration <= 0.0 or puff_interval <= 0.0 or hit_interval <= 0.0):
		errors.append("Trail requires active/cloud lifetime and pulse intervals: %s" % id)
	if behavior == "dash" and cloud_damage > 0.0 and puff_interval <= 0.0:
		errors.append("Dash puff interval must be positive: %s" % id)
	if impact_cloud and (duration <= 0 or hit_interval <= 0):
		errors.append("Impact cloud requires lifetime and pulse interval")
	if airborne_hits < 1 or followup_hits < 0 or followup_interval <= 0 or slow_multiplier <= 0 or slow_multiplier > 1:
		errors.append("Invalid hybrid timing/movement: %s" % id)
	if cloud_tick_interval < 0.0:
		errors.append("Negative cloud pulse interval: %s" % id)
	if followup_skill != null:
		errors.append_array(followup_skill.validate())
	return errors
