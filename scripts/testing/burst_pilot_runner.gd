extends SceneTree
## Bounded deterministic calibration for the three initial-burst candidates.
const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Variants = preload("res://scripts/data/combat_variants.gd")
const PILOTS := ["eagle_hippo", "monkey_hippo", "bear_cheetah"]
const WATCHDOG := 120.0
const GEOMETRIES := [
	{"name":"center", "a":Vector2(280,250), "b":Vector2(840,250)},
	{"name":"offset", "a":Vector2(170,220), "b":Vector2(950,280)},
	{"name":"wide", "a":Vector2(420,190), "b":Vector2(700,310)}
]
const TRIOS := [
	{"id":"fast_into_thorns", "roster":["cheetah","rabbit","hedgehog"]},
	{"id":"backline_under_pressure", "roster":["monkey","skunk","eagle"]},
	{"id":"burst_and_control", "roster":["bear","hippo","rabbit"]}
]
const FINAL_MIXED_TEAMS := [
	{"id":"eagle_front_vs_ranged", "a":["eagle_hippo","bear"], "b":["monkey_skunk","cheetah_eagle"]},
	{"id":"eagle_control_vs_bruiser", "a":["eagle_hippo","hippo"], "b":["bear_cheetah","rabbit"]},
	{"id":"monkey_utility_vs_diver", "a":["monkey_hippo","skunk"], "b":["eagle_hedgehog","bear"]},
	{"id":"monkey_control_vs_fast", "a":["monkey_hippo","hedgehog"], "b":["cheetah_eagle","rabbit"]},
	{"id":"bear_ranged_vs_counter", "a":["bear_cheetah","monkey"], "b":["hippo_rabbit","skunk"]},
	{"id":"bear_front_vs_thorns", "a":["bear_cheetah","eagle"], "b":["bear_hedgehog","hippo"]}
]

var variant := "B"
var output_dir := "res://reports/burst_pilot"
var label := "burst_pilot"
var include_final_coverage := false
var cases: Array[Dictionary] = []
var records: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_parse_args(OS.get_cmdline_user_args())
	if variant not in ["A", "B"]:
		push_error("--variant must be A or B")
		quit(2)
		return
	var absolute := ProjectSettings.globalize_path(output_dir)
	if DirAccess.make_dir_recursive_absolute(absolute) != OK:
		push_error("Cannot create report directory: " + absolute)
		quit(2)
		return
	cases = _final_scenarios() if include_final_coverage else _scenarios()
	var overrides := Variants.definitions(variant)
	var started := Time.get_ticks_msec()
	for scenario in cases:
		var sim := Sim.new()
		var options: Dictionary = scenario.options.duplicate(true)
		options.definitions = overrides
		if not sim.setup(scenario.a, scenario.b, scenario.seed, options):
			push_error("Setup failed %s: %s" % [scenario.id, str(sim.validation_errors)])
			quit(2)
			return
		var initial_positions: Array = []
		for unit: Dictionary in sim.units: initial_positions.append([unit.pos.x,unit.pos.y])
		while sim.result == "running" and sim.time < WATCHDOG: sim.step()
		var row: Dictionary = sim.summary()
		row.merge({"scenario":scenario.id,"family":scenario.family,"pilot":scenario.pilot,
			"roster":scenario.roster,"geometry":scenario.geometry,"seed":scenario.seed,"a":scenario.a,"b":scenario.b,
			"fixture":scenario.get("fixture", ""),
			"positions":initial_positions,"death_before_first_cast":_death_before_first_cast(row.units)},true)
		if sim.result == "running": row.result = "inconclusive"
		records.append(row)
		if records.size() % 64 == 0: print("BURST PILOT %d/%d" % [records.size(),cases.size()])
	var report := {"label":label,"variant":variant,"engine":Engine.get_version_info().string,
		"created_utc":Time.get_datetime_string_from_system(true),"dt":1.0/60.0,
		"watchdog_seconds":WATCHDOG,"wall_ms":Time.get_ticks_msec()-started,
		"interpretation":"Bounded deterministic scenarios, not population win rates. Each pilot faces every lvl1 in both orientations and multiple layouts; pair and trio results use the explicit roster list.",
		"scenario_count":records.size(),"coverage":_coverage(),"pilots":_analyze(),
		"selected_b_peer_results":_peer_results(),"mixed_team_results":_mixed_team_results(),"matches":records}
	var path := absolute.path_join(label + ".json")
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write report: " + path)
		quit(2)
		return
	file.store_string(JSON.stringify(report,"\t")); file.close()
	print("BURST PILOT COMPLETE: %d cases, variant %s: %s" % [records.size(),variant,path])
	for id in report.pilots:
		var item: Dictionary = report.pilots[id]
		print("%s singles=%d/%d pair wins=%d pair losses=%d trio wins=%d trio losses=%d casts=%d death-before-cast=%d" % [id,item.single_wins,item.single_cases,item.pair_wins,item.pair_losses,item.trio_wins,item.trio_losses,item.cast_count,item.death_before_first_cast])
	quit(0)

func _parse_args(args: PackedStringArray) -> void:
	for i in range(args.size()):
		if args[i] == "--variant" and i+1 < args.size(): variant = args[i+1].to_upper()
		elif args[i] == "--output" and i+1 < args.size(): output_dir = args[i+1]
		elif args[i] == "--label" and i+1 < args.size(): label = args[i+1]
		elif args[i] == "--final-coverage": include_final_coverage = true

func _scenarios() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var serial := 0
	for pilot in PILOTS:
		for opponent in Catalog.ids():
			for geometry in GEOMETRIES:
				for side in 2:
					var a: Array = [pilot] if side == 0 else [opponent]
					var b: Array = [opponent] if side == 0 else [pilot]
					var positions: Array[Vector2] = []
					if side == 0: positions = [geometry.a,geometry.b]
					else: positions = [Vector2(1120-geometry.b.x,geometry.b.y),Vector2(1120-geometry.a.x,geometry.a.y)]
					out.append(_case(serial,"single",pilot,[opponent],geometry.name,a,b,{"positions":positions})); serial += 1
		for first in range(8):
			for second in range(first,8):
				var pair: Array = [Catalog.ids()[first],Catalog.ids()[second]]
				for side in 2:
					var a: Array = [pilot] if side == 0 else pair
					var b: Array = pair if side == 0 else [pilot]
					out.append(_case(serial,"pair",pilot,pair,"role_default",a,b,{})); serial += 1
		for trio in TRIOS:
			for side in 2:
				var a: Array = [pilot] if side == 0 else trio.roster
				var b: Array = trio.roster if side == 0 else [pilot]
				out.append(_case(serial,"trio",pilot,trio.roster,"role_default",a,b,{})); serial += 1
	return out

func _final_scenarios() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var serial := 0
	for pilot in PILOTS:
		for opponent in Catalog.hybrid_ids():
			for side in 2:
				var a: Array = [pilot] if side == 0 else [opponent]
				var b: Array = [opponent] if side == 0 else [pilot]
				out.append(_case(serial,"pilot_vs_hybrid",pilot,[opponent],"role_default",a,b,{})); serial += 1
	for matchup in FINAL_MIXED_TEAMS:
		for side in 2:
			var a: Array = matchup.a if side == 0 else matchup.b
			var b: Array = matchup.b if side == 0 else matchup.a
			var row := _case(serial,"mixed_team", "", [matchup.id], "role_default", a, b, {})
			row["fixture"] = matchup.id
			out.append(row); serial += 1
	return out

func _case(serial: int, family: String, pilot: String, roster: Array, geometry: String, a: Array, b: Array, options: Dictionary) -> Dictionary:
	var id := "%s_%s_%03d" % [family,pilot,serial]
	return {"id":id,"family":family,"pilot":pilot,"roster":roster,"geometry":geometry,
		"a":a,"b":b,"seed":1,"options":options}

func _death_before_first_cast(units: Array) -> Array[String]:
	var ids: Array[String] = []
	for unit: Dictionary in units:
		var casts := 0
		for count in unit.skill_uses.values(): casts += int(count)
		if unit.death_time >= 0.0 and casts == 0: ids.append(unit.id)
	return ids

func _coverage() -> Dictionary:
	var families := ["single","pair","trio","pilot_vs_hybrid","mixed_team"]
	var result := {"per_pilot":{}}
	for family in families: result[family] = 0
	for id in PILOTS:
		result.per_pilot[id] = {}
		for family in families: result.per_pilot[id][family] = 0
	for row in records:
		result[row.family] += 1
		if PILOTS.has(row.pilot): result.per_pilot[row.pilot][row.family] += 1
	return result

func _analyze() -> Dictionary:
	var output := {}
	for pilot in PILOTS:
		var item := {"single_cases":0,"single_wins":0,"single_losses":0,"single_draws":0,
			"pair_wins":0,"pair_losses":0,"pair_draws":0,"trio_wins":0,"trio_losses":0,"trio_draws":0,
			"damage_dealt":0.0,"damage_taken":0.0,"survivals":0,"appearances":0,"cast_count":0,
			"death_before_first_cast":0,"first_cast_times":[],"damage_by_skill":{},"casts_by_skill":{}}
		for row in records:
			if row.pilot != pilot or row.family in ["pilot_vs_hybrid","mixed_team"]: continue
			var won := _pilot_won(row)
			if row.family == "single":
				item.single_cases += 1
				if won: item.single_wins += 1
				elif row.result == "draw": item.single_draws += 1
				else: item.single_losses += 1
			elif row.family == "pair":
				if won: item.pair_wins += 1
				elif row.result == "draw": item.pair_draws += 1
				else: item.pair_losses += 1
			else:
				if won: item.trio_wins += 1
				elif row.result == "draw": item.trio_draws += 1
				else: item.trio_losses += 1
			for unit: Dictionary in row.units:
				if unit.id != pilot: continue
				item.appearances += 1
				item.damage_dealt += unit.damage_dealt
				item.damage_taken += unit.damage_taken
				if unit.survived: item.survivals += 1
				for skill in unit.skill_uses:
					var count := int(unit.skill_uses[skill])
					item.cast_count += count
					item.casts_by_skill[skill] = int(item.casts_by_skill.get(skill,0)) + count
				for skill in unit.damage_by_skill:
					item.damage_by_skill[skill] = float(item.damage_by_skill.get(skill,0.0)) + float(unit.damage_by_skill[skill])
				if unit.first_skill_start_time >= 0.0: item.first_cast_times.append(unit.first_skill_start_time)
				if unit.death_time >= 0 and unit.skill_uses.is_empty(): item.death_before_first_cast += 1
		output[pilot] = item
	return output

func _peer_results() -> Dictionary:
	var output := {}
	for pilot in PILOTS:
		output[pilot] = {"cases":0,"wins":0,"losses":0,"draws":0,"by_opponent":{}}
	for row in records:
		if row.family != "pilot_vs_hybrid": continue
		var opponent: String = row.roster[0]
		var item: Dictionary = output[row.pilot]
		if not item.by_opponent.has(opponent): item.by_opponent[opponent] = {"cases":0,"wins":0,"losses":0,"draws":0}
		var matchup: Dictionary = item.by_opponent[opponent]
		item.cases += 1; matchup.cases += 1
		if row.result == "draw": item.draws += 1; matchup.draws += 1
		elif _pilot_won(row): item.wins += 1; matchup.wins += 1
		else: item.losses += 1; matchup.losses += 1
	return output

func _mixed_team_results() -> Dictionary:
	var groups := {}
	for row in records:
		if row.family != "mixed_team": continue
		var fixture: String = str(row.get("fixture", row.roster[0]))
		if not groups.has(fixture): groups[fixture] = {"a_roster":[],"b_roster":[],"results":[]}
		groups[fixture].results.append(row.result)
		if groups[fixture].results.size() == 1:
			groups[fixture].a_roster = row.a
			groups[fixture].b_roster = row.b
	for fixture in groups:
		var results: Array = groups[fixture].results
		groups[fixture]["mirrored_outcome"] = results.size() == 2 and ((results[0] == "draw" and results[1] == "draw") or (results[0] == "A" and results[1] == "B") or (results[0] == "B" and results[1] == "A"))
	return groups

func _pilot_won(row: Dictionary) -> bool:
	if row.result == "draw" or row.result == "inconclusive": return false
	var pilot_on_a: bool = row.a.size() == 1 and row.a[0] == row.pilot
	return (pilot_on_a and row.result == "A") or (not pilot_on_a and row.result == "B")
