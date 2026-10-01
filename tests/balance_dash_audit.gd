extends SceneTree
const Probe=preload("res://tests/balance_probe_simulation.gd")
const Variants=preload("res://scripts/data/combat_variants.gd")
const CONTEXTS = [
	{"name":"front_vs_brawl","allies":["bear","hippo"],"enemies":["bear","cheetah","hippo"]},
	{"name":"protected_vs_dive","allies":["bear","hedgehog"],"enemies":["eagle","cheetah","monkey"]},
	{"name":"pressure_vs_ranged","allies":["eagle","hippo"],"enemies":["hippo","monkey","skunk"]},
	{"name":"six_mixed","allies":["bear","hippo","hedgehog","eagle","skunk"],"enemies":["bear","hippo","cheetah","eagle","monkey","skunk"]}
]

var records: Array=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var defs: Dictionary=Variants.definitions("B")
	for id: String in defs:
		var has_dash := false
		for skill: Resource in defs[id].skills:
			if skill.behavior=="dash": has_dash=true
		if not has_dash: continue
		for context: Dictionary in CONTEXTS:
			for slot in [0,2]:
				var roster: Array=context.allies.duplicate()
				roster.insert(slot,id)
				var sim=Probe.new()
				assert(sim.setup(roster,context.enemies,11,{"definitions":defs}))
				while sim.result=="running" and sim.time<90: sim.step()
				records.append({"id":id,"family":context.name,"slot":slot,"audit":sim.audit.get(slot,{}),"summary":sim.summary().units[slot]})
	var file := FileAccess.open("res://reports/monkey_rabbit_dash_audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(records))
	print("DASH AUDIT COMPLETE ",records.size())
	quit()
