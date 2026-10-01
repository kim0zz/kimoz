class_name ZooMatchDefinition
extends Resource

@export var display_name: String = ""
@export var team_a: Array[String] = []
@export var team_b: Array[String] = []

func as_dictionary() -> Dictionary:
	return {"name": display_name, "a": team_a.duplicate(), "b": team_b.duplicate()}

func validate(known_ids: Array[String]) -> Array[String]:
	var errors: Array[String] = []
	for team in [team_a, team_b]:
		if team.is_empty() or team.size() > 6:
			errors.append("Team must contain 1–6 units: %s" % display_name)
		for unit_id in team:
			if unit_id not in known_ids:
				errors.append("Unknown unit %s in %s" % [unit_id, display_name])
	return errors
