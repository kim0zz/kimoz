extends SceneTree
## Bounded lvl3 matchup sample. Stalls are recorded at 120 simulated seconds.
const Catalog = preload("res://scripts/data/catalog.gd")
const Sim = preload("res://scripts/combat/combat_simulation.gd")

const SIMULATION_LIMIT := 120.0
const EXPECTED_CASES := 56
var matches: Array[Dictionary] = []
var started_msec: int = 0
var mirror_checks := 0
var mirror_passed := 0
var mirror_mismatches: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	started_msec = Time.get_ticks_msec()
	var definitions: Dictionary = Catalog.load_units()
	for lvl3_id in Catalog.lvl3_ids():
		var definition: Resource = definitions[lvl3_id]
		_run_mirror("%s-vs-parents" % lvl3_id, [lvl3_id], definition.parents)
		_run_mirror("%s-vs-strong-pair" % lvl3_id, [lvl3_id], ["eagle_hippo", "monkey_hippo"])
	_run_mixed_teams()
	var out := {
		"date": "2026-09-25",
		"rules_version": Sim.RULES_VERSION,
		"sample_design": "12 lvl3 vs both lvl2 parents together and vs eagle_hippo+monkey_hippo, both orientations (48); 4 matched-base-budget mixed teams and mirrors (8)",
		"simulation_limit_seconds": SIMULATION_LIMIT,
		"expected_cases": EXPECTED_CASES,
		"actual_cases": matches.size(),
		"wall_runtime_seconds": float(Time.get_ticks_msec() - started_msec) / 1000.0,
		"stalled_cases": matches.filter(func(row: Dictionary) -> bool: return bool(row.stalled)).size(),
		"mirror_check": {"pairs": mirror_checks, "passed": mirror_passed, "mismatches": mirror_mismatches},
		"source_hashes": _source_hashes(),
		"matches": matches,
		"lvl3_summary": _summaries(),
	}
	out["source_hash_count"] = out.source_hashes.size()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/lvl3"))
	var file := FileAccess.open("res://reports/lvl3/lvl3_simulations_2026-09-25.json", FileAccess.WRITE)
	if file == null:
		push_error("Unable to write lvl3 simulation report")
		quit(1)
		return
	file.store_string(JSON.stringify(out, "\t"))
	file.close()
	print("LVL3 SIMULATIONS: %d/%d cases; stalls=%d; runtime=%.2fs" % [matches.size(), EXPECTED_CASES, out.stalled_cases, out.wall_runtime_seconds])
	quit(0 if matches.size() == EXPECTED_CASES and out.stalled_cases == 0 else 1)

func _run_mirror(label: String, team_a: Array, team_b: Array) -> void:
	var first := _fight(label, team_a, team_b)
	var mirror := _fight(label + "-mirror", team_b, team_a)
	first["mirror_of"] = label + "-mirror"
	matches.append(first)
	matches.append(mirror)
	var expected: String = "B" if first.result == "A" else ("A" if first.result == "B" else first.result)
	var mirror_ok: bool = mirror.result == expected and absf(float(mirror.duration) - float(first.duration)) <= Sim.DT
	mirror_checks += 1
	if mirror_ok:
		mirror_passed += 1
	else:
		mirror_mismatches.append(label)
	if not mirror_ok:
		push_warning("Mirror mismatch %s: %s/%.3f vs %s/%.3f" % [label, first.result, first.duration, mirror.result, mirror.duration])

func _run_mixed_teams() -> void:
	var samples: Array[Dictionary] = [
		{"a": ["lvl3_01", "bear", "rabbit"], "b": ["eagle_hippo", "monkey_hippo", "bear", "rabbit"]},
		{"a": ["lvl3_04", "cheetah", "hedgehog"], "b": ["bear_cheetah", "hippo_rabbit", "cheetah", "hedgehog"]},
		{"a": ["lvl3_08", "skunk", "hippo"], "b": ["eagle_hippo", "hedgehog_skunk", "skunk", "hippo"]},
		{"a": ["lvl3_11", "monkey", "bear"], "b": ["eagle_hippo", "monkey_hippo", "monkey", "bear"]},
	]
	for i in samples.size():
		var sample: Dictionary = samples[i]
		_run_mirror("mixed_%02d" % (i + 1), sample.a, sample.b)

func _fight(label: String, team_a: Array, team_b: Array) -> Dictionary:
	var sim := Sim.new()
	sim.setup(team_a, team_b, 107 + matches.size())
	var wall_start := Time.get_ticks_msec()
	var max_tick := int(SIMULATION_LIMIT * 60.0)
	while sim.result == "running" and sim.tick < max_tick:
		sim.step()
		if Time.get_ticks_msec() - started_msec >= 120000:
			break
	var stalled := sim.result == "running"
	var summary: Dictionary = sim.summary()
	var reason := "none"
	if stalled:
		reason = "simulation_limit" if sim.tick >= max_tick else "technical_wall_timeout"
	return {
		"scenario": label,
		"a": team_a,
		"b": team_b,
		"result": "stalled" if stalled else sim.result,
		"duration": sim.time,
		"tick": sim.tick,
		"stalled": stalled,
		"stall_reason": reason,
		"wall_runtime_seconds": float(Time.get_ticks_msec() - wall_start) / 1000.0,
		"units": summary.units,
	}

func _summaries() -> Dictionary:
	var output := {}
	for id in Catalog.lvl3_ids():
		var rows: Array = matches.filter(func(row: Dictionary) -> bool: return id in row.a or id in row.b)
		var records := []
		for row: Dictionary in rows:
			for unit: Dictionary in row.units:
				if unit.id == id:
					var winning_team: int = 0 if row.result == "A" else (1 if row.result == "B" else -1)
					var unit_outcome: String = "draw" if winning_team < 0 else ("win" if int(unit.team) == winning_team else "loss")
					records.append({"scenario": row.scenario, "result": row.result,
					"team": unit.team, "unit_outcome": unit_outcome,
					"damage_dealt": unit.damage_dealt, "damage_by_kind": unit.damage_by_kind,
					"damage_by_skill": unit.damage_by_skill, "skill_uses": unit.skill_uses,
					"survived": unit.survived, "death_time": unit.death_time,
					"stun_uptime": unit.stun_uptime, "stagger_uptime": unit.stagger_uptime,
					"slow_uptime": unit.slow_uptime})
		output[id] = records
	return output

func _source_hashes() -> Dictionary:
	var hashes := {}
	_hash_directory("res://scripts", hashes)
	_hash_directory("res://resources", hashes)
	return hashes

func _hash_directory(path: String, output: Dictionary) -> void:
	var directory := DirAccess.open(path)
	if directory == null: return
	for filename in directory.get_files():
		if not filename.ends_with(".gd") and not filename.ends_with(".tres"): continue
		var file_path := path.path_join(filename)
		var context := HashingContext.new()
		if context.start(HashingContext.HASH_SHA256) != OK: continue
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null: continue
		context.update(file.get_buffer(file.get_length()))
		output[file_path.trim_prefix("res://")] = context.finish().hex_encode()
	for dirname in directory.get_directories():
		_hash_directory(path.path_join(dirname), output)
