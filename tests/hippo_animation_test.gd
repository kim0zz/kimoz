extends SceneTree
const Rig = preload("res://scenes/units/hippo_rig.tscn")
var demo: CanvasLayer
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://hippo_"+label+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	demo=CanvasLayer.new()
	demo.set_script(load("res://scripts/presentation/hippo_showcase.gd"))
	root.add_child(demo)
	demo.set_process(false)
	for mode in ["Spoczynek","Chód","Ciężki cios","Oberwanie","Ogłuszenie","Porażka"]:
		demo.set_mode(mode)
		for tick in range(110):
			demo._process(1.0/60.0)
			if tick in [28,54,62,100]: await capture(mode.replace(" ","_")+str(tick))
	# Parts must move relative to each other, not just rotate the entire image.
	demo.set_mode("Chód")
	demo._process(0.0167)
	var leg_a: float=demo.rig.pieces.front.rotation
	var body_a: float=demo.rig.torso.rotation
	for tick in range(15): demo._process(1.0/60.0)
	assert(absf(demo.rig.pieces.front.rotation-leg_a)>0.03)
	assert(absf(demo.rig.pieces.front.rotation-demo.rig.torso.rotation)>0.03)
	# Paused simulation samples cannot advance the pose.
	var frozen: Vector2=demo.rig.head.position
	demo.rig.sample(demo.unit,demo.time)
	assert(demo.rig.head.position.is_equal_approx(frozen))
	# A full missed swing must never emit a contact sound.
	demo.set_mode("Pudło")
	var impacts_before: int = int(demo.audio.played.get("impact",0))
	for tick in range(120): demo._process(1.0/60.0)
	assert(int(demo.audio.played.get("impact",0)) == impacts_before)
	demo.rig.source_event({"kind":"damage","damage_kind":"skill","amount":0},demo.time)
	assert(int(demo.audio.played.get("impact",0)) == impacts_before)
	demo.pause=true
	demo._process(0.1)
	assert(not demo.audio.active)
	for player in demo.audio.players: assert(not player.playing or player.stream_paused)
	demo.queue_free()
	await process_frame
	var combat: Node=load("res://scenes/combat/combat_prototype.tscn").instantiate()
	root.add_child(combat)
	combat.set_physics_process(false)
	for team in range(2):
		for selector: OptionButton in combat.selectors[team]: selector.select(0)
	combat.selectors[0][0].select(combat.ids.find("hippo")+1)
	combat.selectors[1][0].select(combat.ids.find("bear")+1)
	combat._reset()
	combat.running=true
	var seen_hit:=false
	for tick in range(650):
		combat._physics_process(1.0/60.0)
		for event: Dictionary in combat.sim.events:
			if event.kind=="damage" and event.source==0 and event.damage_kind=="skill":
				assert(is_equal_approx(combat.views[0].hippo_rig.strike_at,combat.sim.time))
				assert(int(combat.effects_view.hippo_audio.played.get("impact",0)) == 1)
				assert(combat.effects_view.hippo_contact.hits.size() == 1)
				seen_hit=true
				await capture("combat_impact")
		if seen_hit: break
	assert(seen_hit,"Heavy animation must receive real combat damage")
	print("HIPPO PASS: articulated gait, pause, states, real heavy hit synchronization")
	quit()

