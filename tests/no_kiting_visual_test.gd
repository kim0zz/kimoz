extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	var combat: Node=load("res://scenes/combat/combat_prototype.tscn").instantiate()
	root.add_child(combat)
	combat.set_physics_process(false)
	for team in range(2):
		for selector: OptionButton in combat.selectors[team]: selector.select(0)
	combat.selectors[0][0].select(combat.ids.find("monkey")+1)
	combat.selectors[1][0].select(combat.ids.find("bear")+1)
	combat._reset()
	combat.running=true
	for i in range(420): combat._physics_process(1.0/60.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/no_kiting_combat.png")
	assert(combat.sim.units[0].damage_dealt>0 and combat.sim.units[1].damage_dealt>0)
	print("NO KITING RENDER PASS: live combat exchange")
	quit()
