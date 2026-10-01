extends SceneTree
## Optional visual contact sheet: godot --path . --script ... -- --output=absolute.png
const Catalog = preload("res://scripts/data/catalog.gd")
const View = preload("res://scenes/units/unit_view.tscn")
var frames := 0
var output := "user://zoo_roster.png"
func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	var back := ColorRect.new()
	back.color = Color("d0d5af")
	back.size = Vector2(1280,720)
	root.add_child(back)
	var index := 0
	var definitions := Catalog.load_units()
	for id in Catalog.ids():
		var node := View.instantiate()
		root.add_child(node)
		node.scale = Vector2(2.1,2.1)
		node.refresh({"uid": index,"id":id,"definition":definitions[id],"team":index%2,"pos":Vector2(180+(index%4)*290,200+(index/4)*300),"hp":definitions[id].max_hp,"alive":true,"state":"idle","flash":0.0},0.0)
		index += 1
func _process(_delta: float) -> bool:
	frames += 1
	if frames == 8:
		root.get_texture().get_image().save_png(output)
		print("ROSTER_CAPTURE ",output)
		quit()
	return false
