extends SceneTree
## Offline structural and acceptance checks for a completed lvl2 balance report.
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _run() -> void:
	var path := "res://reports/lvl2/lvl2_baseline.json"
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--report" and i+1 < args.size(): path = args[i+1]
	var file := FileAccess.open(path, FileAccess.READ)
	_check(file != null, "Report exists: " + path)
	if file == null:
		_finish()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	_check(parsed is Dictionary, "Report parses as a JSON object")
	if not parsed is Dictionary:
		_finish()
		return
	var report: Dictionary = parsed
	_check(report.get("selected_family", "") == "", "Complete suite report, not filtered slice")
	_check(int(report.get("scenario_count", 0)) == 1996, "Expected 1996 full scenarios, including mixed teams and targeted ablations")
	var coverage: Dictionary = report.get("coverage", {})
	var actual: Dictionary = coverage.get("families", {})
	_check(int(actual.get("lvl2_vs_lvl1", -1)) == 576, "576 lvl2-versus-single cases")
	_check(int(actual.get("lvl2_vs_lvl1_pair", -1)) == 864, "864 lvl2-versus-pair cases")
	_check(int(actual.get("lvl2_vs_lvl2", -1)) == 420, "420 lvl2 head-to-head cases")
	_check(int(actual.get("lvl2_vs_lvl1_trio", -1)) == 72, "72 representative lvl2-versus-trio cases")
	_check(int(actual.get("mixed_team_sanity", -1)) == 16, "16 mirrored mixed-team sanity cases")
	_check(int(actual.get("ablation_cases", -1)) == 48, "48 paired single-mechanic ablation cases")
	_check(not bool(report.get("sources_changed_during_run", true)), "Source hash stable during run")
	var acceptance: Dictionary = report.get("acceptance", {})
	for assertion in ["every_hybrid_beats_each_lvl1_in_coverage", "mirrors_invert_and_match_duration",
		"lvl2_vs_two_lvl1_has_both_outcomes", "lvl2_vs_three_lvl1_has_both_outcomes",
		"all_cases_complete", "fixture_starts_nonoverlapping"]:
		_check(acceptance.has(assertion), "Acceptance result present: " + assertion)
		if acceptance.has(assertion):
			_check(bool(acceptance[assertion].get("pass", false)), "Acceptance result passes: " + assertion)
	_check(acceptance.has("lvl2_head_to_head_score_band"), "Head-to-head review band is reported as a diagnostic")
	var matches: Array = report.get("matches", [])
	_check(matches.size() == 1996, "Raw case rows preserve full scenario count")
	var missing_fields := 0
	for row in matches:
		for field in ["scenario", "family", "a", "b", "result", "duration", "units", "positions"]:
			if not row.has(field): missing_fields += 1
	_check(missing_fields == 0, "Raw case rows include matchup, result, positions and unit metrics")
	_finish()

func _finish() -> void:
	print("LVL2 BALANCE REPORT ASSERTIONS: %d checks, %d failures" % [checks, failures.size()])
	for failure in failures: printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
