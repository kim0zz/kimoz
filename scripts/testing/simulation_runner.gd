extends SceneTree
## Deterministic scenario coverage; never claims seeds are independent samples.
const SIM_PATH := "res://scripts/combat/combat_simulation.gd"
const IDS := ["bear", "cheetah", "monkey", "eagle", "hedgehog", "hippo", "skunk", "rabbit"]
const WATCHDOG := 120.0
var matches: Array = []
var output_dir := "user://combat_reports"
var label := "baseline"
var suite := "quick"
var trace_one := false
var scenario_filter := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--output" and i + 1 < args.size(): output_dir = args[i + 1]
		if args[i] == "--label" and i + 1 < args.size(): label = args[i + 1]
		if args[i] == "--suite" and i + 1 < args.size(): suite = args[i + 1]
		if args[i] == "--trace-one": trace_one = true
		if args[i] == "--scenario" and i + 1 < args.size(): scenario_filter = args[i + 1]
	if suite not in ["quick", "full"]:
		push_error("Expected --suite quick|full")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		push_error("Cannot create output directory: " + output_dir)
		quit(2)
		return
	var start_ms := Time.get_ticks_msec()
	var start_hash := _source_hash()
	var scenarios := _scenarios()
	if not scenario_filter.is_empty():
		scenarios = scenarios.filter(func(scenario: Dictionary) -> bool: return scenario.id == scenario_filter)
		if scenarios.is_empty():
			push_error("Unknown scenario: " + scenario_filter)
			quit(2)
			return
	var sim_script: Script = load(SIM_PATH)
	if sim_script == null:
		quit(2)
		return
	for scenario in scenarios:
		var sim = sim_script.new()
		var options: Dictionary = scenario.options.duplicate(true)
		options.trace = trace_one and matches.is_empty()
		if not sim.setup(scenario.a, scenario.b, scenario.seed, options):
			push_error("Scenario setup failed: " + scenario.id)
			quit(2)
			return
		var initial_positions: Array = []
		for unit in sim.units:
			initial_positions.append([unit.pos.x, unit.pos.y])
		var started := Time.get_ticks_usec()
		while sim.result == "running" and sim.time < WATCHDOG:
			sim.step()
		var record: Dictionary = sim.summary()
		record.scenario = scenario.id
		record.family = scenario.family
		record.a = scenario.a
		record.b = scenario.b
		record.seed = scenario.seed
		record.positions = initial_positions
		record.disable_skills = options.get("disable_skills", false)
		record.wall_ms = float(Time.get_ticks_usec() - started) / 1000.0
		if sim.result == "running": record.result = "inconclusive"
		matches.append(record)
		if options.trace or record.result == "inconclusive":
			if not options.trace:
				options.trace = true
				sim.setup(scenario.a, scenario.b, scenario.seed, options)
				while sim.result == "running" and sim.time < WATCHDOG: sim.step()
			_save_trace(scenario.id, sim.trace)
		if matches.size() % 64 == 0:
			print("SIMULATION %d/%d" % [matches.size(), scenarios.size()])
	var aggregates := _aggregate()
	if not _validate_aggregates(aggregates):
		quit(2)
		return
	var report := {"label": label, "suite": suite, "engine": Engine.get_version_info().string,
		"created_utc": Time.get_datetime_string_from_system(true), "dt": 1.0 / 60.0,
		"watchdog_seconds": WATCHDOG, "wall_ms": Time.get_ticks_msec() - start_ms,
		"source_hash": start_hash, "scenario_count": matches.size(), "scenario_filter": scenario_filter,
		"interpretation": "Deterministic scenario coverage, not independent random trials or player population win rates. Survivors excluded from TTK. Inconclusive excluded from win rate denominator.",
		"groups": aggregates, "matches": matches}
	var report_file := FileAccess.open(output_dir.path_join(label + ".json"), FileAccess.WRITE)
	if report_file == null:
		push_error("Unable to write report")
		quit(2)
		return
	report_file.store_string(JSON.stringify(report, "\t"))
	report_file.close()
	_save_csv()
	print("SIMULATION COMPLETE %d cases in %.2f s: %s" % [matches.size(), float(report.wall_ms) / 1000.0, output_dir])
	for group in report.groups:
		var metrics: Dictionary = report.groups[group]
		print("%s: n=%d A=%d B=%d draw=%d stalled=%d duration median=%.3f p90=%.3f" % [group, metrics.matches, metrics.A, metrics.B, metrics.draw, metrics.inconclusive, metrics.duration.median, metrics.duration.p90])
	quit(0)

func _scenarios() -> Array:
	var out: Array = []
	var variants: Array = [[280.0, 250.0, 250.0], [170.0, 220.0, 280.0], [420.0, 190.0, 310.0], [300.0, 310.0, 190.0], [460.0, 250.0, 250.0]]
	for variant in range(5):
		for a in IDS:
			for b in IDS:
				var v: Array = variants[variant]
				out.append(_case("duel_%d_%s_%s" % [variant, a, b], "1v1", [a], [b], {"positions": [Vector2(v[0], v[1]), Vector2(1120.0 - v[0], v[2])]}))
	var interactions: Array = [
		[["bear", "monkey"], ["hippo", "cheetah"]],
		[["bear", "monkey"], ["hippo", "eagle"]],
		[["hedgehog", "skunk"], ["cheetah", "bear"]],
		[["cheetah", "bear", "monkey"], ["hippo", "hedgehog", "monkey"]],
		[["rabbit", "eagle", "skunk"], ["bear", "hippo", "monkey"]],
		[["monkey", "monkey", "monkey"], ["bear", "hippo", "eagle"]]]
	for i in range(interactions.size()):
		out.append(_case("interaction_%d" % i, "interactions", interactions[i][0], interactions[i][1]))
		out.append(_case("interaction_%d_mirror" % i, "interactions", interactions[i][1], interactions[i][0]))
	if suite == "full":
		var rosters: Array = []
		for excluded_a in range(8):
			for excluded_b in range(excluded_a + 1, 8):
				var roster: Array = []
				for index in range(8):
					if index != excluded_a and index != excluded_b: roster.append(IDS[index])
				rosters.append(roster)
		for i in range(rosters.size()):
			for j in range(rosters.size()): out.append(_case("six_%02d_%02d" % [i, j], "6v6", rosters[i], rosters[j]))
		for a in IDS:
			for b in IDS:
				out.append(_case("ablation_%s_%s" % [a, b], "1v1_no_skills", [a], [b], {"disable_skills": true, "positions": [Vector2(280,250),Vector2(840,250)]}))
	return out

func _case(id: String, family: String, a: Array, b: Array, options: Dictionary = {}) -> Dictionary:
	return {"id": id, "family": family, "a": a, "b": b, "seed": 1, "options": options}

func _aggregate() -> Dictionary:
	var groups: Dictionary = {}
	for match_record in matches:
		var family: String = match_record.family
		if not groups.has(family): groups[family] = {"matches": 0, "A": 0, "B": 0, "draw": 0, "inconclusive": 0, "times": [], "first_hits": [], "in_target_window": 0, "ending_1v1_count": 0, "ending_1v1_times": [], "units": {}}
		var group: Dictionary = groups[family]
		group.matches += 1
		group[match_record.result] += 1
		if match_record.get("ending_1v1", false):
			group.ending_1v1_count += 1
			group.ending_1v1_times.append(match_record.get("ending_1v1_time", 0.0))
		if match_record.result != "inconclusive":
			group.times.append(match_record.duration)
			if match_record.duration >= 20.0 and match_record.duration <= 30.0: group.in_target_window += 1
		if match_record.get("first_hit_time", -1.0) >= 0: group.first_hits.append(match_record.first_hit_time)
		for unit in match_record.units:
			var id: String = unit.id
			if not group.units.has(id):
				group.units[id] = {"appearances": 0, "completed": 0, "wins": 0, "draws": 0, "survived": 0, "damage_dealt": 0.0, "damage_taken": 0.0, "life_seconds": 0.0, "status_seconds": 0.0, "ttks": [], "skill_uses": {}, "target_changes": 0, "opportunities": 0, "eligible_without_activation": 0, "died_before_opportunity": 0, "damage_by_kind": {}, "target_change_reasons": {}, "overkill": 0.0, "cancelled_damage": 0.0, "focus_damage_received": 0.0, "ranged_in_band_seconds": 0.0, "ranged_observed_seconds": 0.0}
			var stats: Dictionary = group.units[id]
			stats.appearances += 1
			if match_record.result != "inconclusive":
				stats.completed += 1
				if ("A" if int(unit.team) == 0 else "B") == match_record.result: stats.wins += 1
				if match_record.result == "draw": stats.draws += 1
			if unit.survived: stats.survived += 1
			stats.damage_dealt += unit.damage_dealt
			stats.damage_taken += unit.get("damage_taken", unit.get("taken", 0.0))
			stats.life_seconds += unit.death_time if unit.death_time >= 0 else match_record.duration
			stats.status_seconds += unit.get("status_uptime", 0.0)
			stats.target_changes += unit.get("target_changes", 0)
			stats.overkill += unit.get("overkill", 0.0)
			stats.cancelled_damage += unit.get("cancelled_damage", 0.0)
			stats.focus_damage_received += unit.get("focus_damage", 0.0)
			stats.ranged_in_band_seconds += unit.get("ranged_in_band", 0.0)
			stats.ranged_observed_seconds += unit.get("ranged_observed", 0.0)
			for kind in unit.get("damage_by_kind", {}):
				stats.damage_by_kind[kind] = stats.damage_by_kind.get(kind, 0.0) + unit.damage_by_kind[kind]
			for reason in unit.get("target_change_reasons", {}):
				stats.target_change_reasons[reason] = stats.target_change_reasons.get(reason, 0) + unit.target_change_reasons[reason]
			if unit.ttk >= 0: stats.ttks.append(unit.ttk)
			var uses: Dictionary = unit.get("skill_uses", {})
			var activation_count := 0
			for skill_id in uses:
				stats.skill_uses[skill_id] = stats.skill_uses.get(skill_id, 0) + uses[skill_id]
				activation_count += int(uses[skill_id])
			var opportunities = unit.get("skill_opportunities", 0)
			var opportunity_count := 0
			if opportunities is Dictionary:
				for value in opportunities.values(): opportunity_count += int(value)
			else: opportunity_count = int(opportunities)
			stats.opportunities += opportunity_count
			if opportunity_count > 0 and activation_count == 0: stats.eligible_without_activation += 1
			if opportunity_count == 0 and not unit.survived: stats.died_before_opportunity += 1
	for family in groups:
		var group: Dictionary = groups[family]
		group.duration = _distribution(group.times)
		group.first_hit_time = _distribution(group.first_hits)
		group.ending_1v1_duration = _distribution(group.ending_1v1_times)
		group.ending_1v1_fraction = _ratio(group.ending_1v1_count, group.matches)
		group.completed = group.matches - group.inconclusive
		group.a_win_rate = _ratio(group.A, group.completed)
		group.b_win_rate = _ratio(group.B, group.completed)
		group.fraction_duration_20_30 = _ratio(group.in_target_window, group.completed)
		group.erase("times")
		group.erase("first_hits")
		group.erase("ending_1v1_times")
		for id in group.units:
			var stats: Dictionary = group.units[id]
			stats.win_rate = _ratio(stats.wins, stats.completed)
			stats.score_rate = _ratio(stats.wins + stats.draws * 0.5, stats.completed)
			stats.survival_rate = _ratio(stats.survived, stats.appearances)
			stats.observed_dps = _ratio(stats.damage_dealt, stats.life_seconds)
			stats.status_fraction = _ratio(stats.status_seconds, stats.life_seconds)
			stats.focus_damage_received_fraction = _ratio(stats.focus_damage_received, stats.damage_taken)
			stats.ranged_in_band_fraction = _ratio(stats.ranged_in_band_seconds, stats.ranged_observed_seconds)
			stats.target_changes_per_life_second = _ratio(stats.target_changes, stats.life_seconds)
			stats.ttk = _distribution(stats.ttks)
			stats.erase("ttks")
			stats.balance_alert = stats.win_rate > 0.7 or stats.win_rate < 0.3
	return groups

func _ratio(numerator: float, denominator: float) -> float:
	return numerator / denominator if denominator > 0.0 else 0.0

func _validate_aggregates(groups: Dictionary) -> bool:
	# Cross-check against winning roster lengths rather than unit team conversion.
	for family in groups:
		var expected_wins := 0
		var expected_draws := 0
		var expected_appearances := 0
		for record in matches:
			if record.family != family: continue
			expected_appearances += record.a.size() + record.b.size()
			if record.result == "A": expected_wins += record.a.size()
			elif record.result == "B": expected_wins += record.b.size()
			elif record.result == "draw": expected_draws += record.a.size() + record.b.size()
		var actual_wins := 0
		var actual_draws := 0
		var actual_appearances := 0
		for unit_stats in groups[family].units.values():
			actual_wins += unit_stats.wins
			actual_draws += unit_stats.draws
			actual_appearances += unit_stats.appearances
		if actual_wins != expected_wins or actual_draws != expected_draws or actual_appearances != expected_appearances:
			push_error("Aggregate denominator/winner mismatch: " + family)
			return false
	return true

func _distribution(values: Array) -> Dictionary:
	if values.is_empty(): return {"n": 0, "mean": 0.0, "median": 0.0, "p90": 0.0}
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	for value in sorted: total += float(value)
	var midpoint := sorted.size() / 2
	var median: float = sorted[midpoint] if sorted.size() % 2 else (sorted[midpoint - 1] + sorted[midpoint]) / 2.0
	return {"n": sorted.size(), "mean": total / sorted.size(), "median": median, "p90": sorted[maxi(0, ceili(0.9 * sorted.size()) - 1)]}

func _save_csv() -> void:
	var file := FileAccess.open(output_dir.path_join(label + "_matches.csv"), FileAccess.WRITE)
	file.store_csv_line(PackedStringArray(["scenario", "family", "team_a", "team_b", "seed", "result", "duration", "first_hit_time", "wall_ms"]))
	var units_file := FileAccess.open(output_dir.path_join(label + "_units.csv"), FileAccess.WRITE)
	units_file.store_csv_line(PackedStringArray(["scenario", "family", "uid", "id", "team", "survived", "damage_dealt", "damage_taken", "death_time", "ttk", "skill_uses", "target_changes", "status_uptime"]))
	for record in matches:
		file.store_csv_line(PackedStringArray([record.scenario, record.family, "+".join(record.a), "+".join(record.b), str(record.seed), record.result, str(record.duration), str(record.get("first_hit_time", -1)), str(record.wall_ms)]))
		for unit in record.units:
			units_file.store_csv_line(PackedStringArray([record.scenario, record.family, str(unit.uid), unit.id, str(unit.team), str(unit.survived), str(unit.damage_dealt), str(unit.get("damage_taken", unit.get("taken", 0))), str(unit.death_time), str(unit.ttk), JSON.stringify(unit.get("skill_uses", {})), str(unit.get("target_changes", 0)), str(unit.get("status_uptime", 0))]))
	file.close()
	units_file.close()

func _save_trace(id: String, events: Array) -> void:
	var file := FileAccess.open(output_dir.path_join(label + "_" + id + "_trace.jsonl"), FileAccess.WRITE)
	for event in events: file.store_line(JSON.stringify(event))
	file.close()

func _source_hash() -> Dictionary:
	var paths: Array[String] = []
	for directory in ["res://scripts", "res://resources"]: _collect_sources(directory, paths)
	paths.sort()
	var hashes: Dictionary = {}
	var combined := ""
	for path in paths:
		var bytes := FileAccess.get_file_as_bytes(path)
		var hash_context := HashingContext.new()
		hash_context.start(HashingContext.HASH_SHA256)
		hash_context.update(bytes)
		var digest := hash_context.finish().hex_encode()
		hashes[path] = digest
		combined += path + ":" + digest + "\n"
	return {"sha256": combined.sha256_text(), "files": hashes}

func _collect_sources(directory: String, paths: Array[String]) -> void:
	var dir := DirAccess.open(directory)
	if dir == null: return
	for file in dir.get_files():
		if file.get_extension() in ["gd", "tres"]: paths.append(directory.path_join(file))
	for child in dir.get_directories(): _collect_sources(directory.path_join(child), paths)

