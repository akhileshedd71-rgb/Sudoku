extends Control

var puzzle: Array[int] = []
var tint := Color("285ed7")
var font: Font = preload("res://assets/fonts/OpenSans-Regular.ttf")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var side := minf(size.x, size.y)
	var cell := side / 9.0
	var offset := (size - Vector2.ONE * side) / 2.0
	draw_rect(Rect2(offset, Vector2.ONE * side), Color.WHITE)
	for i in range(81):
		if puzzle.size() == 81 and puzzle[i] != 0:
			var font_size := maxi(6, int(cell * 0.72))
			var value := str(puzzle[i])
			var extent := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var center := offset + Vector2(i % 9 + 0.5, i / 9 + 0.5) * cell
			draw_string(font, center + Vector2(-extent.x / 2, font.get_ascent(font_size) - font.get_height(font_size) / 2), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("576c8c"))
	for i in range(10):
		var color := tint if i % 3 == 0 else Color("dce4f0")
		var weight := 1.0 if i % 3 == 0 else 0.5
		draw_line(offset + Vector2(i * cell, 0), offset + Vector2(i * cell, side), color, weight)
		draw_line(offset + Vector2(0, i * cell), offset + Vector2(side, i * cell), color, weight)
