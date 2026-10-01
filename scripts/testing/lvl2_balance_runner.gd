extends SceneTree
## Deterministic finite coverage for lvl2 hybrids; not population win-rate data.
const Sim = preload("res://scripts/combat/combat_simulation.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
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
const MIXED_TEAMS := [
	{"id":"thorns_vs_fast", "a":["bear_hedgehog","bear"], "b":["cheetah","rabbit"]},
	{"id":"diver_into_backline", "a":["cheetah_eagle","bear"], "b":["monkey","skunk"]},
	{"id":"control_vs_burst", "a":["monkey_hippo","skunk"], "b":["hippo","cheetah"]},
	{"id":"aoe_vs_group", "a":["bear_cheetah","monkey"], "b":["hedgehog","skunk","bear"]},
	{"id":"hybrid_frontline", "a":["bear_monkey","eagle"], "b":["bear_hedgehog","rabbit"]},
	{"id":"double_ranged", "a":["monkey_skunk","skunk"], "b":["eagle","hippo"]},
	{"id":"mixed_three", "a":["eagle_hedgehog","bear","monkey"], "b":["cheetah","hippo","skunk"]},
	{"id":"mobile_counter", "a":["hippo_rabbit","bear"], "b":["eagle","monkey","rabbit"]}
]
const ABLATIONS := [
	{"id":"thorns_vs_fast", "hybrid":"bear_hedgehog", "roster":["cheetah"], "skill":"bear_hedgehog_thorns"},
	{"id":"movement_vs_ranged", "hybrid":"cheetah_eagle", "roster":["monkey"], "skill":"cheetah_eagle_dive"},
	{"id":"control_vs_burst", "hybrid":"monkey_hippo", "roster":["hippo"], "skill":"stun"},
	{"id":"aoe_vs_group", "hybrid":"bear_cheetah", "roster":["bear","hippo","cheetah"], "skill":"bear_cheetah_cone"}
]
var output_dir := "res://reports/lvl2"
var label := "lvl2_balance"
var scenario_filter := ""
var family_filter := ""
var include_ablations := true
var cases: Array[Dictionary] = []
var records: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_parse_args(OS.get_cmdline_user_args())
	var hybrids: Array[String] = Catalog.hybrid_ids()
	var lvl1: Array[String] = Catalog.ids()
	if hybrids.size() != 12 or lvl1.size() != 8:
		push_error("Expected exactly 12 lvl2 and 8 lvl1 IDs")
		quit(2)
		return
	var output_absolute := ProjectSettings.globalize_path(output_dir)
	if DirAccess.make_dir_recursive_absolute(output_absolute) != OK:
		push_error("Cannot create report directory: " + output_absolute)
		quit(2)
		return
	cases = _scenarios(hybrids, lvl1)
	if not family_filter.is_empty():
		var selected_families := family_filter.split(",", false)
		cases = cases.filter(func(c: Dictionary) -> bool: return c.family in selected_families)
	if not scenario_filter.is_empty():
		cases = cases.filter(func(c: Dictionary) -> bool: return c.id == scenario_filter)
		if cases.is_empty():
			push_error("Unknown scenario: " + scenario_filter)
			quit(2)
			return
	var started := Time.get_ticks_msec()
	var source_hash_start := _source_hash()
	for scenario in cases:
		var sim := Sim.new()
		var options: Dictionary = scenario.options.duplicate(true)
		if not sim.setup(scenario.a, scenario.b, scenario.seed, options):
			push_error("Setup failed %s: %s" % [scenario.id, str(sim.validation_errors)])
			quit(2)
			return
		var positions: Array = []
		var initial_overlap_pairs := 0
		for i in range(sim.units.size()):
			var unit: Dictionary = sim.units[i]
			positions.append([unit.pos.x, unit.pos.y])
			for j in range(i+1,sim.units.size()):
				if sim.edge_distance(unit,sim.units[j]) < -0.01: initial_overlap_pairs += 1
		var case_started := Time.get_ticks_usec()
		while sim.result == "running" and sim.time < WATCHDOG: sim.step()
		var record: Dictionary = sim.summary()
		record.merge({"scenario":scenario.id, "family":scenario.family, "key":scenario.key,
			"mirror_group":scenario.mirror_group, "mirror_side":scenario.mirror_side,
			"a":scenario.a, "b":scenario.b, "seed":scenario.seed, "positions":positions,
			"geometry":scenario.geometry, "skills_disabled":options.get("disable_skills",false),
			"initial_overlap_pairs":initial_overlap_pairs,
			"wall_ms":float(Time.get_ticks_usec()-case_started)/1000.0}, true)
		if sim.result == "running": record.result = "inconclusive"
		records.append(record)
		if records.size() % 128 == 0: print("LVL2 BALANCE %d/%d" % [records.size(),cases.size()])
	var assertions := _analyze()
	var source_hash_end := _source_hash()
	var report := {"label":label, "engine":Engine.get_version_info().string,
		"created_utc":Time.get_datetime_string_from_system(true), "dt":1.0/60.0,
		"watchdog_seconds":WATCHDOG, "wall_ms":Time.get_ticks_msec()-started,
		"source_hash_start":source_hash_start, "source_hash_end":source_hash_end,
		"sources_changed_during_run":source_hash_start.sha256 != source_hash_end.sha256,
		"selected_family":family_filter, "scenario_count":records.size(),
		"interpretation":"Deterministic finite coverage, not independent trials or population win rates. TTK excludes survivors.",
		"coverage":_coverage(hybrids,lvl1), "acceptance":assertions,
		"counterevidence":_counterevidence(),
		"mechanism_ablation":_ablation_summary(),
		"groups":_aggregate(), "matches":records}
	var report_path := output_absolute.path_join(label + ".json")
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write report: " + report_path)
		quit(2)
		return
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	_save_csv(output_absolute)
	print("LVL2 BALANCE COMPLETE %d cases in %.2fs: %s" % [records.size(),float(report.wall_ms)/1000.0,report_path])
	for name in assertions:
		var item: Dictionary = assertions[name]
		print("%s: %s — %s" % [name,"PASS" if item.pass else "REVIEW",item.summary])
	quit(0)

func _parse_args(args: PackedStringArray) -> void:
	for i in range(args.size()):
		if args[i] == "--output" and i+1 < args.size(): output_dir = args[i+1]
		elif args[i] == "--label" and i+1 < args.size(): label = args[i+1]
		elif args[i] == "--scenario" and i+1 < args.size(): scenario_filter = args[i+1]
		elif args[i] == "--family" and i+1 < args.size(): family_filter = args[i+1]
		elif args[i] == "--no-ablations": include_ablations = false

func _scenarios(hybrids: Array[String], lvl1: Array[String]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for h in hybrids:
		for base in lvl1:
			for g in GEOMETRIES:
				_add_duel_pair(out,"lvl2_vs_lvl1",h,[base],g,"single|%s|%s|%s" % [h,base,g.name])
		for i in range(lvl1.size()):
			for j in range(i,lvl1.size()):
				var pair: Array[String] = [lvl1[i],lvl1[j]]
				_add_pair(out,"lvl2_vs_lvl1_pair",h,pair,"pair|%s|%s+%s" % [h,pair[0],pair[1]])
		for trio in TRIOS:
			_add_pair(out,"lvl2_vs_lvl1_trio",h,trio.roster,"trio|%s|%s" % [h,trio.id])
	for i in range(hybrids.size()):
		for j in range(i,hybrids.size()):
			var layouts: Array = GEOMETRIES if i != j else [GEOMETRIES[0]]
			for g in layouts:
				_add_duel_pair(out,"lvl2_vs_lvl2",hybrids[i],[hybrids[j]],g,"hybrid|%s|%s|%s" % [hybrids[i],hybrids[j],g.name])
	for matchup in MIXED_TEAMS:
		var g: Dictionary = GEOMETRIES[0]
		var key: String = "mixed|"+matchup.id
		_add_case(out,"mixed_team_sanity",key,matchup.a,matchup.b,g.name,{"positions":_positions(matchup.a.size(),matchup.b.size(),g,false)},0)
		_add_case(out,"mixed_team_sanity",key,matchup.b,matchup.a,g.name,{"positions":_positions(matchup.a.size(),matchup.b.size(),g,true)},1)
	if include_ablations:
		for ab in ABLATIONS:
			for g in GEOMETRIES:
				for disabled in [false,true]:
					var family := "ablation_axis_off" if disabled else "ablation_axis_on"
					var key := "ablation|%s|%s" % [ab.id,g.name]
					var options_a := {"positions":_positions(1,ab.roster.size(),g,false)}
					var options_b := {"positions":_positions(1,ab.roster.size(),g,true)}
					if disabled:
						var modified := _without_mechanism(ab.hybrid,ab.skill)
						options_a.definitions = {ab.hybrid:modified}
						options_b.definitions = {ab.hybrid:modified}
					_add_case(out,family,key,[ab.hybrid],ab.roster,g.name,options_a,0)
					_add_case(out,family,key,ab.roster,[ab.hybrid],g.name,options_b,1)
	return out

func _add_duel_pair(out: Array[Dictionary], family: String, a_id: String, b: Array, g: Dictionary, key: String) -> void:
	_add_case(out,family,key,[a_id],b,g.name,{"positions":_positions(1,b.size(),g,false)},0)
	_add_case(out,family,key,b,[a_id],g.name,{"positions":_positions(1,b.size(),g,true)},1)

func _positions(a_count: int, b_count: int, g: Dictionary, mirrored: bool) -> Array[Vector2]:
	var a_points := _slot_points(a_count, g.a)
	var b_points := _slot_points(b_count, g.b)
	var result: Array[Vector2] = []
	if not mirrored:
		result.append_array(a_points)
		result.append_array(b_points)
	else:
		for point in b_points: result.append(Vector2(1120.0-point.x, point.y))
		for point in a_points: result.append(Vector2(1120.0-point.x, point.y))
	return result

func _slot_points(count: int, center: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for slot in range(count):
		var vertical := (float(slot)-(count-1)*0.5)*76.0
		points.append(Vector2(center.x,center.y+vertical))
	return points

func _without_mechanism(unit_id: String, mechanism: String) -> Resource:
	var original: Resource = Catalog.load_units()[unit_id]
	var modified: Resource = original.duplicate(true)
	var original_skills: Array = modified.skills.duplicate()
	modified.skills.clear()
	for skill in original_skills:
		if skill.id == mechanism: continue
		var copy: Resource = skill.duplicate(true)
		if mechanism == "stun":
			copy.stun_duration = 0.0
			copy.followup_stun = 0.0
		modified.skills.append(copy)
	return modified

func _add_pair(out: Array[Dictionary], family: String, hybrid: String, roster: Array, key: String) -> void:
	_add_case(out,family,key,[hybrid],roster,"role_default",{},0)
	_add_case(out,family,key,roster,[hybrid],"role_default",{},1)

func _add_case(out: Array[Dictionary], family: String, key: String, a: Array, b: Array, geometry: String, options: Dictionary, side: int) -> void:
	var safe_key := key.replace("|","_").replace("+","-")
	var id := "%s__%s__%s__%s" % [family,safe_key,geometry,"a" if side == 0 else "b"]
	if family.begins_with("ablation_"): id += "__" + family.trim_prefix("ablation_")
	out.append({"id":id,"family":family,"key":key,"mirror_group":"%s|%s|%s" % [family,key,geometry],
		"mirror_side":side,"a":a,"b":b,"geometry":geometry,"seed":1,"options":options})

func _coverage(hybrids: Array[String], lvl1: Array[String]) -> Dictionary:
	var counts := {"lvl2_vs_lvl1":0,"lvl2_vs_lvl1_pair":0,"lvl2_vs_lvl2":0,"lvl2_vs_lvl1_trio":0,"ablation_cases":0}
	for record in records:
		if counts.has(record.family): counts[record.family] += 1
		if record.family.begins_with("ablation_"): counts.ablation_cases += 1
	counts["mixed_team_sanity"] = 0
	for record in records:
		if record.family == "mixed_team_sanity": counts["mixed_team_sanity"] += 1
	return {"lvl1_ids":lvl1,"hybrid_ids":hybrids,"families":counts,
		"expected_lvl2_vs_lvl1":hybrids.size()*lvl1.size()*GEOMETRIES.size()*2,
		"expected_lvl2_vs_lvl1_pair":hybrids.size()*36*2,"expected_lvl2_vs_lvl2":420,
		"expected_lvl2_vs_lvl1_trio":hybrids.size()*TRIOS.size()*2,"expected_mixed_team_sanity":MIXED_TEAMS.size()*2}

func _analyze() -> Dictionary:
	var singles := {}
	var duo_wins := 0
	var duo_losses := 0
	var trio_wins := 0
	var trio_losses := 0
	var witnesses := {"duo_hybrid_win":"","duo_pair_win":"","trio_hybrid_win":"","trio_team_win":""}
	var mirror_groups := {}
	for r in records:
		if r.family == "lvl2_vs_lvl1":
			var h: String = r.a[0] if r.a.size() == 1 and r.a[0] in Catalog.hybrid_ids() else r.b[0]
			var base: String = r.b[0] if h == r.a[0] else r.a[0]
			var key := h+"|"+base
			if not singles.has(key): singles[key] = {"wins":0,"losses":0,"draws":0,"n":0}
			var won := _hybrid_won(r)
			singles[key].n += 1
			if r.result == "draw": singles[key].draws += 1
			elif won: singles[key].wins += 1
			else: singles[key].losses += 1
		elif r.family == "lvl2_vs_lvl1_pair" or r.family == "lvl2_vs_lvl1_trio":
			var won := _hybrid_won(r)
			if r.result in ["A","B"]:
				var prefix := "duo" if r.family == "lvl2_vs_lvl1_pair" else "trio"
				if won:
					if prefix == "duo": duo_wins += 1
					else: trio_wins += 1
					if witnesses[prefix+"_hybrid_win"].is_empty(): witnesses[prefix+"_hybrid_win"] = r.scenario
				else:
					if prefix == "duo": duo_losses += 1
					else: trio_losses += 1
					var witness_key := "duo_pair_win" if prefix == "duo" else "trio_team_win"
					if witnesses[witness_key].is_empty(): witnesses[witness_key] = r.scenario
		if r.family in ["lvl2_vs_lvl1","lvl2_vs_lvl1_pair","lvl2_vs_lvl1_trio","lvl2_vs_lvl2","mixed_team_sanity"]:
			var group_key: String = str(r.family)+"|"+str(r.key)
			if not mirror_groups.has(group_key): mirror_groups[group_key] = []
			mirror_groups[group_key].append(r)
	var single_bad: Array[String] = []
	for key in singles:
		var s: Dictionary = singles[key]
		if s.losses or s.draws: single_bad.append("%s wins=%d losses=%d draws=%d" % [key,s.wins,s.losses,s.draws])
	var mirror_bad: Array[String] = []
	for key in mirror_groups:
		var pair: Array = mirror_groups[key]
		if pair.size() != 2: continue
		if not _opposite(pair[0].result,pair[1].result) or absf(pair[0].duration-pair[1].duration) > 1.0/60.0:
			mirror_bad.append("%s: %s/%.3f vs %s/%.3f" % [key,pair[0].result,pair[0].duration,pair[1].result,pair[1].duration])
	var l2l2: Array = records.filter(func(r: Dictionary) -> bool: return r.family == "lvl2_vs_lvl2" and r.result != "inconclusive")
	var individual_scores := _hybrid_head_to_head_scores(l2l2)
	var score_outliers: Array[String] = []
	for id in individual_scores:
		var score: float = individual_scores[id].score_rate
		if score < 0.35 or score > 0.65: score_outliers.append("%s=%.3f (n=%d)" % [id,score,individual_scores[id].appearances])
	var inconclusive := 0
	for r in records:
		if r.result == "inconclusive": inconclusive += 1
	return {
		"every_hybrid_beats_each_lvl1_in_coverage":{"pass":single_bad.is_empty(),"summary":"%d pairings; %d counterexamples" % [singles.size(),single_bad.size()],"counterexamples":single_bad},
		"mirrors_invert_and_match_duration":{"pass":mirror_bad.is_empty(),"summary":"%d mirror pairs; %d mismatches" % [mirror_groups.size(),mirror_bad.size()],"witnesses":mirror_bad.slice(0,20)},
		"lvl2_vs_two_lvl1_has_both_outcomes":{"pass":duo_wins>0 and duo_losses>0,"summary":"hybrid wins=%d, pair wins=%d; %s / %s" % [duo_wins,duo_losses,witnesses.duo_hybrid_win,witnesses.duo_pair_win]},
		"lvl2_vs_three_lvl1_has_both_outcomes":{"pass":trio_wins>0 and trio_losses>0,"summary":"hybrid wins=%d, trio wins=%d; %s / %s" % [trio_wins,trio_losses,witnesses.trio_hybrid_win,witnesses.trio_team_win]},
		"lvl2_head_to_head_score_band":{"pass":score_outliers.is_empty(),"summary":"%d/12 individual hybrids outside 0.35–0.65 band" % score_outliers.size(),"outliers":score_outliers,"per_hybrid":individual_scores},
		"all_cases_complete":{"pass":inconclusive==0,"summary":"%d/%d complete; %d watchdog cases" % [records.size()-inconclusive,records.size(),inconclusive]},
		"fixture_starts_nonoverlapping":{"pass":records.all(func(r: Dictionary) -> bool: return r.initial_overlap_pairs == 0),"summary":"overlapping starts in %d/%d cases" % [records.filter(func(r: Dictionary) -> bool: return r.initial_overlap_pairs > 0).size(),records.size()]}}

func _hybrid_won(r: Dictionary) -> bool:
	var h_a: bool = r.a.size() == 1 and r.a[0] in Catalog.hybrid_ids()
	return (r.result == "A" and h_a) or (r.result == "B" and not h_a)

func _opposite(a: String, b: String) -> bool:
	return (a == "A" and b == "B") or (a == "B" and b == "A") or (a == "draw" and b == "draw")

func _hybrid_head_to_head_scores(rows: Array) -> Dictionary:
	var scores := {}
	for id in Catalog.hybrid_ids(): scores[id] = {"appearances":0,"points":0.0,"score_rate":0.0}
	for r in rows:
		var a_id: String = r.a[0]
		var b_id: String = r.b[0]
		if a_id == b_id or r.result == "inconclusive": continue
		scores[a_id].appearances += 1
		scores[b_id].appearances += 1
		if r.result == "A": scores[a_id].points += 1.0
		elif r.result == "B": scores[b_id].points += 1.0
		elif r.result == "draw":
			scores[a_id].points += 0.5
			scores[b_id].points += 0.5
	for id in scores:
		scores[id].score_rate = _ratio(scores[id].points,scores[id].appearances)
	return scores

func _aggregate() -> Dictionary:
	var groups := {}
	for r in records:
		if not groups.has(r.family): groups[r.family] = {"cases":0,"A":0,"B":0,"draw":0,"inconclusive":0,"durations":[],"first_hits":[],"ttks":[],"units":{}}
		var g: Dictionary = groups[r.family]
		g.cases += 1
		g[r.result] = int(g.get(r.result,0))+1
		if r.result != "inconclusive": g.durations.append(r.duration)
		if r.first_hit_time >= 0: g.first_hits.append(r.first_hit_time)
		for u in r.units:
			var id: String = u.id
			if not g.units.has(id): g.units[id] = {"n":0,"wins":0,"draws":0,"survivals":0,"damage_dealt":0.0,"damage_taken":0.0,"life":0.0,"ttks":[],"status_uptime":0.0,"stun_uptime":0.0,"stagger_uptime":0.0,"slow_uptime":0.0,"skill_uses":{},"skill_opportunities":{},"target_changes":0}
			var s: Dictionary = g.units[id]
			s.n += 1
			var team_result := "A" if u.team == 0 else "B"
			if r.result == team_result: s.wins += 1
			elif r.result == "draw": s.draws += 1
			if u.survived: s.survivals += 1
			s.damage_dealt += u.damage_dealt
			s.damage_taken += u.damage_taken
			s.life += u.death_time if u.death_time >= 0 else r.duration
			s.status_uptime += u.get("status_uptime",0.0)
			s.stun_uptime += u.get("stun_uptime",0.0)
			s.stagger_uptime += u.get("stagger_uptime",0.0)
			s.slow_uptime += u.get("slow_uptime",0.0)
			s.target_changes += u.get("target_changes",0)
			if u.ttk >= 0: s.ttks.append(u.ttk)
			if u.ttk >= 0: g.ttks.append(u.ttk)
			for skill in u.skill_uses: s.skill_uses[skill] = s.skill_uses.get(skill,0)+u.skill_uses[skill]
			for skill in u.skill_opportunities: s.skill_opportunities[skill] = s.skill_opportunities.get(skill,0)+u.skill_opportunities[skill]
	for family in groups:
		var g: Dictionary = groups[family]
		var n: int = g.cases-g.inconclusive
		g.win_rate_a = _ratio(g.A,n)
		g.win_rate_b = _ratio(g.B,n)
		g.duration = _distribution(g.durations)
		g.first_hit = _distribution(g.first_hits)
		g.ttk = _distribution(g.ttks)
		g.erase("durations"); g.erase("first_hits"); g.erase("ttks")
		for id in g.units:
			var s: Dictionary = g.units[id]
			s.score_rate = _ratio(s.wins+0.5*s.draws,s.n)
			s.survival_rate = _ratio(s.survivals,s.n)
			s.damage_per_life_second = _ratio(s.damage_dealt,s.life)
			s.damage_taken_per_life_second = _ratio(s.damage_taken,s.life)
			s.status_fraction = _ratio(s.status_uptime,s.life)
			s.stun_fraction = _ratio(s.stun_uptime,s.life)
			s.stagger_fraction = _ratio(s.stagger_uptime,s.life)
			s.slow_fraction = _ratio(s.slow_uptime,s.life)
			s.target_changes_per_life_second = _ratio(s.target_changes,s.life)
			s.ttk = _distribution(s.ttks)
			s.erase("ttks")
	return groups

func _ablation_summary() -> Dictionary:
	var paired := {}
	for r in records:
		if not r.family.begins_with("ablation_axis_"): continue
		var key: String = r.key+"|"+str(r.mirror_side)
		if not paired.has(key): paired[key] = {}
		paired[key]["off" if r.family == "ablation_axis_off" else "on"] = r
	var by_case := {}
	for pair_key in paired:
		var pair: Dictionary = paired[pair_key]
		if not pair.has("on") or not pair.has("off"): continue
		var on: Dictionary = pair.on
		var off: Dictionary = pair.off
		var case_id: String = on.key.split("|")[1]
		if not by_case.has(case_id): by_case[case_id] = {"n":0,"on_wins":0,"off_wins":0,"score_delta_sum":0.0,"damage_delta_sum":0.0,"duration_delta_sum":0.0}
		var values: Dictionary = by_case[case_id]
		values.n += 1
		var hybrid_id := _hybrid_id(on)
		var on_points := _team_points(on,hybrid_id)
		var off_points := _team_points(off,hybrid_id)
		values.score_delta_sum += on_points-off_points
		if on_points == 1.0: values.on_wins += 1
		if off_points == 1.0: values.off_wins += 1
		values.damage_delta_sum += _unit_damage(on,hybrid_id)-_unit_damage(off,hybrid_id)
		values.duration_delta_sum += float(on.duration)-float(off.duration)
	for case_id in by_case:
		var values: Dictionary = by_case[case_id]
		values.hybrid_score_delta_on_minus_off = _ratio(values.score_delta_sum,values.n)
		values.hybrid_damage_delta_on_minus_off = _ratio(values.damage_delta_sum,values.n)
		values.duration_delta_on_minus_off = _ratio(values.duration_delta_sum,values.n)
		values.erase("score_delta_sum"); values.erase("damage_delta_sum"); values.erase("duration_delta_sum")
	return {"interpretation":"Paired counterfactuals remove one named hybrid mechanic at a time; values describe these fixtures only.","cases":by_case}

func _hybrid_id(record: Dictionary) -> String:
	for u in record.units:
		if u.id in Catalog.hybrid_ids(): return u.id
	return ""

func _counterevidence() -> Dictionary:
	var output := {"lvl2_vs_two_lvl1":{},"lvl2_vs_three_lvl1":{}}
	for family in ["lvl2_vs_lvl1_pair","lvl2_vs_lvl1_trio"]:
		var key := "lvl2_vs_two_lvl1" if family == "lvl2_vs_lvl1_pair" else "lvl2_vs_three_lvl1"
		for hybrid in Catalog.hybrid_ids(): output[key][hybrid] = {"n":0,"hybrid_wins":0,"lvl1_team_wins":0,"draws":0,"team_win_rosters":{},"hybrid_loss_witnesses":[]}
		for r in records:
			if r.family != family: continue
			var hybrid := _hybrid_id(r)
			if hybrid.is_empty(): continue
			var item: Dictionary = output[key][hybrid]
			item.n += 1
			if r.result == "draw": item.draws += 1
			elif _hybrid_won(r): item.hybrid_wins += 1
			else:
				item.lvl1_team_wins += 1
				var roster: Array = r.b if r.a.size() == 1 and r.a[0] == hybrid else r.a
				var roster_key := "+".join(roster)
				item.team_win_rosters[roster_key] = int(item.team_win_rosters.get(roster_key,0))+1
				if item.hybrid_loss_witnesses.size() < 12: item.hybrid_loss_witnesses.append(r.scenario)
	return output

func _team_points(record: Dictionary, hybrid_id: String) -> float:
	for u in record.units:
		if u.id == hybrid_id:
			if record.result == "draw": return 0.5
			if (u.team == 0 and record.result == "A") or (u.team == 1 and record.result == "B"): return 1.0
	return 0.0

func _unit_damage(record: Dictionary, hybrid_id: String) -> float:
	for u in record.units:
		if u.id == hybrid_id: return float(u.damage_dealt)
	return 0.0

func _ratio(a: float, b: float) -> float:
	return a/b if b>0 else 0.0

func _distribution(values: Array) -> Dictionary:
	if values.is_empty(): return {"n":0,"mean":0.0,"median":0.0,"p90":0.0}
	var sorted: Array = values.duplicate(); sorted.sort()
	var total := 0.0
	for v in sorted: total += float(v)
	var mid := sorted.size()/2
	var median := float(sorted[mid]) if sorted.size()%2 else (float(sorted[mid-1])+float(sorted[mid]))/2.0
	return {"n":sorted.size(),"mean":total/sorted.size(),"median":median,"p90":sorted[maxi(0,ceili(0.9*sorted.size())-1)]}

func _save_csv(directory: String) -> void:
	var matches_file := FileAccess.open(directory.path_join(label+"_matches.csv"),FileAccess.WRITE)
	var units_file := FileAccess.open(directory.path_join(label+"_units.csv"),FileAccess.WRITE)
	matches_file.store_csv_line(PackedStringArray(["scenario","family","key","team_a","team_b","geometry","skills_disabled","seed","result","duration","first_hit_time","ending_1v1","ending_1v1_time","wall_ms"]))
	units_file.store_csv_line(PackedStringArray(["scenario","family","uid","id","team","survived","hp","damage_dealt","damage_taken","death_time","ttk","status_uptime","stun_uptime","stagger_uptime","slow_uptime","skill_uses","skill_opportunities","target_changes"]))
	for r in records:
		matches_file.store_csv_line(PackedStringArray([r.scenario,r.family,r.key,"+".join(r.a),"+".join(r.b),r.geometry,str(r.skills_disabled),str(r.seed),r.result,str(r.duration),str(r.first_hit_time),str(r.get("ending_1v1",false)),str(r.get("ending_1v1_time",0.0)),str(r.wall_ms)]))
		for u in r.units:
			units_file.store_csv_line(PackedStringArray([r.scenario,r.family,str(u.uid),u.id,str(u.team),str(u.survived),str(u.hp),str(u.damage_dealt),str(u.damage_taken),str(u.death_time),str(u.ttk),str(u.status_uptime),str(u.stun_uptime),str(u.get("stagger_uptime",0.0)),str(u.get("slow_uptime",0.0)),JSON.stringify(u.skill_uses),JSON.stringify(u.skill_opportunities),str(u.target_changes)]))
	matches_file.close(); units_file.close()

func _source_hash() -> Dictionary:
	var paths: Array[String] = []
	for root in ["res://scripts/combat","res://scripts/data","res://resources"]: _collect(root,paths)
	paths.append("res://scripts/testing/lvl2_balance_runner.gd")
	paths.sort()
	var hashes := {}; var combined := ""
	for path in paths:
		var bytes := FileAccess.get_file_as_bytes(path)
		var context := HashingContext.new(); context.start(HashingContext.HASH_SHA256); context.update(bytes)
		var digest := context.finish().hex_encode(); hashes[path] = digest; combined += path+":"+digest+"\n"
	return {"sha256":combined.sha256_text(),"files":hashes}

func _collect(path: String, output: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null: return
	for file in dir.get_files():
		if file.get_extension() in ["gd","tres"]: output.append(path.path_join(file))
	for child in dir.get_directories(): _collect(path.path_join(child),output)
