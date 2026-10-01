extends SceneTree
const Sim=preload("res://scripts/combat/combat_simulation.gd")
const Catalog=preload("res://scripts/data/catalog.gd")
const Variants=preload("res://scripts/data/combat_variants.gd")
var definitions: Dictionary
var records: Array=[]
var contexts := [
	{"name":"front_vs_brawl","allies":["bear","hippo"],"enemies":["bear","cheetah","hippo"]},
	{"name":"protected_vs_dive","allies":["bear","hedgehog"],"enemies":["eagle","cheetah","monkey"]},
	{"name":"pressure_vs_ranged","allies":["eagle","hippo"],"enemies":["hippo","monkey","skunk"]},
	{"name":"six_mixed","allies":["bear","hippo","hedgehog","eagle","skunk"],"enemies":["bear","hippo","cheetah","eagle","monkey","skunk"]}
]
var focus: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	definitions=Variants.definitions("B")
	for id: String in definitions:
		var traits: Array[String]=Catalog.base_traits(id)
		if "monkey" in traits or "rabbit" in traits: focus.append(id)
	# Full lvl1 controls, focal lvl2/3 vs every peer of same level.
	for id: String in definitions:
		if definitions[id].level>1 and id not in focus: continue
		for opponent: String in definitions:
			if definitions[id].level!=definitions[opponent].level: continue
			for layout in range(2):
				for mirror in range(2): trial("duel",id,[id],[opponent],0,layout,mirror,"live")
	# Every unit in the same team slot: team utility is not equated with duels.
	for id: String in definitions:
		for context: Dictionary in contexts:
			for slot in [0,2]:
				var roster: Array=context.allies.duplicate()
				roster.insert(slot,id)
				for mirror in range(2): trial(context.name,id,roster,context.enemies,slot,0,mirror,"live")
	# Cross-tier: monkey/rabbit descendants vs base units and vs BOTH parents.
	for id in focus:
		if definitions[id].level==1: continue
		var opponents: Array=[]
		for parent in definitions[id].parents: opponents.append([parent])
		opponents.append(Array(definitions[id].parents))
		if definitions[id].level==2:
			for base in Catalog.ids(): opponents.append([base])
		for opponent in opponents:
			for mirror in range(2): trial("upgrade",id,[id],opponent,0,0,mirror,"live")
	# Paired counterfactuals: same stats, allies, enemy and positions; only focal dash removed.
	for id in focus:
		var dash := false
		for skill: Resource in definitions[id].skills:
			if skill.behavior=="dash": dash=true
		if not dash: continue
		for mode in ["no_dash","no_interrupt"]:
			for context: Dictionary in contexts:
				for slot in [0,2]:
					var roster: Array=context.allies.duplicate()
					roster.insert(slot,id)
					for mirror in range(2): trial(context.name,id,roster,context.enemies,slot,0,mirror,mode)
	var f := FileAccess.open("res://reports/monkey_rabbit_balance.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"variant":"B","date":"2026-09-27","focus":focus,"limit_seconds":90,"records":records}))
	print("BALANCE COMPLETE: ",records.size())
	quit()

func trial(family: String,id: String,a: Array,b: Array,slot: int,layout: int,mirror: int,mode: String) -> void:
	var sim=Sim.new()
	var options := {"definitions":definitions}
	var roster: Array=a.duplicate()
	var focus_id := id
	if mode!="live":
		# Alias keeps the opponent's identical species unchanged.
		var clone: Resource=definitions[id].duplicate(true)
		clone.id=id
		clone.skills.clear()
		for skill: Resource in definitions[id].skills:
			if mode=="no_dash" and skill.behavior=="dash": continue
			var copy: Resource=skill.duplicate(true)
			if mode=="no_interrupt" and copy.behavior=="dash": copy.interrupt_on_hit=false
			clone.skills.append(copy)
		focus_id=id+"_probe"
		roster[slot]=focus_id
		options.definitions=definitions.duplicate()
		options.definitions[focus_id]=clone
	var left: Array=roster if mirror==0 else b
	var right: Array=b if mirror==0 else roster
	if family=="duel":
		options.positions=[Vector2(300,250),Vector2(820,250)] if layout==0 else [Vector2(440,180),Vector2(680,320)]
	assert(sim.setup(left,right,11+layout,options))
	var uid: int=slot if mirror==0 else b.size()+slot
	var states := {}
	var basic_hits := 0
	var dash_cancellations := 0
	var pending_hits_lost := 0
	var aggro_breaks := 0
	var starts := {}
	var first_damage := -1.0
	while sim.result=="running" and sim.time<90:
		var u: Dictionary=sim.units[uid]
		var before: Dictionary=u.action.duplicate()
		if u.alive: states[u.state]=float(states.get(u.state,0.0))+Sim.DT
		sim.step()
		for e: Dictionary in sim.events:
			if int(e.get("source",-1))!=uid: continue
			if e.kind=="skill_start":
				starts[e.skill]=int(starts.get(e.skill,0))+1
				if e.behavior=="dash" and not before.is_empty() and before.get("skill")!=null and before.skill.behavior!="dash" and int(before.get("remaining",0))>0:
					dash_cancellations+=1
					pending_hits_lost+=int(before.remaining)
			if e.kind=="aggro_break": aggro_breaks+=1
			if e.kind=="damage" and float(e.get("amount",0))>0:
				if first_damage<0: first_damage=sim.time
				if e.damage_kind=="basic": basic_hits+=1
	var summary: Dictionary=sim.summary()
	var focal: Dictionary=summary.units[uid]
	# Translate alias back for readable aggregate output only.
	focal.id=id
	var team_damage := 0.0
	var survivors := 0
	for row in summary.units:
		if int(row.team)==mirror:
			team_damage+=float(row.damage_dealt)
			if row.survived: survivors+=1
	var outcome := "stall" if sim.result=="running" else "draw" if sim.result=="draw" else "win" if sim.result==("A" if mirror==0 else "B") else "loss"
	records.append({"family":family,"id":id,"level":definitions[id].level,"a":a,"b":b,"slot":slot,"layout":layout,"mirror":mirror,"mode":mode,"outcome":outcome,"duration":sim.time,"focal":focal,"team_damage":team_damage,"team_survivors":survivors,"states":states,"basic_hits":basic_hits,"dash_cancellations":dash_cancellations,"pending_hits_lost":pending_hits_lost,"aggro_break_events":aggro_breaks,"first_damage":first_damage})
	if records.size()%100==0: print("BALANCE ",records.size())
