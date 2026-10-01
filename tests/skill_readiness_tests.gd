extends SceneTree
const Readiness = preload("res://scripts/presentation/skill_readiness.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
var failures: Array[String] = []
func _initialize() -> void:
	var definitions: Dictionary = Catalog.load_units()
	var unit := {"definition":definitions.eagle_hippo,"cooldowns":{"eagle_hippo_dive":120},"skills_used":{},"action":{}}
	_check(is_zero_approx(Readiness.rows(unit,0)[0].progress),"Initial lock starts empty")
	_check(is_equal_approx(Readiness.rows(unit,1)[0].progress,0.5),"Initial two-second lock is half full after one second")
	_check(Readiness.rows(unit,2)[0].ready,"Initial readiness at two seconds")
	unit.cooldowns.eagle_hippo_dive = 300
	_check(is_equal_approx(Readiness.rows(unit,2.5)[0].progress,0.5),"Individual five-second opening is half full after 2.5 seconds")
	unit.skills_used.eagle_hippo_dive = 1
	unit.cooldowns.eagle_hippo_dive = 840
	unit.action = {"skill":definitions.eagle_hippo.skills[0]}
	_check(Readiness.rows(unit,2)[0].casting and is_zero_approx(Readiness.rows(unit,2)[0].progress),"Cast resets recurring bar from start of skill")
	unit.action = {}
	_check(is_equal_approx(Readiness.rows(unit,8)[0].progress,0.5),"Twelve-second cooldown halfway at eight seconds")
	_check(Readiness.rows(unit,14)[0].ready,"Repeat ready at fourteen seconds")
	_check(is_equal_approx(Readiness.rows(unit,99)[0].progress,1.0),"Ready bar stays full while awaiting conditions")
	unit.definition = definitions.hedgehog
	_check(Readiness.rows(unit,0)[0].passive,"Passive thorns never masquerade as charging skill")
	unit.definition = definitions.skunk_rabbit
	unit.cooldowns = {"skunk_rabbit_cloud":600,"skunk_rabbit_dash":120}
	unit.skills_used = {"skunk_rabbit_cloud":1}
	var rows: Array[Dictionary] = Readiness.rows(unit,4)
	_check(rows.size()==2 and not rows[0].ready and rows[1].ready,"Independent cloud and reactive dodge readiness")
	for failure in failures: push_error(failure)
	print("SKILL_READINESS: 10 checks, %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
func _check(ok: bool, reason: String) -> void:
	if not ok: failures.append(reason)
