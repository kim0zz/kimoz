extends RefCounted
## Read-only presentation of the simulation's tick-based cooldown deadlines.

static func rows(unit: Dictionary, elapsed: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if unit.is_empty(): return result
	for skill: Resource in unit.definition.skills:
		var passive: bool = skill.behavior == "thorns"
		var deadline: float = float(unit.get("cooldowns", {}).get(skill.id, 0)) / 60.0
		var remaining: float = maxf(0.0, deadline - elapsed)
		var used: int = int(unit.get("skills_used", {}).get(skill.id, 0))
		# The first deadline uses this skill's initial delay, not its recurring cooldown.
		var duration: float = deadline if used == 0 else float(skill.cooldown)
		var progress: float = clampf(1.0 - remaining / maxf(duration, 0.000001), 0.0, 1.0)
		var action: Dictionary = unit.get("action", {})
		var casting: bool = false
		var phase: Resource = skill
		while phase != null:
			if not action.is_empty() and action.skill.id == phase.id: casting = true
			phase = phase.followup_skill
		result.append({"id":skill.id, "name":skill_name(skill), "passive":passive,
			"remaining":remaining, "progress":progress, "ready":remaining <= 0.000001,
			"casting":casting, "conditional":skill.behavior == "dash"})
	return result

static func skill_name(skill: Resource) -> String:
	if skill.has_meta("teamfight_label"): return str(skill.get_meta("teamfight_label"))
	match skill.behavior:
		"cone": return "Zamach"
		"multi": return "Seria"
		"heavy": return "Ciężki cios"
		"projectile": return "Banan"
		"dive": return "Skok"
		"dash": return "Doskok" if skill.dash_mode == "farthest" else "Unik"
		"trail": return "Ślad smrodu"
		"cloud": return "Chmura"
		"thorns": return "Kolce"
	return "Skill"
