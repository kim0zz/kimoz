extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	var demo := CanvasLayer.new()
	demo.set_script(load("res://scripts/presentation/hippo_showcase.gd"))
	root.add_child(demo)
