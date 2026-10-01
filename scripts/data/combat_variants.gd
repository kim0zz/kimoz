class_name CombatVariants
extends RefCounted
## Immutable, deep-cloned combat definitions for the full-roster A/B comparison.

const Catalog = preload("res://scripts/data/catalog.gd")
const BASELINE_PATH := "res://resources/balance/full_roster_baseline.json"

static func definitions(variant: String) -> Dictionary:
	var normalized := variant.to_upper()
	if normalized not in ["A", "B"]:
		push_error("Unknown combat variant: %s" % variant)
		return {}
	var all_units: Dictionary = Catalog.load_units()
	var baseline: Dictionary = {}
	if normalized == "A":
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BASELINE_PATH))
		if not parsed is Dictionary or not parsed.has("units"):
			push_error("Missing or invalid full-roster baseline snapshot: " + BASELINE_PATH)
			return {}
		baseline = parsed.units
	var result: Dictionary = {}
	for id in Catalog.ids() + Catalog.hybrid_ids() + Catalog.lvl3_ids():
		if not all_units.has(id):
			push_error("No source definition for combat variant: " + id)
			continue
		var source: ZooUnitDefinition = all_units[id] as ZooUnitDefinition
		var unit: ZooUnitDefinition = source.duplicate(true)
		unit.skills.clear()
		for source_skill in source.skills:
			unit.skills.append(_clone_skill(source_skill))
		if normalized == "A" and unit.level < 3:
			if not baseline.has(id):
				push_error("No baseline numbers for combat variant: " + id)
				continue
			_restore_numbers(unit, baseline[id])
			if id == "rabbit": unit.skills[0].behavior = "dash"
			# Historical A predates the moving-smell redesign as well as the number pass.
			if id in ["skunk", "hedgehog_skunk", "skunk_rabbit"]:
				unit.role = "ranged"
				unit.attack_enabled = true
				for skill in unit.skills:
					if skill.behavior == "trail": skill.behavior = "cloud"
					if skill.behavior == "dash": skill.puff_interval = 0.0
		result[id] = unit
	return result

static func _restore_numbers(unit: ZooUnitDefinition, snapshot: Dictionary) -> void:
	var unit_numbers: Dictionary = snapshot.get("unit", {})
	for property_name in unit_numbers:
		unit.set(property_name, unit_numbers[property_name])
	var skill_numbers: Array = snapshot.get("skills", [])
	if skill_numbers.size() != unit.skills.size():
		push_error("Baseline skill count changed for: " + unit.id)
		return
	for index in unit.skills.size():
		var skill: ZooSkillDefinition = unit.skills[index]
		var numbers: Dictionary = skill_numbers[index]
		for property_name in numbers:
			skill.set(property_name, numbers[property_name])

static func _clone_skill(source: ZooSkillDefinition) -> ZooSkillDefinition:
	var copy := source.duplicate(true) as ZooSkillDefinition
	if source.followup_skill != null:
		copy.followup_skill = _clone_skill(source.followup_skill)
	return copy
