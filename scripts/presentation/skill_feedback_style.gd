extends RefCounted
## Shared, data-driven presentation mapping for skill feedback.

const COLORS := {
	"shield_jump": Color("9de5ff"),
	"heavy": Color("ffd166"),
	"multi": Color("ffe190"),
	"projectile": Color("ffe66d"),
	"dive": Color("ff9d4d"),
	"dash": Color("79d8d0"),
	"thorns": Color("d5a1e0"),
	"debuff": Color("b6df70"),
	"cone": Color("ffbd55"),
	"trail": Color("a8cf61"),
	"cloud": Color("a8cf61")
}

const LABELS := {
	"shield_jump": "SKOK Z OSŁONĄ",
	"heavy": "CIĘŻKI CIOS",
	"multi": "SERIA",
	"projectile": "RZUT",
	"dive": "DESANT",
	"dash": "DOSKOK",
	"thorns": "KOLCE",
	"debuff": "OSŁABIENIE",
	"cone": "ZAMACH",
	"trail": "SMRÓD W RUCHU",
	"cloud": "CHMURA"
}

static func skill(units: Array, source: int, skill_id: String) -> Resource:
	if source < 0 or source >= units.size() or skill_id.is_empty(): return null
	var definition: Resource = units[source].get("definition")
	if definition == null: return null
	for candidate: Resource in definition.skills:
		var phase: Resource = candidate
		while phase != null:
			if phase.id == skill_id: return phase
			phase = phase.followup_skill
	return null

static func behavior(units: Array, source: int, skill_id: String, fallback: String = "") -> String:
	var definition := skill(units, source, skill_id)
	return str(definition.behavior) if definition != null else fallback

static func color(behavior_id: String) -> Color:
	return COLORS.get(behavior_id, Color("ffe190"))

static func label(behavior_id: String) -> String:
	return LABELS.get(behavior_id, "SKILL")

static func is_passive(behavior_id: String) -> bool:
	return behavior_id == "thorns"

static func is_strong(behavior_id: String) -> bool:
	return behavior_id in ["heavy", "dive", "projectile"]
