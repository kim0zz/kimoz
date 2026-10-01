extends "res://tests/monkey_rabbit_balance.gd"
func run() -> void:
	definitions=Variants.definitions("B")
	var peers: Array[String]=Catalog.hybrid_ids()
	for id in Catalog.ids()+peers:
		for layout in range(12):
			var roster: Array=[peers[(layout+1)%12],peers[(layout+5)%12]]
			var enemies: Array=[peers[(layout*5+2)%12],peers[(layout*5+6)%12],peers[(layout*5+9)%12]]
			var slot: int=0 if layout%2==0 else 2
			roster.insert(slot,id)
			for mirror in range(2): trial("peer_diverse",id,roster,enemies,slot,layout,mirror,"live")
	var f := FileAccess.open("res://reports/monkey_rabbit_diverse.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(records))
	print("DIVERSE COMPLETE ",records.size())
	quit()
