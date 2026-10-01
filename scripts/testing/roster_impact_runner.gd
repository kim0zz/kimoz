extends SceneTree
## Bounded A/B roster comparison for the full lvl1/lvl2 roster.
## 40 fixed matchup fixtures x two mirrored sides x A/B = 160 fights.

const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Variants = preload("res://scripts/data/combat_variants.gd")
const ARENA := Vector2(1120.0, 500.0)
const WATCHDOG := 120.0
const KINDS := ["basic", "skill", "dot", "thorns"]
const ALL_UNITS := ["bear", "cheetah", "monkey", "eagle", "hedgehog", "hippo", "skunk", "rabbit",
	"bear_cheetah", "bear_monkey", "bear_hedgehog", "cheetah_eagle", "cheetah_rabbit", "monkey_skunk",
	"monkey_hippo", "eagle_hedgehog", "eagle_hippo", "hippo_rabbit", "hedgehog_skunk", "skunk_rabbit"]

var output_dir := "res://reports/full_roster"
var label := "full_roster_ab"
var six_only := false
var fixtures: Array[Dictionary] = []
var records: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_parse_args(OS.get_cmdline_user_args())
	if six_only and label == "full_roster_ab": label = "full_roster_ab_six"
	var output_absolute := ProjectSettings.globalize_path(output_dir)
	if DirAccess.make_dir_recursive_absolute(output_absolute) != OK:
		_fail("Cannot create report directory: " + output_absolute)
		return
	var catalog := Catalog.load_units()
	if catalog.size() != 20:
		_fail("Expected 20 catalog units; found %d" % catalog.size())
		return
	var definitions_a: Dictionary = Variants.definitions("A")
	var definitions_b: Dictionary = Variants.definitions("B")
	if definitions_a.size() != ALL_UNITS.size() or definitions_b.size() != ALL_UNITS.size():
		_fail("CombatVariants must provide all 20 roster definitions for A and B")
		return
	fixtures = _six_v_six_fixtures(catalog) if six_only else _fixtures(catalog)
	var fixture_validation := _validate_fixtures(fixtures,4 if six_only else 40)
	if not fixture_validation.pass:
		for error in fixture_validation.errors: push_error(error)
		quit(2)
		return
	var hash_start := _source_hash()
	var started := Time.get_ticks_msec()
	for fixture in fixtures:
		for mirror_side in [0, 1]:
			var scenario := _oriented_fixture(fixture, mirror_side)
			for variant in ["A", "B"]:
				var definitions: Dictionary = definitions_a if variant == "A" else definitions_b
				var sim := Sim.new()
				var options := {"definitions": definitions, "positions": scenario.positions}
				if not sim.setup(scenario.a, scenario.b, int(scenario.seed), options):
					_fail("Setup failed %s/%s/%s: %s" % [scenario.id, variant, str(mirror_side), str(sim.validation_errors)])
					return
				var damage_events: Array[Dictionary] = []
				var utility := {"aggro_breaks": 0, "forced_retargets": 0, "stun_events": 0}
				while sim.result == "running" and sim.time < WATCHDOG:
					sim.step()
					for event in sim.events:
						if event.get("kind", "") == "damage":
							damage_events.append({"source": int(event.source), "target": int(event.target),
								"kind": str(event.damage_kind), "skill": str(event.get("skill", "")),
								"amount": float(event.applied)})
						elif event.get("kind", "") == "aggro_break":
							utility.aggro_breaks += 1
						elif event.get("kind", "") == "target" and event.get("reason", "") == "rabbit_aggro_break":
							utility.forced_retargets += 1
						elif event.get("kind", "") == "stun":
							utility.stun_events += 1
				var row: Dictionary = sim.summary()
				row.merge({"scenario": scenario.id, "fixture": fixture.id, "family": fixture.family,
					"variant": variant, "mirror_group": fixture.id, "mirror_side": mirror_side,
					"a": scenario.a, "b": scenario.b, "seed": scenario.seed,
					"positions": _positions_as_arrays(scenario.positions),
					"focal_units": fixture.focal_units, "control": bool(fixture.control),
					"active_damage_events": damage_events, "utility_events": utility}, true)
				if sim.result == "running": row.result = "inconclusive"
				records.append(row)
		if records.size() % 32 == 0:
			print("FULL ROSTER A/B %d/160" % records.size())
	var hash_end := _source_hash()
	var validation := _validate_records(fixtures)
	if hash_start.sha256 != hash_end.sha256:
		validation.errors.append("Source files changed during run")
		validation.pass = false
	if not validation.pass:
		for error in validation.errors: push_error(error)
		quit(2)
		return
	var report := {"label": label, "created_utc": Time.get_datetime_string_from_system(true),
		"engine": Engine.get_version_info().string, "dt": 1.0 / 60.0,
		"watchdog_seconds": WATCHDOG, "mode": "six_v_six" if six_only else "mixed_3v3",
		"fixture_count": fixtures.size(), "fight_count": records.size(),
		"wall_ms": Time.get_ticks_msec() - started, "source_hash_start": hash_start,
		"source_hash_end": hash_end, "sources_changed_during_run": false,
		"coverage": fixture_validation, "validation": validation,
		"interpretation": "Deterministic finite roster contexts, not a randomized tournament, general win rate, or 50/50 duel estimate. A/B deltas compare these exact paired rosters and positions. Aggro break, forced retarget, and stun are utility proxies only; they do not establish causality.",
		"fixture_index": fixtures, "family_summary": _family_summary(),
		"unit_summary": _unit_summary(), "unit_b_minus_a": _unit_deltas(),
		"mirror_checks": _mirror_summary(), "matches": records}
	var file := FileAccess.open(output_absolute.path_join(label + ".json"), FileAccess.WRITE)
	if file == null:
		_fail("Cannot write report JSON")
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	_save_csv(output_absolute)
	print("FULL ROSTER A/B COMPLETE: %d fights; %.2fs; %s" % [records.size(), float(report.wall_ms) / 1000.0, output_absolute])
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(2)

func _parse_args(args: PackedStringArray) -> void:
	for i in range(args.size()):
		if args[i] == "--output" and i + 1 < args.size(): output_dir = args[i + 1]
		elif args[i] == "--label" and i + 1 < args.size(): label = args[i + 1]
		elif args[i] == "--six-only": six_only = true

func _six_v_six_fixtures(catalog: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_add_fixture(out,"six_v_six","six_front_diver",
		["bear_hedgehog","bear_cheetah","eagle_hippo","bear","cheetah","eagle"],
		["monkey_skunk","monkey_hippo","skunk_rabbit","monkey","skunk","rabbit"],
		catalog,[],[],ALL_UNITS,false)
	_add_fixture(out,"six_v_six","six_diver_backline",
		["cheetah_eagle","eagle_hedgehog","hippo_rabbit","hippo","hedgehog","cheetah"],
		["bear_monkey","hedgehog_skunk","cheetah_rabbit","monkey","skunk","rabbit"],
		catalog,[],[],ALL_UNITS,false)
	_add_fixture(out,"six_v_six","six_thorns_vs_fast",
		["bear_hedgehog","eagle_hedgehog","monkey_skunk","bear","monkey","hippo"],
		["cheetah_rabbit","cheetah_eagle","skunk_rabbit","cheetah","rabbit","skunk"],
		catalog,[],[],ALL_UNITS,false)
	_add_fixture(out,"six_v_six","six_burst_vs_control",
		["bear_cheetah","bear_monkey","monkey_hippo","bear","monkey","hedgehog"],
		["eagle_hippo","hippo_rabbit","hedgehog_skunk","eagle","hippo","skunk"],
		catalog,[],[],ALL_UNITS,false)
	return out

func _fixtures(catalog: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	# 24 balanced 3v3 suites rotate every one of the 20 units through focal duty.
	# Teams match the focal unit's level profile; this prevents using isolated duels as a proxy.
	for i in range(24):
		var unit_index: int = i % ALL_UNITS.size()
		var focal: String = ALL_UNITS[unit_index]
		var opponent: String
		var a: Array[String]
		var b: Array[String]
		if unit_index < 8:
			var l1: int = unit_index
			opponent = ALL_UNITS[(l1 + 4) % 8]
			a = [focal, ALL_UNITS[(l1 + 1) % 8], ALL_UNITS[8 + (i % 12)]]
			b = [opponent, ALL_UNITS[(l1 + 5) % 8], ALL_UNITS[8 + ((i + 6) % 12)]]
		else:
			var h: int = unit_index - 8
			opponent = ALL_UNITS[8 + ((h + 6) % 12)]
			a = [focal, ALL_UNITS[(h + 1) % 12 + 8], ALL_UNITS[(h % 8)]]
			b = [opponent, ALL_UNITS[(h + 7) % 12 + 8], ALL_UNITS[(h + 4) % 8]]
		_add_fixture(out, "balanced_coverage", "coverage_%02d" % i, a, b, catalog, [], [], [focal, opponent], false)
	# Explicit, matched role probes. Controls change one roster member at a time.
	var guard_enemy: Array[String] = ["monkey_skunk", "monkey", "cheetah"]
	var guard_positions := [Vector2(175,250), Vector2(365,190), Vector2(365,310),
		Vector2(790,170), Vector2(790,250), Vector2(790,330)]
	var exposed_positions := [Vector2(365,250), Vector2(175,165), Vector2(175,335),
		Vector2(790,170), Vector2(790,250), Vector2(790,330)]
	_add_fixture(out,"guarded_carry","carry_guarded",["monkey_hippo","bear","bear_hedgehog"],guard_enemy,catalog,guard_positions,[],["monkey_hippo"],false)
	_add_fixture(out,"guarded_carry","carry_exposed",["monkey_hippo","bear","bear_hedgehog"],guard_enemy,catalog,exposed_positions,[],["monkey_hippo"],false)
	_add_fixture(out,"guarded_carry","carry_guard_control",["monkey_hippo","bear","bear_cheetah"],guard_enemy,catalog,guard_positions,[],["monkey_hippo"],true)
	_add_fixture(out,"guarded_carry","carry_exposed_control",["monkey_hippo","bear","bear_cheetah"],guard_enemy,catalog,exposed_positions,[],["monkey_hippo"],true)
	var dive_backline := [Vector2(300,250), Vector2(445,185), Vector2(445,315),
		Vector2(850,170), Vector2(850,250), Vector2(850,330)]
	var dive_screen := [Vector2(300,250), Vector2(445,185), Vector2(445,315),
		Vector2(700,170), Vector2(850,250), Vector2(850,330)]
	_add_fixture(out,"diver_impact","diver_backline",["eagle_hippo","bear","skunk"],["hippo","monkey_hippo","monkey_skunk"],catalog,dive_backline,[],["eagle_hippo"],false)
	_add_fixture(out,"diver_impact","diver_screened",["eagle_hippo","bear","skunk"],["hippo","monkey_hippo","monkey_skunk"],catalog,dive_screen,[],["eagle_hippo"],false)
	_add_fixture(out,"diver_impact","diver_control_backline",["eagle_hedgehog","bear","skunk"],["hippo","monkey_hippo","monkey_skunk"],catalog,dive_backline,[],["eagle_hedgehog"],true)
	_add_fixture(out,"diver_impact","diver_control_screened",["eagle_hedgehog","bear","skunk"],["hippo","monkey_hippo","monkey_skunk"],catalog,dive_screen,[],["eagle_hedgehog"],true)
	var fast_cluster := [Vector2(300,220), Vector2(430,200), Vector2(430,300),
		Vector2(720,200), Vector2(780,250), Vector2(720,300)]
	var fast_spread := [Vector2(300,220), Vector2(430,200), Vector2(430,300),
		Vector2(690,90), Vector2(760,250), Vector2(850,410)]
	_add_fixture(out,"thorns_vs_fast","thorns_fast_clustered",["bear_hedgehog","bear","skunk"],["cheetah","rabbit","hippo"],catalog,fast_cluster,[],["bear_hedgehog"],false)
	_add_fixture(out,"thorns_vs_fast","thorns_fast_spread",["bear_hedgehog","bear","skunk"],["cheetah","rabbit","hippo"],catalog,fast_spread,[],["bear_hedgehog"],false)
	_add_fixture(out,"thorns_vs_fast","thorns_control_clustered",["hedgehog","bear","skunk"],["cheetah","rabbit","hippo"],catalog,fast_cluster,[],["hedgehog"],true)
	_add_fixture(out,"thorns_vs_fast","thorns_control_spread",["hedgehog","bear","skunk"],["cheetah","rabbit","hippo"],catalog,fast_spread,[],["hedgehog"],true)
	var cone_cluster := [Vector2(300,250), Vector2(430,170), Vector2(430,330),
		Vector2(720,200), Vector2(780,250), Vector2(720,300)]
	var cone_spread := [Vector2(300,250), Vector2(430,170), Vector2(430,330),
		Vector2(680,90), Vector2(780,250), Vector2(880,410)]
	_add_fixture(out,"cone_formation","cone_clustered",["bear_cheetah","bear","monkey"],["hippo","skunk","rabbit"],catalog,cone_cluster,[],["bear_cheetah"],false)
	_add_fixture(out,"cone_formation","cone_spread",["bear_cheetah","bear","monkey"],["hippo","skunk","rabbit"],catalog,cone_spread,[],["bear_cheetah"],false)
	_add_fixture(out,"cone_formation","cone_control_clustered",["bear","cheetah","monkey"],["hippo","skunk","rabbit"],catalog,cone_cluster,[],["bear","cheetah"],true)
	_add_fixture(out,"cone_formation","cone_control_spread",["bear","cheetah","monkey"],["hippo","skunk","rabbit"],catalog,cone_spread,[],["bear","cheetah"],true)
	return out

func _add_fixture(out: Array[Dictionary], family: String, id: String, a: Array[String], b: Array[String], catalog: Dictionary,
		positions_a: Array, positions_b: Array, focal: Array, control: bool) -> void:
	var positions: Array[Vector2] = []
	if positions_a.size() == a.size() + b.size() and positions_b.is_empty():
		for point in positions_a: positions.append(Vector2(point))
	else:
		positions.append_array(positions_a if not positions_a.is_empty() else _default_positions(a,0,catalog))
		positions.append_array(positions_b if not positions_b.is_empty() else _default_positions(b,1,catalog))
	if positions.size() != a.size() + b.size():
		push_error("Invalid explicit formation in fixture " + id)
		return
	out.append({"id":id,"family":family,"a":a,"b":b,"positions":positions,
		"focal_units":focal,"control":control,"seed":1})

func _default_positions(roster: Array, team: int, catalog: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for slot in range(roster.size()):
		var definition: Resource = catalog[roster[slot]]
		var x := 300.0 if definition.role in ["front", "melee", "mobile"] else 180.0
		if team == 1: x = ARENA.x - x
		out.append(Vector2(x, ARENA.y * (slot + 1.0) / (roster.size() + 1.0)))
	return out

func _oriented_fixture(fixture: Dictionary, mirror_side: int) -> Dictionary:
	if mirror_side == 0:
		return {"id":fixture.id + "_a","a":fixture.a.duplicate(),"b":fixture.b.duplicate(),
			"positions":fixture.positions.duplicate(),"seed":fixture.seed}
	var mirrored: Array[Vector2] = []
	var team_b_positions: Array = fixture.positions.slice(fixture.a.size())
	var team_a_positions: Array = fixture.positions.slice(0,fixture.a.size())
	for point in team_b_positions: mirrored.append(Vector2(ARENA.x - point.x, point.y))
	for point in team_a_positions: mirrored.append(Vector2(ARENA.x - point.x, point.y))
	return {"id":fixture.id + "_b","a":fixture.b.duplicate(),"b":fixture.a.duplicate(),
		"positions":mirrored,"seed":fixture.seed}

func _validate_fixtures(rows: Array[Dictionary], expected_count: int) -> Dictionary:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	var focal_seen: Dictionary = {}
	if rows.size() != expected_count: errors.append("Expected %d fixture groups; found %d" % [expected_count,rows.size()])
	for fixture in rows:
		if seen.has(fixture.id): errors.append("Duplicate fixture id: " + fixture.id)
		seen[fixture.id] = true
		for id in fixture.a + fixture.b:
			if id not in ALL_UNITS: errors.append("Unknown full-roster fixture unit: " + str(id))
		for id in fixture.focal_units: focal_seen[id] = true
		if fixture.positions.size() != fixture.a.size() + fixture.b.size(): errors.append("Formation size mismatch: " + fixture.id)
	for id in ALL_UNITS:
		if not focal_seen.has(id): errors.append("Unit never appears as focal: " + id)
	return {"pass":errors.is_empty(),"fixture_groups":rows.size(),"mirrored_configurations":rows.size()*2,
		"fight_count":rows.size()*4,"unit_ids_covered":focal_seen.keys().size(),"errors":errors}

func _validate_records(expected: Array[Dictionary]) -> Dictionary:
	var errors: Array[String] = []
	var expected_fights := expected.size() * 4
	if records.size() != expected_fights: errors.append("Expected %d A/B fights; found %d" % [expected_fights,records.size()])
	var by_key: Dictionary = {}
	for row in records:
		if row.result == "inconclusive": errors.append("Watchdog reached: " + row.scenario)
		var dealt := 0.0
		var taken := 0.0
		for unit in row.units:
			dealt += float(unit.damage_dealt)
			taken += float(unit.damage_taken)
			var kind_total := 0.0
			for kind in unit.damage_by_kind:
				if kind not in KINDS: errors.append("Unknown damage kind %s in %s" % [kind,row.scenario])
				kind_total += float(unit.damage_by_kind[kind])
			if absf(kind_total - float(unit.damage_dealt)) > 0.02:
				errors.append("Damage-kind sum mismatch: %s/%s" % [row.scenario,unit.id])
		var event_total := 0.0
		for event in row.active_damage_events: event_total += float(event.amount)
		if absf(dealt - taken) > 0.02: errors.append("Damage dealt/taken mismatch: " + row.scenario)
		if absf(event_total - dealt) > 0.02: errors.append("Event/damage sum mismatch: " + row.scenario)
		var key := "%s/%s/%d" % [row.fixture,row.variant,row.mirror_side]
		if by_key.has(key): errors.append("Duplicate run key: " + key)
		by_key[key] = row
	for fixture in expected:
		for variant in ["A","B"]:
			var left_key := "%s/%s/0" % [fixture.id,variant]
			var right_key := "%s/%s/1" % [fixture.id,variant]
			if not by_key.has(left_key) or not by_key.has(right_key):
				errors.append("Missing mirror member: %s/%s" % [fixture.id,variant])
				continue
			var left: Dictionary = by_key[left_key]
			var right: Dictionary = by_key[right_key]
			if left.a != fixture.a or left.b != fixture.b or right.a != fixture.b or right.b != fixture.a:
				errors.append("Mirror roster mismatch: %s/%s" % [fixture.id,variant])
			for index in fixture.positions.size():
				var source_index: int = index
				var expected_point: Array = left.positions[source_index]
				var target_index: int = fixture.b.size() + index if index < fixture.a.size() else index - fixture.a.size()
				var mirrored_point: Array = right.positions[target_index]
				if absf(float(expected_point[0]) + float(mirrored_point[0]) - ARENA.x) > 0.01 or absf(float(expected_point[1]) - float(mirrored_point[1])) > 0.01:
					errors.append("Mirror position mismatch: %s/%s" % [fixture.id,variant])
					break
			if not _opposite_results(left.result,right.result): errors.append("Mirror result mismatch: %s/%s" % [fixture.id,variant])
			if absf(float(left.duration)-float(right.duration)) > 1.0/60.0 + 0.0001:
				errors.append("Mirror duration mismatch: %s/%s" % [fixture.id,variant])
	return {"pass":errors.is_empty(),"fight_count":records.size(),"mirror_groups":expected.size(),
		"damage_dealt_taken_equal_within_0_02":errors.is_empty(),"damage_kind_sums_equal_within_0_02":errors.is_empty(),
		"watchdog_stalls":0,"errors":errors}

func _opposite_results(a: String, b: String) -> bool:
	if a == "A": return b == "B"
	if a == "B": return b == "A"
	return a == b

func _positions_as_arrays(positions: Array) -> Array:
	var out: Array = []
	for point in positions: out.append([Vector2(point).x,Vector2(point).y])
	return out

func _family_summary() -> Dictionary:
	var out: Dictionary = {}
	for family in ["balanced_coverage","guarded_carry","diver_impact","thorns_vs_fast","cone_formation","six_v_six"]:
		out[family] = {"A":_new_family_stats(),"B":_new_family_stats()}
	for row in records:
		if not out.has(row.family): out[row.family] = {"A":_new_family_stats(),"B":_new_family_stats()}
		var stats: Dictionary = out[row.family][row.variant]
		stats.fights += 1
		stats.duration_sum += float(row.duration)
		stats.durations.append(float(row.duration))
		stats.aggro_breaks += int(row.utility_events.aggro_breaks)
		stats.forced_retargets += int(row.utility_events.forced_retargets)
		stats.stun_events += int(row.utility_events.stun_events)
		stats.stun_victim_seconds += _stun_seconds(row.units)
		for unit in row.units:
			for kind in KINDS: stats.damage_by_kind[kind] += float(unit.damage_by_kind.get(kind,0.0))
		if row.result == "A": stats.a_wins += 1
		elif row.result == "B": stats.b_wins += 1
		else: stats.draws += 1
	for family in out:
		for variant in ["A","B"]:
			var stats: Dictionary = out[family][variant]
			stats.mean_duration = _ratio(float(stats.duration_sum),int(stats.fights))
			stats.median_duration = _median(stats.durations)
			var total_damage := 0.0
			for kind in KINDS: total_damage += float(stats.damage_by_kind[kind])
			stats.skill_damage_share = _ratio(float(stats.damage_by_kind.skill),total_damage)
			stats.dot_damage_share = _ratio(float(stats.damage_by_kind.dot),total_damage)
			stats.active_damage_share = _ratio(float(stats.damage_by_kind.skill + stats.damage_by_kind.dot),total_damage)
			stats.erase("duration_sum")
			stats.erase("durations")
	return out

func _new_family_stats() -> Dictionary:
	return {"fights":0,"a_wins":0,"b_wins":0,"draws":0,"inconclusive":0,
		"duration_sum":0.0,"durations":[],"mean_duration":0.0,"median_duration":0.0,
		"damage_by_kind":{"basic":0.0,"skill":0.0,"dot":0.0,"thorns":0.0},
		"skill_damage_share":0.0,"dot_damage_share":0.0,"active_damage_share":0.0,
		"aggro_breaks":0,"forced_retargets":0,"stun_events":0,"stun_victim_seconds":0.0}

func _unit_summary() -> Dictionary:
	var out: Dictionary = {}
	for row in records:
		for unit in row.units:
			var key := "%s/%s/%s" % [row.family,row.variant,unit.id]
			if not out.has(key): out[key] = _new_unit_stats(unit.id,row.family,row.variant)
			var stats: Dictionary = out[key]
			stats.appearances += 1
			stats.survivals += 1 if unit.survived else 0
			stats.damage_dealt += float(unit.damage_dealt)
			stats.damage_taken += float(unit.damage_taken)
			stats.stun_victim_seconds += float(unit.stun_uptime)
			stats.stagger_victim_seconds += float(unit.stagger_uptime)
			stats.slow_victim_seconds += float(unit.slow_uptime)
			for kind in KINDS: stats.damage[kind] += float(unit.damage_by_kind.get(kind,0.0))
			var casts := 0
			for skill in unit.skill_uses: casts += int(unit.skill_uses[skill])
			stats.casts += casts
			if float(unit.first_skill_start_time) >= 0.0:
				stats.first_casts += 1
				stats.first_cast_time_sum += float(unit.first_skill_start_time)
			elif not unit.survived:
				stats.deaths_before_first_cast += 1
			if not unit.survived and float(unit.ttk) >= 0.0:
				stats.death_count += 1
				stats.death_ttk_sum += float(unit.ttk)
	for key in out:
		var stats: Dictionary = out[key]
		stats.survival_rate = _ratio(stats.survivals,stats.appearances)
		stats.mean_damage_dealt = _ratio(stats.damage_dealt,stats.appearances)
		stats.mean_damage_taken = _ratio(stats.damage_taken,stats.appearances)
		stats.mean_first_cast_seconds = _ratio(stats.first_cast_time_sum,stats.first_casts)
		stats.mean_death_ttk = _ratio(stats.death_ttk_sum,stats.death_count)
		stats.erase("survivals"); stats.erase("first_cast_time_sum"); stats.erase("death_ttk_sum")
	return out

func _unit_deltas() -> Dictionary:
	var summaries := _unit_summary()
	var out: Dictionary = {}
	for fixture in fixtures:
		for unit_id in ALL_UNITS:
			var prefix := str(fixture.family) + "/"
			var key_a: String = prefix + "A/" + unit_id
			var key_b: String = prefix + "B/" + unit_id
			if not summaries.has(key_a) or not summaries.has(key_b): continue
			var a: Dictionary = summaries[key_a]
			var b: Dictionary = summaries[key_b]
			var delta_key: String = prefix + unit_id
			if out.has(delta_key): continue
			var damage_delta := {}
			for kind in KINDS: damage_delta[kind] = float(b.damage[kind]) - float(a.damage[kind])
			out[delta_key] = {"unit_id":unit_id,"level":a.level,"family":fixture.family,
				"appearances_A":a.appearances,"appearances_B":b.appearances,
				"survival_rate_delta_B_minus_A":float(b.survival_rate)-float(a.survival_rate),
				"mean_damage_dealt_delta_B_minus_A":float(b.mean_damage_dealt)-float(a.mean_damage_dealt),
				"mean_damage_taken_delta_B_minus_A":float(b.mean_damage_taken)-float(a.mean_damage_taken),
				"damage_by_kind_delta_B_minus_A":damage_delta,
				"casts_delta_B_minus_A":int(b.casts)-int(a.casts),
				"deaths_before_first_cast_delta_B_minus_A":int(b.deaths_before_first_cast)-int(a.deaths_before_first_cast),
				"mean_first_cast_seconds_delta_B_minus_A":float(b.mean_first_cast_seconds)-float(a.mean_first_cast_seconds),
				"mean_death_ttk_delta_B_minus_A":float(b.mean_death_ttk)-float(a.mean_death_ttk)}
	return out

func _new_unit_stats(unit_id: String, family: String, variant: String) -> Dictionary:
	var definition: Resource = Catalog.load_units()[unit_id]
	var damage := {"basic":0.0,"skill":0.0,"dot":0.0,"thorns":0.0}
	return {"unit_id":unit_id,"level":int(definition.level),"family":family,"variant":variant,
		"appearances":0,"survivals":0,"survival_rate":0.0,"damage_dealt":0.0,"damage_taken":0.0,
		"mean_damage_dealt":0.0,"mean_damage_taken":0.0,"damage":damage,"casts":0,"first_casts":0,
		"mean_first_cast_seconds":0.0,"deaths_before_first_cast":0,"death_count":0,"mean_death_ttk":0.0,
		"stun_victim_seconds":0.0,"stagger_victim_seconds":0.0,"slow_victim_seconds":0.0,
		"first_cast_time_sum":0.0,"death_ttk_sum":0.0}

func _stun_seconds(units: Array) -> float:
	var total := 0.0
	for unit in units: total += float(unit.stun_uptime)
	return total

func _mirror_summary() -> Dictionary:
	var out := {"checks":0,"failures":0,"max_duration_delta":0.0}
	for fixture in fixtures:
		for variant in ["A","B"]:
			var left: Dictionary = _find_record(fixture.id,variant,0)
			var right: Dictionary = _find_record(fixture.id,variant,1)
			if left.is_empty() or right.is_empty(): continue
			out.checks += 1
			var duration_delta := absf(float(left.duration)-float(right.duration))
			out.max_duration_delta = maxf(float(out.max_duration_delta),duration_delta)
			if not _opposite_results(left.result,right.result) or duration_delta > 1.0/60.0 + 0.0001:
				out.failures += 1
	return out

func _find_record(fixture: String, variant: String, side: int) -> Dictionary:
	for row in records:
		if row.fixture == fixture and row.variant == variant and int(row.mirror_side) == side: return row
	return {}

func _ratio(numerator: float, denominator: float) -> float:
	return numerator / denominator if denominator > 0.0 else 0.0

func _median(values: Array) -> float:
	if values.is_empty(): return 0.0
	var sorted: Array = values.duplicate()
	sorted.sort()
	var middle := int(sorted.size() / 2)
	return float(sorted[middle]) if sorted.size() % 2 == 1 else (float(sorted[middle-1]) + float(sorted[middle])) * 0.5

func _source_hash() -> Dictionary:
	var paths: Array[String] = []
	_collect("res://scripts/combat",paths)
	_collect("res://scripts/data",paths)
	_collect("res://resources",paths)
	paths.append("res://scripts/testing/roster_impact_runner.gd")
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
	return {"sha256":combined.sha256_text(),"files":files}

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
		if dir.current_is_dir(): _collect(path,paths)
		elif name.ends_with(".gd") or name.ends_with(".tres") or name.ends_with(".json"): paths.append(path)
		name = dir.get_next()
	dir.list_dir_end()

func _save_csv(absolute: String) -> void:
	var file := FileAccess.open(absolute.path_join(label + "_matches.csv"),FileAccess.WRITE)
	file.store_csv_line(PackedStringArray(["fixture","family","variant","mirror_side","team_a","team_b","result","duration","first_hit_time","aggro_breaks","forced_retargets","stun_events","stun_victim_seconds"]))
	var units_file := FileAccess.open(absolute.path_join(label + "_units.csv"),FileAccess.WRITE)
	units_file.store_csv_line(PackedStringArray(["fixture","family","variant","uid","unit_id","level","team","survived","damage_dealt","damage_taken","basic","skill","dot","thorns","skill_uses","first_skill_start_time","death_time","ttk","stun_uptime","target_changes"]))
	for row in records:
		file.store_csv_line(PackedStringArray([row.fixture,row.family,row.variant,str(row.mirror_side),"+".join(row.a),"+".join(row.b),row.result,str(row.duration),str(row.first_hit_time),str(row.utility_events.aggro_breaks),str(row.utility_events.forced_retargets),str(row.utility_events.stun_events),str(_stun_seconds(row.units))]))
		for unit in row.units:
			units_file.store_csv_line(PackedStringArray([row.fixture,row.family,row.variant,str(unit.uid),unit.id,str(unit.level),str(unit.team),str(unit.survived),str(unit.damage_dealt),str(unit.damage_taken),str(unit.damage_by_kind.get("basic",0.0)),str(unit.damage_by_kind.get("skill",0.0)),str(unit.damage_by_kind.get("dot",0.0)),str(unit.damage_by_kind.get("thorns",0.0)),JSON.stringify(unit.skill_uses),str(unit.first_skill_start_time),str(unit.death_time),str(unit.ttk),str(unit.stun_uptime),str(unit.target_changes)]))
	file.close()
	units_file.close()
