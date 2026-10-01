class_name ZooCatalog
extends RefCounted

static func ids() -> Array[String]:
	return ["bear", "cheetah", "monkey", "eagle", "hedgehog", "hippo", "skunk", "rabbit"]

## The original 12 lvl2 IDs. Keep this list stable for existing draft/UI callers.
static func hybrid_ids() -> Array[String]:
	return [
		"bear_cheetah", "bear_monkey", "bear_hedgehog", "cheetah_eagle",
		"cheetah_rabbit", "monkey_skunk", "monkey_hippo", "eagle_hedgehog",
		"eagle_hippo", "hippo_rabbit", "hedgehog_skunk", "skunk_rabbit",
	]

static func lvl3_ids() -> Array[String]:
	return [
		"lvl3_01", "lvl3_02", "lvl3_03", "lvl3_04", "lvl3_05", "lvl3_06",
		"lvl3_07", "lvl3_08", "lvl3_09", "lvl3_10", "lvl3_11", "lvl3_12",
	]

static func _unit_path(unit_id: String) -> String:
	if unit_id in ids():
		return "res://resources/units/%s.tres" % unit_id
	if unit_id in hybrid_ids():
		return "res://resources/hybrids/%s.tres" % unit_id
	if unit_id in lvl3_ids():
		return "res://resources/lvl3/%s.tres" % unit_id
	return ""

static func _load_unit(unit_id: String) -> ZooUnitDefinition:
	var path := _unit_path(unit_id)
	return load(path) as ZooUnitDefinition if not path.is_empty() else null

static func fusion(parent_a: String, parent_b: String) -> String:
	if parent_a == parent_b:
		return ""
	for unit_id in hybrid_ids() + lvl3_ids():
		var definition := _load_unit(unit_id)
		if definition != null and definition.parents.size() == 2:
			if (definition.parents[0] == parent_a and definition.parents[1] == parent_b) or (definition.parents[0] == parent_b and definition.parents[1] == parent_a):
				return unit_id
	return ""

static func base_traits(unit_id: String) -> Array[String]:
	var result: Array[String] = []
	_collect_base_traits(unit_id, result, [])
	return result

static func _collect_base_traits(unit_id: String, result: Array[String], visiting: Array[String]) -> void:
	if unit_id in visiting:
		return
	var definition := _load_unit(unit_id)
	if definition == null:
		return
	if definition.level == 1:
		if unit_id not in result:
			result.append(unit_id)
		return
	var next_visiting := visiting.duplicate()
	next_visiting.append(unit_id)
	for parent_id in definition.parents:
		_collect_base_traits(parent_id, result, next_visiting)

static func load_units() -> Dictionary:
	var definitions: Dictionary = {}
	for unit_id in ids() + hybrid_ids() + lvl3_ids():
		var definition := _load_unit(unit_id)
		if definition == null:
			push_error("Missing unit definition: %s" % unit_id)
			continue
		definitions[unit_id] = definition
	return definitions

static func presets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for preset_id in ["mixed_six", "front_ranged", "dive_backline", "thorns", "dash_heavy", "utility", "mirror_six", "mobile_three"]:
		var preset := load("res://resources/matches/%s.tres" % preset_id) as ZooMatchDefinition
		if preset != null:
			result.append(preset.as_dictionary())
	return result

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var units := load_units()
	for unit_id in ids():
		if not units.has(unit_id):
			errors.append("Missing unit: %s" % unit_id)
			continue
		var definition: ZooUnitDefinition = units[unit_id]
		if definition.id != unit_id or definition.level != 1 or definition.skills.size() != 1 or not definition.parents.is_empty():
			errors.append("Lvl1 identity / one-skill contract: %s" % unit_id)
		errors.append_array(definition.validate())
	for hybrid_id in hybrid_ids():
		if not units.has(hybrid_id):
			errors.append("Missing hybrid: %s" % hybrid_id)
			continue
		var hybrid: ZooUnitDefinition = units[hybrid_id]
		if hybrid.id != hybrid_id or hybrid.level != 2 or hybrid.skills.is_empty():
			errors.append("Lvl2 identity / level / skill contract: %s" % hybrid_id)
		if hybrid.parents.size() != 2 or fusion(hybrid.parents[0], hybrid.parents[1]) != hybrid_id:
			errors.append("Lvl2 parents do not match fusion matrix: %s" % hybrid_id)
		errors.append_array(hybrid.validate())
	var partner_counts: Dictionary = {}
	for hybrid_id in hybrid_ids():
		partner_counts[hybrid_id] = 0
	for lvl3_id in lvl3_ids():
		if not units.has(lvl3_id):
			errors.append("Missing lvl3: %s" % lvl3_id)
			continue
		var lvl3: ZooUnitDefinition = units[lvl3_id]
		if lvl3.id != lvl3_id or lvl3.level != 3 or lvl3.skills.is_empty():
			errors.append("Lvl3 identity / level / inherited-skill contract: %s" % lvl3_id)
		if lvl3.parents.size() != 2 or fusion(lvl3.parents[0], lvl3.parents[1]) != lvl3_id:
			errors.append("Lvl3 parents do not match fusion matrix: %s" % lvl3_id)
		elif lvl3.parents[0] in partner_counts and lvl3.parents[1] in partner_counts:
			partner_counts[lvl3.parents[0]] += 1
			partner_counts[lvl3.parents[1]] += 1
		var traits := base_traits(lvl3_id)
		if traits.size() != 4:
			errors.append("Lvl3 must have four distinct base traits: %s" % lvl3_id)
		if lvl3.parents.size() == 2:
			var parent_traits := base_traits(lvl3.parents[0])
			var other_traits := base_traits(lvl3.parents[1])
			for base_trait in parent_traits:
				if base_trait in other_traits:
					errors.append("Lvl3 parents share a base trait: %s" % lvl3_id)
					break
		errors.append_array(lvl3.validate())
	for hybrid_id in hybrid_ids():
		if partner_counts.get(hybrid_id, 0) != 2:
			errors.append("Lvl2 must have exactly two lvl3 partners: %s" % hybrid_id)
	return errors
