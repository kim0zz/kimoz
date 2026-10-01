extends "res://scripts/combat/combat_simulation.gd"
## Diagnostic-only subclass. Overrides observe calls and forward unchanged mechanics.
var audit: Dictionary={}
func _metric(uid: int,key: String,value: float=1.0) -> void:
	if not audit.has(uid): audit[uid]={}
	audit[uid][key]=float(audit[uid].get(key,0.0))+value
func _start_skill(u: Dictionary,s: Resource) -> void:
	if s.behavior=="dash":
		_metric(u.uid,"dash_starts")
		if not u.action.is_empty() and u.action.get("skill")!=null and u.action.skill.behavior!="dash" and int(u.action.get("remaining",0))>0:
			_metric(u.uid,"actual_self_interrupts")
			_metric(u.uid,"actual_pending_hits_cancelled",int(u.action.remaining))
	super._start_skill(u,s)
func _break_aggro(u: Dictionary,duration: float) -> void:
	var old: Dictionary={}
	for enemy in _enemies(u):
		old[enemy.uid]={"target":enemy.target,"action":enemy.action.duplicate()}
	super._break_aggro(u,duration)
	for uid in old:
		var enemy: Dictionary=units[uid]
		if old[uid].target==u.uid and enemy.target!=u.uid: _metric(u.uid,"enemy_retargets")
		if not old[uid].action.is_empty() and enemy.action.is_empty(): _metric(u.uid,"enemy_actions_cancelled")
func _emit(event: Dictionary) -> void:
	if event.kind=="miss": _metric(int(event.get("source",-1)),"miss_events")
	super._emit(event)
