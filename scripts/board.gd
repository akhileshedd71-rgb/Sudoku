class_name SudokuBoard
extends Control

signal cell_selected(index: int)
var game: GameState
var highlight_peers := true
var show_same := true
var dark := false
var pulse := 0.0
var font: Font = preload("res://assets/fonts/OpenSans-Regular.ttf")
var note_font: Font = preload("res://assets/fonts/OpenSans-Semibold.ttf")

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if game == null or game.paused or game.completed or game.lost:
			return
		var cell_size := size.x / 9.0
		var column := clampi(int(event.position.x / cell_size), 0, 8)
		var row := clampi(int(event.position.y / cell_size), 0, 8)
		cell_selected.emit(row * 9 + column)
		accept_event()

func animate_entry() -> void:
	pulse = 1.0
	var tween := create_tween()
	tween.tween_method(func(value: float):
		pulse = value
		queue_redraw(), 1.0, 0.0, 0.22)

func _draw() -> void:
	if game == null or game.cells.size() != 81:
		return
	var cell := size.x / 9.0
	var ink := Color("dfe7f5") if dark else Color("29384f")
	var blue := Color("8cb4ff") if dark else Color("285ed7")
	var muted := Color("90a2bc") if dark else Color("8a99ae")
	var base := Color("1b273b") if dark else Color.WHITE
	var peer := Color("23344e") if dark else Color("edf3fc")
	var same := Color("30496d") if dark else Color("dce9fb")
	var active := Color("3b5b8c") if dark else Color("bfd6fc")
	draw_rect(Rect2(Vector2.ZERO, size), base)
	var selected_value := game.cells[game.selected] if game.selected >= 0 else 0
	for i in range(81):
		var area := Rect2(Vector2(i % 9, i / 9) * cell, Vector2.ONE * cell)
		var fill := base
		if game.selected >= 0 and highlight_peers and GameState.peers(i, game.selected):
			fill = peer
		if show_same and selected_value != 0 and game.cells[i] == selected_value:
			fill = same
		var wrong := game.cells[i] != 0 and game.cells[i] != game.solution[i]
		if wrong:
			fill = Color("543346") if dark else Color("fff0f1")
		if i == game.selected:
			fill = Color("764559") if wrong and dark else (Color("ffd8df") if wrong else active)
		draw_rect(area, fill)
		if game.paused:
			continue
		if game.cells[i] != 0:
			var font_size := int(cell * 0.66 + (pulse * 2.5 if i == game.selected else 0.0))
			var color := ink if game.givens[i] != 0 else blue
			if wrong:
				color = Color("ff8294") if dark else Color("d4546c")
			_text(str(game.cells[i]), area, font, font_size, color)
		elif game.notes[i] != 0:
			for n in range(9):
				if game.notes[i] & (1 << n):
					var note_area := Rect2(area.position + Vector2(n % 3, n / 3) * cell / 3.0, Vector2.ONE * cell / 3.0)
					_text(str(n + 1), note_area, note_font, int(cell * 0.245), muted)
	for i in range(10):
		var major := i % 3 == 0
		var color := (Color("7e91b0") if dark else Color("697b97")) if major else (Color("3e506b") if dark else Color("c8d4e5"))
		var width := 2.0 if major else 1.0
		var coordinate := clampf(i * cell, 1.0, size.x - 1.0)
		draw_line(Vector2(coordinate, 0), Vector2(coordinate, size.y), color, width, true)
		draw_line(Vector2(0, coordinate), Vector2(size.x, coordinate), color, width, true)
	if game.selected >= 0 and not game.paused:
		var selected_rect := Rect2(Vector2(game.selected % 9, game.selected / 9) * cell + Vector2.ONE * 1.5, Vector2.ONE * (cell - 3.0))
		draw_rect(selected_rect, blue.lightened(0.2), false, 2.0)
	if game.paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.94, 0.96, 0.99, 0.92) if not dark else Color(0.1, 0.15, 0.23, 0.94))
		_text("Take a breath.", Rect2(0, size.y / 2.0 - 40, size.x, 40), note_font, 25, ink)
		_text("Your puzzle will be right here.", Rect2(0, size.y / 2.0 + 4, size.x, 30), font, 15, muted)

func _text(value: String, area: Rect2, text_font: Font, font_size: int, color: Color) -> void:
	var text_size := text_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := area.position + Vector2((area.size.x - text_size.x) / 2.0, (area.size.y - text_font.get_height(font_size)) / 2.0 + text_font.get_ascent(font_size))
	draw_string(text_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
