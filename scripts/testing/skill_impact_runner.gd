extends SceneTree
## Deterministic, paired damage-share audit for the current unit resources.
## Produces 80 baseline fights and their 80 matched active-skill ablations.

const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const ARENA := Vector2(1120.0, 500.0)
const WATCHDOG := 120.0
const L1 := ["bear", "cheetah", "monkey", "eagle", "hedgehog", "hippo", "skunk", "rabbit"]
const HYBRIDS := ["bear_cheetah", "bear_monkey", "bear_hedgehog", "cheetah_eagle", "cheetah_rabbit", "monkey_skunk", "monkey_hippo", "eagle_hedgehog", "eagle_hippo", "hippo_rabbit", "hedgehog_skunk", "skunk_rabbit"]
const KINDS := ["basic", "skill", "dot", "thorns"]
var output_dir := "res://reports/skill_impact"
var label := "skill_impact"
var records: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_parse_args(OS.get_cmdline_user_args())
	var absolute := ProjectSettings.globalize_path(output_dir)
	if DirAccess.make_dir_recursive_absolute(absolute) != OK:
		push_error("Cannot create output directory: " + absolute)
		quit(2)
		return
	var definitions := Catalog.load_units()
	if definitions.size() != 20:
		push_error("Expected 20 current unit definitions; found %d" % definitions.size())
		quit(2)
		return
	var hash_start := _source_hash()
	var started := Time.get_ticks_msec()
	var scenarios := _scenarios()
	for scenario in scenarios:
		for disabled in [false, true]:
			var options: Dictionary = {"positions": scenario.positions.duplicate()}
			if disabled:
				options.definitions = _active_skills_removed(definitions)
			var sim := Sim.new()
			if not sim.setup(scenario.a, scenario.b, int(scenario.seed), options):
				push_error("Setup failed %s disabled=%s: %s" % [scenario.id, str(disabled), str(sim.validation_errors)])
				quit(2)
				return
			var initial: Array = []
			var damage_events: Array[Dictionary] = []
			for unit in sim.units:
				initial.append([unit.pos.x, unit.pos.y])
			while sim.result == "running" and sim.time < WATCHDOG:
				sim.step()
				damage_events.append_array(_damage_events(sim.events))
			var row: Dictionary = sim.summary()
			row.merge({"scenario": scenario.id, "family": scenario.family,
				"mirror_group": scenario.mirror_group, "mirror_side": scenario.mirror_side,
				"a": scenario.a, "b": scenario.b, "seed": scenario.seed,
				"positions": initial, "skills_disabled": disabled,
				"active_damage_events": damage_events}, true)
			if sim.result == "running": row.result = "inconclusive"
			records.append(row)
			if records.size() % 32 == 0:
				print("SKILL IMPACT %d/160" % records.size())
	var hash_end := _source_hash()
	var validation := _validate(definitions)
	if not validation.pass:
		for error in validation.errors: push_error(error)
		quit(2)
		return
	var report := {"label": label, "created_utc": Time.get_datetime_string_from_system(true),
		"engine": Engine.get_version_info().string, "dt": 1.0 / 60.0,
		"watchdog_seconds": WATCHDOG, "scenario_count": records.size(),
		"baseline_count": 80, "matched_ablation_count": 80,
		"wall_ms": Time.get_ticks_msec() - started,
		"source_hash_start": hash_start, "source_hash_end": hash_end,
		"sources_changed_during_run": hash_start.sha256 != hash_end.sha256,
		"interpretation": "Finite deterministic coverage, not random samples or population win rates. Active ablation removes every non-thorns skill from deep-copied definitions while retaining base stats and thorns; behavioral changes make duration and result differences exploratory rather than damage attribution.",
		"damage_event_packets": _packet_summary(), "groups": _aggregate(),
		"skill_detail": _skill_detail(definitions), "ablation_pairs": _ablation_pairs(),
		"validation": validation, "matches": records}
	var file := FileAccess.open(absolute.path_join(label + ".json"), FileAccess.WRITE)
	if file == null:
		push_error("Cannot write report")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	_save_csv(absolute)
	print("SKILL IMPACT COMPLETE: %d fights; %.2fs; %s" % [records.size(), float(report.wall_ms) / 1000.0, absolute])
	for key in report.groups:
		var g: Dictionary = report.groups[key]
		print("%s n=%d basic=%.1f%% skill+dot=%.1f%% thorns=%.1f%%" % [key, g.appearances, 100.0 * g.damage_share.basic, 100.0 * g.active_damage_share, 100.0 * g.damage_share.thorns])
	quit(0)

func _parse_args(args: PackedStringArray) -> void:
	for i in range(args.size()):
		if args[i] == "--output" and i + 1 < args.size(): output_dir = args[i + 1]
		elif args[i] == "--label" and i + 1 < args.size(): label = args[i + 1]

func _scenarios() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	# Eight mirror pairs per roster size; rotating windows give every lvl1 repeated exposure.
	for i in range(8):
		var a2: Array[String] = [L1[i], L1[(i + 1) % 8]]
		var b2: Array[String] = [L1[(i + 4) % 8], L1[(i + 5) % 8]]
		_add_pair(out, "lvl1_2v2", "l1_2v2_%02d" % i, a2, b2, 1)
		var a6: Array[String] = []
		var b6: Array[String] = []
		for j in range(8):
			if j != i and j != (i + 1) % 8: a6.append(L1[j])
			if j != (i + 4) % 8 and j != (i + 5) % 8: b6.append(L1[j])
		_add_pair(out, "lvl1_6v6", "l1_6v6_%02d" % i, a6, b6, 1)
	# One roster per hybrid in 3v3; the opposite side cycles by half the hybrid list.
	for i in range(12):
		var a3: Array[String] = [HYBRIDS[i], L1[(2 * i) % 8], L1[(2 * i + 1) % 8]]
		var b3: Array[String] = [HYBRIDS[(i + 6) % 12], L1[(2 * i + 4) % 8], L1[(2 * i + 5) % 8]]
		_add_pair(out, "mixed_3v3", "mixed_3v3_%02d" % i, a3, b3, 1)
	# Sliding triplets cycle all twelve hybrids and all eight lvl1s on both sides.
	for i in range(12):
		var a6m: Array[String] = [HYBRIDS[i], HYBRIDS[(i + 1) % 12], HYBRIDS[(i + 2) % 12], L1[(i * 2) % 8], L1[(i * 2 + 1) % 8], L1[(i * 2 + 2) % 8]]
		var b6m: Array[String] = [HYBRIDS[(i + 6) % 12], HYBRIDS[(i + 7) % 12], HYBRIDS[(i + 8) % 12], L1[(i * 2 + 4) % 8], L1[(i * 2 + 5) % 8], L1[(i * 2 + 6) % 8]]
		_add_pair(out, "mixed_6v6", "mixed_6v6_%02d" % i, a6m, b6m, 1)
	return out

func _add_pair(out: Array[Dictionary], family: String, id: String, a: Array[String], b: Array[String], seed: int) -> void:
	var ap := _default_positions(a, 0)
	var bp := _default_positions(b, 1)
	var positions: Array[Vector2] = []
	positions.append_array(ap)
	positions.append_array(bp)
	out.append({"id": id + "_a", "family": family, "mirror_group": id,
		"mirror_side": 0, "a": a, "b": b, "seed": seed, "positions": positions})
	var mirrored: Array[Vector2] = []
	for point in bp: mirrored.append(Vector2(ARENA.x - point.x, point.y))
	for point in ap: mirrored.append(Vector2(ARENA.x - point.x, point.y))
	out.append({"id": id + "_b", "family": family, "mirror_group": id,
		"mirror_side": 1, "a": b, "b": a, "seed": seed, "positions": mirrored})

func _default_positions(roster: Array[String], team: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var defs := Catalog.load_units()
	for slot in range(roster.size()):
		var definition: Resource = defs[roster[slot]]
		var x := 300.0 if definition.role in ["front", "melee", "mobile"] else 180.0
		if team == 1: x = ARENA.x - x
		out.append(Vector2(x, ARENA.y * (slot + 1.0) / (roster.size() + 1.0)))
	return out

func _active_skills_removed(definitions: Dictionary) -> Dictionary:
	var modified: Dictionary = {}
	for unit_id in definitions:
		var copy: Resource = definitions[unit_id].duplicate(true)
		var retained: Array[ZooSkillDefinition] = []
		for skill in copy.skills:
			if skill.behavior == "thorns": retained.append(skill.duplicate(true))
		copy.skills.clear()
		for skill in retained: copy.skills.append(skill)
		modified[unit_id] = copy
	return modified

func _damage_events(events: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event in events:
		if event.get("kind", "") != "damage": continue
		out.append({"source": int(event.source), "target": int(event.target),
			"kind": str(event.damage_kind), "skill": str(event.get("skill", "")),
			"amount": float(event.applied)})
	return out

func _aggregate() -> Dictionary:
	var groups: Dictionary = {}
	for record in records:
		if record.skills_disabled: continue
		var seen_levels: Dictionary = {}
		for unit in record.units:
			var key := "%s_lvl%d" % [record.family, int(unit.level)]
			if not groups.has(key): groups[key] = _new_stats()
			var g: Dictionary = groups[key]
			g.appearances += 1
			_add_unit_stats(g, unit)
			seen_levels[key] = true
		for key in seen_levels: groups[key].fights += 1
	for key in groups:
		var g: Dictionary = groups[key]
		var total := 0.0
		for kind in KINDS: total += float(g.damage_by_kind.get(kind, 0.0))
		g.raw_damage_total = total
		g.damage_share = {}
		for kind in KINDS: g.damage_share[kind] = _ratio(float(g.damage_by_kind.get(kind, 0.0)), total)
		g.active_damage_total = float(g.damage_by_kind.get("skill", 0.0)) + float(g.damage_by_kind.get("dot", 0.0))
		g.active_damage_share = _ratio(g.active_damage_total, total)
		g.thorns_share = _ratio(float(g.damage_by_kind.get("thorns", 0.0)), total)
		g.basic_share = _ratio(float(g.damage_by_kind.get("basic", 0.0)), total)
		g.damage_by_kind = g.damage_by_kind
		g.casts_per_active_owner_appearance = _ratio(g.skill_uses, g.active_owner_appearances)
		g.noncast_active_owner_rate = _ratio(g.noncast_active_owner_appearances, g.active_owner_appearances)
		g.cast_appearance_rate = _ratio(g.cast_active_owner_appearances, g.active_owner_appearances)
		g.stun_seconds_per_fight = _ratio(g.stun_victim_seconds, g.fights)
		g.stagger_seconds_per_fight = _ratio(g.stagger_victim_seconds, g.fights)
		g.slow_seconds_per_fight = _ratio(g.slow_victim_seconds, g.fights)
		g.erase("skill_uses")
		g.erase("cast_active_owner_appearances")
		g.erase("noncast_active_owner_appearances")
	return groups

func _new_stats() -> Dictionary:
	return {"fights": 0, "appearances": 0, "damage_by_kind": {}, "skill_uses": 0,
		"active_owner_appearances": 0, "cast_active_owner_appearances": 0,
		"noncast_active_owner_appearances": 0, "stun_victim_seconds": 0.0,
		"stagger_victim_seconds": 0.0, "slow_victim_seconds": 0.0}

func _add_unit_stats(g: Dictionary, unit: Dictionary) -> void:
	for kind in KINDS:
		g.damage_by_kind[kind] = float(g.damage_by_kind.get(kind, 0.0)) + float(unit.damage_by_kind.get(kind, 0.0))
	var definition: Resource = Catalog.load_units()[unit.id]
	var owns_active := false
	for skill in definition.skills:
		if skill.behavior != "thorns": owns_active = true
	var uses: Dictionary = unit.skill_uses
	var cast_count := 0
	for skill in definition.skills:
		if skill.behavior == "thorns": continue
		cast_count += int(uses.get(skill.id, 0))
	g.skill_uses += cast_count
	if owns_active:
		g.active_owner_appearances += 1
		if cast_count > 0: g.cast_active_owner_appearances += 1
		else: g.noncast_active_owner_appearances += 1
	g.stun_victim_seconds += float(unit.get("stun_uptime", 0.0))
	g.stagger_victim_seconds += float(unit.get("stagger_uptime", 0.0))
	g.slow_victim_seconds += float(unit.get("slow_uptime", 0.0))

func _packet_summary() -> Dictionary:
	var values := {"basic": [], "skill": [], "dot": [], "thorns": []}
	for record in records:
		if record.skills_disabled: continue
		for event in record.active_damage_events:
			if values.has(event.kind) and float(event.amount) > 0.0: values[event.kind].append(float(event.amount))
	var result := {}
	for kind in values: result[kind] = _distribution(values[kind])
	result.skill_vs_basic_median_ratio = _ratio(float(result.skill.median), float(result.basic.median))
	return result

func _skill_detail(definitions: Dictionary) -> Dictionary:
	var detail: Dictionary = {}
	for unit_id in definitions:
		var definition: Resource = definitions[unit_id]
		for skill in definition.skills:
			if skill.behavior == "thorns": continue
			var key: String = str(unit_id) + "/" + str(skill.id)
			var appearances := 0
			var uses := 0
			var events := 0
			var raw_damage := 0.0
			for record in records:
				if record.skills_disabled: continue
				for unit in record.units:
					if unit.id == unit_id:
						appearances += 1
						uses += int(unit.skill_uses.get(skill.id, 0))
					for event in record.active_damage_events:
						if int(event.source) == int(unit.uid) and (event.skill == skill.id or str(event.skill).begins_with(str(skill.id) + "_")):
							events += 1
							raw_damage += float(event.amount)
			detail[key] = {"unit_level": int(definition.level), "behavior": skill.behavior,
				"nominal_damage_per_hit": float(skill.damage), "nominal_hits": int(skill.hits),
				"cooldown_seconds": float(skill.cooldown), "appearances": appearances,
				"casts": uses, "casts_per_appearance": _ratio(uses, appearances),
				"active_skill_damage_events": events, "applied_skill_damage": raw_damage}
	return detail

func _ablation_pairs() -> Dictionary:
	var grouped: Dictionary = {}
	for record in records:
		var key: String = str(record.scenario).trim_suffix("_a").trim_suffix("_b")
		if not grouped.has(key): grouped[key] = {"baseline": {}, "ablated": {}}
		var variant := "ablated" if record.skills_disabled else "baseline"
		grouped[key][variant][str(record.mirror_side)] = record
	var all := {"pairs": 0, "result_flips": 0, "duration_delta_sum_on_minus_off": 0.0,
		"duration_delta_mean_on_minus_off": 0.0, "team_damage_delta_sum_on_minus_off": 0.0,
		"notes": "Paired behavioral signal; active-skill removal changes movement, action time, control and survival, so delta is not damage attribution."}
	for pair_id in grouped:
		var pair: Dictionary = grouped[pair_id]
		for side in ["0", "1"]:
			if not pair.baseline.has(side) or not pair.ablated.has(side): continue
			var on: Dictionary = pair.baseline[side]
			var off: Dictionary = pair.ablated[side]
			all.pairs += 1
			all.duration_delta_sum_on_minus_off += float(on.duration) - float(off.duration)
			all.team_damage_delta_sum_on_minus_off += _team_damage(on, 0) - _team_damage(off, 0)
			if on.result != off.result: all.result_flips += 1
	all.duration_delta_mean_on_minus_off = _ratio(all.duration_delta_sum_on_minus_off, all.pairs)
	return all

func _team_damage(record: Dictionary, team: int) -> float:
	var total := 0.0
	for unit in record.units:
		if int(unit.team) == team: total += float(unit.damage_dealt)
	return total

func _validate(definitions: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var allowed := ["basic", "skill", "dot", "thorns"]
	var mirror_groups: Dictionary = {}
	for record in records:
		if record.result == "inconclusive": errors.append("Watchdog stall: " + record.scenario)
		var dealt := 0.0
		var taken := 0.0
		var kinds := {}
		for unit in record.units:
			dealt += float(unit.damage_dealt)
			taken += float(unit.damage_taken)
			var unit_total := 0.0
			for kind in unit.damage_by_kind:
				if kind not in allowed: errors.append("Unknown damage kind %s at %s" % [kind, record.scenario])
				unit_total += float(unit.damage_by_kind[kind])
			kinds[unit.id] = kinds.get(unit.id, 0.0) + unit_total
			if absf(unit_total - float(unit.damage_dealt)) > 0.02: errors.append("Damage-kind sum mismatch: %s/%s" % [record.scenario, unit.id])
		if absf(dealt - taken) > 0.02: errors.append("Dealt/taken mismatch: " + record.scenario)
		var event_total := 0.0
		for event in record.active_damage_events: event_total += float(event.amount)
		if absf(event_total - dealt) > 0.02: errors.append("Damage-event/dealt mismatch: " + record.scenario)
		if not mirror_groups.has(record.mirror_group): mirror_groups[record.mirror_group] = {}
		mirror_groups[record.mirror_group]["%s_%s" % ["off" if record.skills_disabled else "on", str(record.mirror_side)]] = record
	for key in mirror_groups:
		var pair: Dictionary = mirror_groups[key]
		for mode in ["on", "off"]:
			if not pair.has(mode + "_0") or not pair.has(mode + "_1"):
				errors.append("Missing mirror partner: %s/%s" % [key, mode])
				continue
			var a: Dictionary = pair[mode + "_0"]
			var b: Dictionary = pair[mode + "_1"]
			if not _opposite(a.result, b.result): errors.append("Mirror result mismatch: " + key + "/" + mode)
			if absf(float(a.duration) - float(b.duration)) > 1.0 / 60.0 + 0.0001: errors.append("Mirror duration mismatch: " + key + "/" + mode)
	return {"pass": errors.is_empty(), "scenario_count": records.size(),
		"mirror_groups": mirror_groups.size(), "damage_totals_equal_within_0_02": errors.is_empty(),
		"unknown_categories": 0, "stalls": 0, "errors": errors}

func _opposite(a: String, b: String) -> bool:
	if a == "A": return b == "B"
	if a == "B": return b == "A"
	return a == b

func _distribution(values: Array) -> Dictionary:
	if values.is_empty(): return {"n": 0, "median": 0.0, "mean": 0.0}
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	for value in sorted: total += float(value)
	var mid: int = sorted.size() / 2
	var median: float = sorted[mid] if sorted.size() % 2 else (float(sorted[mid - 1]) + float(sorted[mid])) / 2.0
	return {"n": sorted.size(), "median": median, "mean": total / sorted.size()}

func _ratio(numerator: float, denominator: float) -> float:
	return numerator / denominator if denominator > 0.0 else 0.0

func _source_hash() -> Dictionary:
	var paths: Array[String] = []
	_collect("res://scripts", paths)
	_collect("res://resources", paths)
	paths.sort()
	var files := {}
	var combined := ""
	for path in paths:
		var context := HashingContext.new()
		context.start(HashingContext.HASH_SHA256)
		context.update(FileAccess.get_file_as_bytes(path))
		var digest := context.finish().hex_encode()
		files[path] = digest
		combined += path + ":" + digest + "\n"
	return {"sha256": combined.sha256_text(), "files": files}

func _collect(directory: String, paths: Array[String]) -> void:
	var dir := DirAccess.open(directory)
	if dir == null: return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var path := directory.path_join(name)
		if dir.current_is_dir(): _collect(path, paths)
		elif name.ends_with(".gd") or name.ends_with(".tres"): paths.append(path)
		name = dir.get_next()
	dir.list_dir_end()

func _save_csv(absolute: String) -> void:
	var match_file := FileAccess.open(absolute.path_join(label + "_matches.csv"), FileAccess.WRITE)
	match_file.store_csv_line(PackedStringArray(["scenario", "family", "skills_disabled", "mirror_group", "mirror_side", "team_a", "team_b", "result", "duration", "team_a_damage", "team_b_damage", "positions"]))
	var unit_file := FileAccess.open(absolute.path_join(label + "_units.csv"), FileAccess.WRITE)
	unit_file.store_csv_line(PackedStringArray(["scenario", "family", "skills_disabled", "uid", "unit_id", "level", "team", "survived", "damage_dealt", "damage_taken", "basic", "skill", "dot", "thorns", "skill_uses", "stun_victim_seconds", "stagger_victim_seconds", "slow_victim_seconds"]))
	for record in records:
		match_file.store_csv_line(PackedStringArray([record.scenario, record.family, str(record.skills_disabled), record.mirror_group, str(record.mirror_side), "+".join(record.a), "+".join(record.b), record.result, str(record.duration), str(_team_damage(record, 0)), str(_team_damage(record, 1)), JSON.stringify(record.positions)]))
		for unit in record.units:
			unit_file.store_csv_line(PackedStringArray([record.scenario, record.family, str(record.skills_disabled), str(unit.uid), unit.id, str(unit.level), str(unit.team), str(unit.survived), str(unit.damage_dealt), str(unit.damage_taken), str(unit.damage_by_kind.get("basic", 0.0)), str(unit.damage_by_kind.get("skill", 0.0)), str(unit.damage_by_kind.get("dot", 0.0)), str(unit.damage_by_kind.get("thorns", 0.0)), JSON.stringify(unit.skill_uses), str(unit.stun_uptime), str(unit.stagger_uptime), str(unit.slow_uptime)]))
	match_file.close()
	unit_file.close()
