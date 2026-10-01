extends SceneTree
const Catalog = preload("res://scripts/data/catalog.gd")
func _initialize() -> void:
	var out := {"snapshot_date":"2026-09-25","units":{},"hybrids":{}}
	var units := Catalog.load_units()
	for id in units:
		out.units[id] = _unit(units[id])
	for id in Catalog.hybrid_ids():
		out.hybrids[id] = _unit(units[id])
	var f := FileAccess.open("res://reports/full_roster_baseline_2026-09-25.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t")); f.close()
	quit()
func _unit(unit: ZooUnitDefinition) -> Dictionary:
	var item := {"unit":{},"skills":[]}
	for p in unit.get_property_list():
		var name: String = p.name
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and unit.get(name) is float or unit.get(name) is int:
			item.unit[name] = unit.get(name)
	for skill in unit.skills:
		var s := {}
		for p in skill.get_property_list():
			var name: String = p.name
			if (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and (skill.get(name) is float or skill.get(name) is int):
				s[name] = skill.get(name)
		item.skills.append(s)
	return item
