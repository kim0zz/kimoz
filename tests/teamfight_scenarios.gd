extends SceneTree
## Small diagnostic sample, not a matchup balance matrix.
const Sim = preload("res://scripts/combat/teamfight_simulation.gd")
const Data = preload("res://scripts/data/teamfight_definitions.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var reports: Array = []
	for preset: Dictionary in Data.presets():
		for mirrored in [false, true]:
			var sim := Sim.new()
			assert(sim.setup(preset.b if mirrored else preset.a, preset.a if mirrored else preset.b, 42))
			var events_count: Dictionary = {}
			for frame in range(60 * 120):
				sim.step()
				for event: Dictionary in sim.events:
					var kind := str(event.kind)
					events_count[kind] = int(events_count.get(kind, 0)) + 1
				if sim.result != "running": break
			var report := sim.summary()
			report["scenario"] = preset.name
			report["mirrored"] = mirrored
			report["event_counts"] = events_count
			report["timeout"] = sim.result == "running"
			reports.append(report)
			print("SCENARIO ", preset.name, " mirror=", mirrored, " result=", sim.result, " seconds=", snappedf(sim.time, 0.1), " support=", report.get("teamfight", {}))
	var file := FileAccess.open("res://reports/teamfight_scenarios.json", FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(reports, "\t"))
	print("TEAMFIGHT SCENARIOS: ", reports.size(), " bounded fights recorded")
	quit()
