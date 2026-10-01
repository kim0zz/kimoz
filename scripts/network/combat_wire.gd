extends RefCounted
## Converts combat runtime state to transport-safe dictionaries and restores local Resources.

const VECTOR_TAG := "__combat_wire_vector2"
const SKILL_TAG := "__combat_wire_skill"
const STATUS_TAG := "__combat_wire_status"

static func capture(sim: CombatSimulation) -> Dictionary:
	var snapshot: Dictionary = {
		"version": 1,
		"tick": sim.tick,
		"time": sim.time,
		"result": sim.result,
		"first_hit_time": sim.first_hit_time,
		"seed_value": sim.seed_value,
		"trace_enabled": sim.trace_enabled,
		"skills_disabled": sim.skills_disabled,
		"startup_ready_tick": sim.startup_ready_tick,
		"ending_1v1_time": sim.ending_1v1_time,
		"ending_1v1": sim.ending_1v1,
		"next_projectile": sim._next_projectile,
		"units": [],
		"projectiles": [],
		"clouds": _pack(sim.clouds),
		"cloud_damage_ready": _pack(sim.cloud_damage_ready),
		"pending_status": _pack(sim._pending_status),
	}
	for unit: Dictionary in sim.units:
		var packed_unit: Dictionary = {}
		for key in unit:
			if key == "definition":
				continue
			packed_unit[key] = _pack(unit[key], str(unit.get("id", "")))
		snapshot.units.append(packed_unit)
	for projectile: Dictionary in sim.projectiles:
		var packed_projectile: Dictionary = {}
		var owner_id := ""
		var source := int(projectile.get("source", -1))
		if source >= 0 and source < sim.units.size():
			owner_id = str(sim.units[source].get("id", ""))
		for key in projectile:
			if key == "definition":
				var definition: Resource = projectile[key]
				packed_projectile["definition"] = _pack(definition, owner_id)
			else:
				packed_projectile[key] = _pack(projectile[key], owner_id)
		snapshot.projectiles.append(packed_projectile)
	return snapshot

static func apply(sim: CombatSimulation, snapshot: Dictionary, definitions: Dictionary) -> void:
	if sim == null or snapshot.is_empty():
		return
	sim.tick = int(snapshot.get("tick", 0))
	sim.time = float(snapshot.get("time", 0.0))
	sim.result = str(snapshot.get("result", "running"))
	sim.first_hit_time = float(snapshot.get("first_hit_time", -1.0))
	sim.seed_value = int(snapshot.get("seed_value", 1))
	sim.trace_enabled = bool(snapshot.get("trace_enabled", false))
	sim.skills_disabled = bool(snapshot.get("skills_disabled", false))
	sim.startup_ready_tick = int(snapshot.get("startup_ready_tick", 120))
	sim.ending_1v1_time = float(snapshot.get("ending_1v1_time", 0.0))
	sim.ending_1v1 = bool(snapshot.get("ending_1v1", false))
	sim._next_projectile = int(snapshot.get("next_projectile", 0))
	sim.definitions = definitions
	sim.units.clear()
	for packed_unit: Dictionary in snapshot.get("units", []):
		var restored: Dictionary = _unpack(packed_unit, definitions, str(packed_unit.get("id", "")))
		var unit_id := str(restored.get("id", ""))
		if definitions.has(unit_id):
			restored["definition"] = definitions[unit_id]
		sim.units.append(restored)
	sim.projectiles = _unpack(snapshot.get("projectiles", []), definitions)
	sim.clouds = _unpack(snapshot.get("clouds", []), definitions)
	sim.cloud_damage_ready = _unpack(snapshot.get("cloud_damage_ready", {}), definitions)
	sim._pending_status = _unpack(snapshot.get("pending_status", []), definitions)
	sim.events.clear()
	sim.trace.clear()
	sim.validation_errors.clear()

static func _pack(value: Variant, owner_id: String = "") -> Variant:
	if value is Vector2:
		return {VECTOR_TAG: [value.x, value.y]}
	if value is Resource:
		if value is ZooSkillDefinition:
			return {SKILL_TAG: str(value.id), "owner": owner_id}
		if value is ZooStatusDefinition:
			return {STATUS_TAG: str(value.id)}
		return null
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			result[key] = _pack(value[key], owner_id)
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_pack(item, owner_id))
		return result
	if value == null or value is bool or value is int or value is float or value is String:
		return value
	# No engine object or unsupported variant is permitted on the wire.
	return null

static func _unpack(value: Variant, definitions: Dictionary, owner_id: String = "") -> Variant:
	if value is Dictionary:
		if value.has(VECTOR_TAG):
			var coordinates: Array = value[VECTOR_TAG]
			return Vector2(float(coordinates[0]), float(coordinates[1])) if coordinates.size() >= 2 else Vector2.ZERO
		if value.has(SKILL_TAG):
			return _find_skill(definitions, str(value.get("owner", owner_id)), str(value[SKILL_TAG]))
		if value.has(STATUS_TAG):
			return _find_status(definitions, str(value[STATUS_TAG]))
		var result: Dictionary = {}
		for key in value:
			result[key] = _unpack(value[key], definitions, owner_id)
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_unpack(item, definitions, owner_id))
		return result
	return value

static func _find_skill(definitions: Dictionary, owner_id: String, skill_id: String) -> Resource:
	var definition: Resource = definitions.get(owner_id)
	if definition == null:
		return null
	for skill: Resource in definition.skills:
		var found := _find_skill_in_chain(skill, skill_id, [])
		if found != null:
			return found
	return null

static func _find_skill_in_chain(skill: Resource, skill_id: String, visited: Array[String]) -> Resource:
	if skill == null or skill.id in visited:
		return null
	if str(skill.id) == skill_id:
		return skill
	var next_visited := visited.duplicate()
	next_visited.append(str(skill.id))
	return _find_skill_in_chain(skill.followup_skill, skill_id, next_visited)

static func _find_status(definitions: Dictionary, status_id: String) -> Resource:
	for definition: Resource in definitions.values():
		for skill: Resource in definition.skills:
			var status := _find_status_in_chain(skill, status_id, [])
			if status != null:
				return status
	return null

static func _find_status_in_chain(skill: Resource, status_id: String, visited: Array[String]) -> Resource:
	if skill == null or skill.id in visited:
		return null
	if skill.status != null and str(skill.status.id) == status_id:
		return skill.status
	var next_visited := visited.duplicate()
	next_visited.append(str(skill.id))
	return _find_status_in_chain(skill.followup_skill, status_id, next_visited)
