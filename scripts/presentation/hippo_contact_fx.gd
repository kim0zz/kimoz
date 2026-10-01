extends Node2D
## Tight directional contact, never an area-of-effect shockwave.
var hits: Array[Dictionary] = []
var clock := 0.0

func impact(point: Vector2, direction: Vector2, at: float) -> void:
	hits.append({"pos":point,"dir":direction.normalized(),"at":at})
	clock=at
	queue_redraw()

func advance(at: float) -> void:
	clock=at
	hits=hits.filter(func(hit: Dictionary) -> bool: return at-float(hit.at)<0.38)
	queue_redraw()

func _draw() -> void:
	for hit: Dictionary in hits:
		var age := clock-float(hit.at)
		var p := clampf(age/0.38,0,1)
		var origin: Vector2=hit.pos
		var direction: Vector2=hit.dir
		var angle := direction.angle()
		if age<0.11:
			var points := PackedVector2Array()
			for i in range(16):
				var r := (20.0 if i%2==0 else 7.0)*(1.0-p*1.5)
				points.append(origin+Vector2.from_angle(angle+TAU*i/16.0)*r)
			draw_colored_polygon(points,Color(1,0.88,0.49,1-p))
			draw_circle(origin,5.0*(1-p),Color("fff9dd"))
		for i in range(7):
			var ray := Vector2.from_angle(angle-1.25+i*0.42)
			var start := origin+ray*(10+p*20)
			draw_line(start,start+ray*(8*(1-p)),Color(1,0.72,0.23,1-p),2.5*(1-p)+0.5,true)
