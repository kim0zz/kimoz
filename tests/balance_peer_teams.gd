extends "res://tests/monkey_rabbit_balance.gd"
func run() -> void:
	definitions=Variants.definitions("B")
	for id: String in definitions:
		var level: int=definitions[id].level
		if level<2: continue
		var peers: Array=[
			{"name":"peer_brawl","allies":["bear_hedgehog","monkey_hippo"],"enemies":["bear_cheetah","eagle_hippo","monkey_skunk"]},
			{"name":"peer_dive","allies":["eagle_hippo","hedgehog_skunk"],"enemies":["cheetah_eagle","hippo_rabbit","monkey_hippo"]}
		] if level==2 else [
			{"name":"peer_brawl","allies":["lvl3_07","lvl3_10"],"enemies":["lvl3_02","lvl3_09","lvl3_12"]},
			{"name":"peer_dive","allies":["lvl3_06","lvl3_03"],"enemies":["lvl3_07","lvl3_11","lvl3_04"]}
		]
		for context: Dictionary in peers:
			for slot in [0,2]:
				var roster: Array=context.allies.duplicate()
				roster.insert(slot,id)
				for mirror in range(2): trial(context.name,id,roster,context.enemies,slot,0,mirror,"live")
	var f := FileAccess.open("res://reports/monkey_rabbit_peer_teams.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(records))
	print("PEER TEAMS COMPLETE ",records.size())
	quit()
