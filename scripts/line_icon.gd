class_name LineIcon
extends Control

var kind := "grid"
var color := Color("798aa5")
var stroke := 1.8

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var scale_factor := minf(size.x, size.y) / 28.0
	draw_set_transform((size - Vector2.ONE * 28.0 * scale_factor) / 2.0, 0, Vector2.ONE * scale_factor)
	match kind:
		"grid":
			for r in range(3):
				for c in range(3):
					var box := Rect2(3 + c * 8, 3 + r * 8, 5.2, 5.2)
					draw_rect(box, color if r != 1 or c != 1 else color.lightened(0.5))
		"undo":
			draw_arc(Vector2(14, 15), 8.0, -PI * 0.68, PI * 0.9, 30, color, stroke, true)
			_line([Vector2(8, 3), Vector2(7, 9), Vector2(13, 9)])
		"erase":
			_line([Vector2(4, 17), Vector2(15, 4), Vector2(24, 12), Vector2(14, 24), Vector2(10, 24), Vector2(4, 19), Vector2(4, 17)])
			_line([Vector2(9, 12), Vector2(19, 20)])
			_line([Vector2(12, 24), Vector2(25, 24)])
		"notes":
			_line([Vector2(5, 19), Vector2(19, 4), Vector2(24, 9), Vector2(10, 24), Vector2(4, 25), Vector2(5, 19), Vector2(10, 24)])
			_line([Vector2(16, 7), Vector2(21, 12)])
			_line([Vector2(17, 24), Vector2(25, 24)])
		"hint":
			draw_arc(Vector2(14, 11), 7.5, PI * 0.72, PI * 2.28, 30, color, stroke, true)
			_line([Vector2(9, 16), Vector2(10, 20), Vector2(18, 20), Vector2(19, 16)])
			_line([Vector2(11, 24), Vector2(17, 24)])
			_line([Vector2(13, 27), Vector2(15, 27)])
		"pause":
			_line([Vector2(10, 7), Vector2(10, 21)])
			_line([Vector2(18, 7), Vector2(18, 21)])
		"play":
			draw_colored_polygon(PackedVector2Array([Vector2(9, 5), Vector2(22, 14), Vector2(9, 23)]), color)
		"settings":
			draw_arc(Vector2(14, 14), 7.5, 0, TAU, 32, color, stroke, true)
			draw_arc(Vector2(14, 14), 2.5, 0, TAU, 20, color, stroke, true)
			for i in range(8):
				var direction := Vector2.from_angle(i * TAU / 8)
				draw_line(Vector2(14, 14) + direction * 8.0, Vector2(14, 14) + direction * 11.0, color, stroke + 0.4, true)
		"close":
			_line([Vector2(7, 7), Vector2(21, 21)])
			_line([Vector2(21, 7), Vector2(7, 21)])
		"chevron":
			_line([Vector2(8, 11), Vector2(14, 17), Vector2(20, 11)])
		"arrow":
			_line([Vector2(5, 14), Vector2(23, 14), Vector2(17, 8)])
			_line([Vector2(23, 14), Vector2(17, 20)])
		"calendar":
			_line([Vector2(5, 6), Vector2(23, 6), Vector2(23, 24), Vector2(5, 24), Vector2(5, 6)])
			_line([Vector2(5, 11), Vector2(23, 11)])
			_line([Vector2(10, 3), Vector2(10, 8)])
			_line([Vector2(18, 3), Vector2(18, 8)])
			for p in [Vector2(10, 16), Vector2(17, 16), Vector2(10, 20)]:
				draw_circle(p, 1, color)
		"check":
			_line([Vector2(5, 14), Vector2(11, 20), Vector2(23, 7)])
		"trophy":
			_line([Vector2(8, 4), Vector2(20, 4), Vector2(19, 14), Vector2(14, 18), Vector2(9, 14), Vector2(8, 4)])
			_line([Vector2(7, 7), Vector2(3, 7), Vector2(4, 12), Vector2(9, 15)])
			_line([Vector2(21, 7), Vector2(25, 7), Vector2(24, 12), Vector2(19, 15)])
			_line([Vector2(14, 18), Vector2(14, 24)])
			_line([Vector2(9, 25), Vector2(19, 25)])
		"sun":
			draw_arc(Vector2(14, 14), 5, 0, TAU, 24, color, stroke, true)
			for i in range(8):
				var direction := Vector2.from_angle(i * TAU / 8)
				draw_line(Vector2(14, 14) + direction * 9, Vector2(14, 14) + direction * 12, color, stroke, true)
		"moon":
			draw_arc(Vector2(14, 14), 10, 0, TAU, 40, color, stroke, true)
			draw_arc(Vector2(18, 10), 8, PI * 0.5, PI * 1.5, 30, color, stroke, true)

func _line(points: Array[Vector2]) -> void:
	draw_polyline(PackedVector2Array(points), color, stroke, true)
