extends RefCounted
## Shared atlas regions for combat, draft and menus. Presentation only.
const Catalog = preload("res://scripts/data/catalog.gd")
const DISPLAY_FONT = preload("res://assets/cartoon/LilitaOne-Regular.ttf")
static var textures: Dictionary = {}
static var sheets: Dictionary = {}
static var regions: Dictionary = {}

static func texture(id: String, pose: int = 0) -> AtlasTexture:
	var key := "%s:%d" % [id, pose]
	if textures.has(key): return textures[key]
	var sheet := "lvl1"
	var columns := 4
	var index := Catalog.ids().find(id)
	var posed := ["hippo", "monkey", "eagle", "eagle_hippo"]
	if id in posed and pose >= 0:
		sheet = "poses"
		index = posed.find(id) * 4 + clampi(pose, 0, 3)
	elif index < 0:
		sheet = "lvl2"
		index = Catalog.hybrid_ids().find(id)
		if index < 0:
			sheet = "lvl3"
			index = Catalog.lvl3_ids().find(id)
	assert(index >= 0, "Missing cartoon art: " + id)
	if not sheets.has(sheet): sheets[sheet] = load("res://assets/cartoon/%s.png" % sheet)
	var source: Texture2D = sheets[sheet]
	if regions.is_empty():
		regions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/cartoon/regions.json"))
	var bounds: Array = regions[sheet][index]
	var result := AtlasTexture.new()
	result.atlas = source
	result.region = Rect2(float(bounds[0]),float(bounds[1]),float(bounds[2]),float(bounds[3]))
	result.filter_clip = true
	textures[key] = result
	return result

static func portrait(id: String, height: float = 90.0) -> TextureRect:
	var view := TextureRect.new()
	view.texture = texture(id, -1)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.custom_minimum_size = Vector2(height, height)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view

static func panel(fill: Color, border: Color = Color("142f33")) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(12)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	box.shadow_color = Color(0.02,0.06,0.07,0.30)
	box.shadow_size = 3
	box.shadow_offset = Vector2(0,3)
	return box

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 15
	result.set_font("font", "Button", DISPLAY_FONT)
	result.set_font_size("font_size", "Button", 17)
	for type in ["Button", "OptionButton"]:
		result.set_stylebox("normal", type, panel(Color("245861")))
		result.set_stylebox("hover", type, panel(Color("367784"), Color("ffdb8a")))
		result.set_stylebox("pressed", type, panel(Color("b96932"), Color("ffdb8a")))
		result.set_stylebox("disabled", type, panel(Color("293e40")))
		result.set_stylebox("focus", type, panel(Color(0,0,0,0), Color("ffdb8a")))
		result.set_color("font_color", type, Color("fff1d4"))
		result.set_color("font_hover_color", type, Color.WHITE)
		result.set_color("font_pressed_color", type, Color("fff1d4"))
		result.set_color("font_disabled_color", type, Color("829695"))
	result.set_stylebox("panel", "PanelContainer", panel(Color("21474b")))
	result.set_stylebox("panel", "PopupMenu", panel(Color("21474b")))
	return result
