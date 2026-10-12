extends Control

const State = preload("res://scripts/game_state.gd")
const Library = preload("res://scripts/puzzle_library.gd")
const Board = preload("res://scripts/board.gd")
const Icon = preload("res://scripts/line_icon.gd")
const Preview = preload("res://scripts/puzzle_preview.gd")
const REGULAR = preload("res://assets/fonts/OpenSans-Regular.ttf")
const SEMIBOLD = preload("res://assets/fonts/OpenSans-Semibold.ttf")
const BOLD = preload("res://assets/fonts/OpenSans-Bold.ttf")
const SAVE_PATH := "user://progress.json"
const DESCRIPTIONS := ["Find your rhythm", "A little more focus", "Think a step ahead", "Follow the possibilities", "Trust your logic", "Your ultimate challenge"]

var game := State.new()
var settings := {"highlight": true, "same_numbers": true, "auto_notes": true, "haptics": true, "dark": false}
var stats := {"wins": 0, "best_times": {}, "daily_dates": []}
var page: Control
var board: SudokuBoard
var background: ColorRect
var brand: Control
var tagline: Label
var mode_row: Control
var mode_label: Label
var level_button: Button
var daily_button: Button
var stats_panel: Panel
var mistakes_value: Label
var score_value: Label
var time_value: Label
var pause_button: Button
var tools_row: HBoxContainer
var notes_badge: Label
var hints_badge: Label
var undo_button: Button
var notes_button: Button
var hint_button: Button
var keypad: HBoxContainer
var number_buttons: Array[Button] = []
var number_counts: Array[Label] = []
var footer: Control
var progress_label: Label
var progress_bar: ProgressBar
var toast_label: Label
var toast_tween: Tween
var overlay: Control
var sheet: PanelContainer
var sheet_kind := ""
var tick_save := 0.0
var last_second := -1
var just_loaded := false
var initialized := false
var demo_mode := false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	demo_mode = "--demo" in OS.get_cmdline_user_args()
	if not demo_mode:
		_load_progress()
	if game.cells.is_empty():
		game.new_game("Medium", 20261012 if demo_mode else randi())
		for i in range(81):
			if game.cells[i] == 0:
				game.selected = i
				break
	_build_ui()
	resized.connect(_layout)
	initialized = true
	_layout()
	_refresh()
	if game.completed:
		call_deferred("_show_victory")
	elif game.lost:
		call_deferred("_show_loss")
	elif just_loaded:
		_toast("Welcome back. Your puzzle is saved.")
	_save_progress()

func _ink() -> Color:
	return Color("e2eaf8") if settings.dark else Color("273750")

func _muted() -> Color:
	return Color("98aac4") if settings.dark else Color("7a8aa3")

func _blue() -> Color:
	return Color("8cb4ff") if settings.dark else Color("285ed7")

func _surface() -> Color:
	return Color("1b273b") if settings.dark else Color.WHITE

func _soft() -> Color:
	return Color("283b59") if settings.dark else Color("eaf1fd")

func _style(color: Color, radius: int = 12, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(width)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _label(value: String, font_size: int, color: Color, font: Font = REGULAR) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(value: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 48
	button.add_theme_font_override("font", SEMIBOLD)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE if primary else _blue())
	button.add_theme_color_override("font_hover_color", Color.WHITE if primary else _blue())
	button.add_theme_color_override("font_pressed_color", Color.WHITE if primary else _blue())
	button.add_theme_color_override("font_disabled_color", _muted().lightened(0.15))
	button.add_theme_stylebox_override("normal", _style(Color("285ed7") if primary else _soft()))
	button.add_theme_stylebox_override("hover", _style(Color("3470ed") if primary else _soft().darkened(0.04)))
	button.add_theme_stylebox_override("pressed", _style(Color("1d4fbb") if primary else _soft().darkened(0.1)))
	button.add_theme_stylebox_override("disabled", _style(_soft()))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, 12, _blue().lightened(0.25), 2))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	return button

func _icon(kind: String, color: Color, icon_size: float = 28.0) -> Control:
	var icon := Icon.new()
	icon.kind = kind
	icon.color = color
	icon.custom_minimum_size = Vector2.ONE * icon_size
	icon.size = Vector2.ONE * icon_size
	return icon

func _icon_button(kind: String, description: String, callback: Callable) -> Button:
	var button := _button("", callback)
	button.tooltip_text = description
	button.accessibility_name = description
	button.custom_minimum_size = Vector2(44, 44)
	var icon := _icon(kind, _muted(), 24)
	button.add_child(icon)
	icon.position = Vector2(10, 10)
	return button

func _place(node: Control, x: float, y: float, width: float, height: float) -> void:
	node.position = Vector2(x, y)
	node.size = Vector2(width, height)

func _build_ui() -> void:
	background = ColorRect.new()
	background.color = Color("121d2e") if settings.dark else Color("f7f9fd")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	page = Control.new()
	add_child(page)
	brand = Control.new()
	page.add_child(brand)
	var mark := Panel.new()
	mark.add_theme_stylebox_override("panel", _style(Color("285ed7"), 11))
	_place(mark, 0, 4, 38, 38)
	brand.add_child(mark)
	var brand_icon := _icon("grid", Color.WHITE, 23)
	mark.add_child(brand_icon)
	brand_icon.position = Vector2(7.5, 7.5)
	var title := _label("sudoku", 31, _ink(), BOLD)
	_place(title, 50, -2, 180, 49)
	brand.add_child(title)
	var title_dot := _label(".", 34, _blue(), BOLD)
	_place(title_dot, 168, -4, 20, 49)
	brand.add_child(title_dot)
	var settings_button := _icon_button("settings", "Settings", _show_settings)
	settings_button.name = "Settings"
	brand.add_child(settings_button)
	settings_button.position = Vector2(388, 0)
	tagline = _label("A little focus. A lot of calm.", 15, _muted())
	page.add_child(tagline)
	mode_row = Control.new()
	page.add_child(mode_row)
	mode_label = _label("CLASSIC", 12, _blue(), BOLD)
	mode_row.add_child(mode_label)
	_place(mode_label, 0, 0, 180, 19)
	level_button = _button("Medium", _show_new_game)
	level_button.name = "Difficulty"
	level_button.custom_minimum_size.y = 28
	level_button.add_theme_font_size_override("font_size", 20)
	level_button.add_theme_color_override("font_color", _ink())
	for state in ["normal", "hover", "pressed"]:
		level_button.add_theme_stylebox_override(state, _style(Color.TRANSPARENT, 0))
	level_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	mode_row.add_child(level_button)
	_place(level_button, -12, 17, 136, 35)
	var down := _icon("chevron", _muted(), 18)
	level_button.add_child(down)
	down.position = Vector2(107, 9)
	daily_button = _button("Daily challenge", _show_daily)
	daily_button.name = "DailyChallenge"
	daily_button.add_theme_font_size_override("font_size", 13)
	daily_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	daily_button.custom_minimum_size = Vector2(164, 44)
	mode_row.add_child(daily_button)
	var calendar := _icon("calendar", _blue(), 21)
	daily_button.add_child(calendar)
	calendar.position = Vector2(10, 11)
	stats_panel = Panel.new()
	stats_panel.add_theme_stylebox_override("panel", _style(_surface(), 14, Color("24344e") if settings.dark else Color("e9eef7"), 1))
	page.add_child(stats_panel)
	mistakes_value = _stat("Mistakes", "0 / 3", 16)
	score_value = _stat("Score", "0", 143)
	time_value = _stat("Time", "00:00", 254)
	pause_button = _icon_button("pause", "Pause game", _show_pause)
	pause_button.name = "Pause"
	stats_panel.add_child(pause_button)
	board = Board.new()
	board.name = "Board"
	board.game = game
	board.cell_selected.connect(_select_cell)
	page.add_child(board)
	tools_row = HBoxContainer.new()
	tools_row.add_theme_constant_override("separation", 8)
	page.add_child(tools_row)
	undo_button = _tool_button("undo", "Undo", _undo)
	_tool_button("erase", "Erase", _erase)
	notes_button = _tool_button("notes", "Notes", _toggle_notes)
	notes_badge = _badge("OFF", notes_button, Vector2(55, 0))
	hint_button = _tool_button("hint", "Hint", _hint)
	hints_badge = _badge("3", hint_button, Vector2(59, 0))
	keypad = HBoxContainer.new()
	keypad.name = "NumberPad"
	keypad.add_theme_constant_override("separation", 5)
	page.add_child(keypad)
	for n in range(1, 10):
		var button := _button("", _enter.bind(n))
		button.name = "Number%d" % n
		button.accessibility_name = "Enter %d" % n
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 64)
		button.add_theme_stylebox_override("normal", _style(_surface(), 10, Color("2a3b55") if settings.dark else Color("e5ebf6"), 1))
		keypad.add_child(button)
		var digit := _label(str(n), 31, _blue())
		digit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		digit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		digit.offset_bottom = -16
		button.add_child(digit)
		var count := _label("9", 10, _muted(), SEMIBOLD)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		count.offset_top = -20
		count.offset_bottom = -4
		button.add_child(count)
		number_buttons.append(button)
		number_counts.append(count)
	footer = Control.new()
	page.add_child(footer)
	progress_label = _label("", 12, _muted())
	footer.add_child(progress_label)
	_place(progress_label, 0, 1, 240, 24)
	progress_bar = ProgressBar.new()
	progress_bar.show_percentage = false
	progress_bar.max_value = 81
	var track_style := _style(_soft(), 2)
	var fill_style := _style(_blue().lightened(0.15), 2)
	for style in [track_style, fill_style]:
		style.content_margin_top = 0
		style.content_margin_bottom = 0
	progress_bar.add_theme_stylebox_override("background", track_style)
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	footer.add_child(progress_bar)
	_place(progress_bar, 0, 31, 112, 3)
	var new_button := _button("New game  +", _show_new_game)
	new_button.name = "NewGame"
	new_button.custom_minimum_size.y = 44
	new_button.add_theme_font_size_override("font_size", 14)
	footer.add_child(new_button)
	toast_label = _label("", 14, Color.WHITE, SEMIBOLD)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_stylebox_override("normal", _style(Color("273750"), 14))
	toast_label.modulate.a = 0
	add_child(toast_label)

func _stat(title: String, value: String, x: float) -> Label:
	var heading := _label(title, 11, _muted(), SEMIBOLD)
	stats_panel.add_child(heading)
	_place(heading, x, 8, 90, 16)
	var label := _label(value, 18, _ink(), SEMIBOLD)
	stats_panel.add_child(label)
	_place(label, x, 25, 96, 25)
	return label

func _tool_button(icon_name: String, title: String, callback: Callable) -> Button:
	var button := _button("", callback)
	button.name = title
	button.accessibility_name = title
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 74)
	for state in ["normal", "disabled"]:
		button.add_theme_stylebox_override(state, _style(Color.TRANSPARENT))
	var icon := _icon(icon_name, _muted(), 29)
	button.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	icon.offset_left = -14.5
	icon.offset_right = 14.5
	icon.offset_top = 9
	icon.offset_bottom = 38
	var label := _label(title, 13, _muted(), SEMIBOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -29
	label.offset_bottom = -5
	tools_row.add_child(button)
	return button

func _badge(value: String, parent: Control, pos: Vector2) -> Label:
	var badge := _label(value, 9, Color.WHITE, BOLD)
	badge.add_theme_stylebox_override("normal", _badge_style(Color("285ed7")))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(badge)
	_place(badge, pos.x, pos.y, 28, 20)
	return badge

func _badge_style(color: Color) -> StyleBoxFlat:
	var style := _style(color, 9)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

func _layout() -> void:
	if page == null:
		return
	var safe_top := 0.0
	var safe_bottom := 0.0
	if OS.has_feature("android"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		if screen.y > 0 and safe.size.y > 0:
			safe_top = safe.position.y * size.y / screen.y
			safe_bottom = (screen.y - safe.end.y) * size.y / screen.y
	var width := minf(size.x, 520.0)
	var height := size.y - safe_top - safe_bottom
	_place(page, (size.x - width) / 2.0, safe_top, width, height)
	var margin := 24.0
	var inside := width - margin * 2
	var roomy := clampf((height - 853.0) / 107.0, 0, 1)
	var top := lerpf(16, 28, roomy)
	_place(brand, margin, top, inside, 48)
	brand.get_node("Settings").position = Vector2(inside - 44, 0)
	_place(tagline, margin, top + 51, inside, 26)
	_place(mode_row, margin, lerpf(104, 124, roomy), inside, 52)
	daily_button.position = Vector2(inside - 164, 4)
	_place(stats_panel, margin, lerpf(166, 190, roomy), inside, 60)
	pause_button.position = Vector2(inside - 54, 8)
	var board_top := lerpf(240, 266, roomy)
	var board_size := minf(inside, height - board_top - 244)
	_place(board, (width - board_size) / 2.0, board_top, board_size, board_size)
	var board_bottom := board_top + board_size
	_place(tools_row, margin, board_bottom + 12, inside, 74)
	_place(keypad, margin, board_bottom + 100, inside, 64)
	_place(footer, margin, board_bottom + 181, inside, 44)
	_place(footer.get_node("NewGame"), inside - 138, 0, 138, 44)
	_place(toast_label, page.position.x + margin, safe_top + board_top + board_size * 0.72, inside, 42)
	if is_instance_valid(overlay):
		_layout_sheet()

func _refresh() -> void:
	if board == null:
		return
	board.highlight_peers = bool(settings.highlight)
	board.show_same = bool(settings.same_numbers)
	board.dark = bool(settings.dark)
	board.queue_redraw()
	level_button.text = game.level
	mode_label.text = "DAILY · " + _date_title(game.daily_date).to_upper() if not game.daily_date.is_empty() else "CLASSIC SUDOKU"
	mistakes_value.text = "%d / 3" % game.mistakes
	mistakes_value.add_theme_color_override("font_color", Color("d4546c") if game.mistakes > 0 else _ink())
	score_value.text = str(game.score)
	time_value.text = _time_string(game.elapsed)
	notes_badge.text = "ON" if game.note_mode else "OFF"
	notes_badge.add_theme_stylebox_override("normal", _badge_style(Color("285ed7") if game.note_mode else Color("a3b0c5")))
	hints_badge.text = str(game.hints)
	notes_button.add_theme_stylebox_override("normal", _style(_soft() if game.note_mode else Color.TRANSPARENT))
	undo_button.modulate.a = 1.0 if not game.history.is_empty() else 0.4
	hint_button.modulate.a = 1.0 if game.hints > 0 else 0.4
	for n in range(1, 10):
		var count := game.remaining(n)
		number_counts[n - 1].text = str(count) + " left" if count > 0 else "done"
		number_buttons[n - 1].modulate.a = 0.35 if count == 0 else 1.0
		number_buttons[n - 1].disabled = count == 0 or game.completed or game.lost
	progress_label.text = "%d of 81 · one step at a time" % game.filled_count()
	progress_bar.value = game.filled_count()

func _select_cell(index: int) -> void:
	game.selected = index
	_haptic()
	_refresh()

func _enter(number: int) -> void:
	if is_instance_valid(overlay):
		return
	if game.selected < 0:
		_toast("Choose an empty cell first")
		return
	if game.givens[game.selected] != 0:
		_toast("That number is a clue. Choose an empty cell.")
		return
	var result := game.enter(number, settings.auto_notes)
	if result == "mistake":
		_haptic(65)
		_toast("Not quite. Try another possibility.")
	elif result != "ignored":
		_haptic()
		board.animate_entry()
	_refresh()
	_save_progress()
	if game.lost:
		_show_loss()
	elif game.completed:
		_show_victory()

func _undo() -> void:
	if game.undo():
		_haptic()
		_refresh()
		_save_progress()
	else:
		_toast("No moves to undo yet")

func _erase() -> void:
	if game.erase():
		_haptic()
		_refresh()
		_save_progress()
	else:
		_toast("Select a number or note to erase")

func _toggle_notes() -> void:
	if game.completed or game.lost:
		return
	game.note_mode = not game.note_mode
	_haptic()
	_refresh()
	_save_progress()
	_toast("Notes on · pencil in the possibilities" if game.note_mode else "Notes off · enter your answer")

func _hint() -> void:
	if game.hints <= 0:
		_toast("You've used all 3 hints for this puzzle")
		return
	var content := _open_sheet("hint", "A little nudge?", "Reveal the correct number in the selected cell.\nYou have %d hints remaining." % game.hints, "hint")
	_sheet_button(content, "Reveal a number", func():
		_close_sheet()
		var target := game.hint(settings.auto_notes)
		if target >= 0:
			_haptic()
			board.animate_entry()
			_toast("%d belongs here · row %d, column %d" % [game.solution[target], target / 9 + 1, target % 9 + 1])
		_refresh()
		_save_progress()
		if game.completed:
			_show_victory(), true)
	_sheet_button(content, "Keep thinking", _close_sheet)

func _haptic(duration: int = 16) -> void:
	if settings.haptics and OS.has_feature("android"):
		Input.vibrate_handheld(duration)

func _process(delta: float) -> void:
	if not initialized:
		return
	if not game.paused and not game.completed and not game.lost:
		game.elapsed += delta
		if int(game.elapsed) != last_second:
			last_second = int(game.elapsed)
			time_value.text = _time_string(game.elapsed)
			tick_save += 1
			if tick_save >= 5:
				tick_save = 0
				_save_progress()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
		if is_instance_valid(overlay):
			_close_sheet()
		else:
			_show_pause()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(overlay):
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_9:
		_enter(event.keycode - KEY_0)
	elif event.keycode >= KEY_KP_1 and event.keycode <= KEY_KP_9:
		_enter(event.keycode - KEY_KP_0)
	elif event.keycode in [KEY_DELETE, KEY_BACKSPACE]:
		_erase()
	elif event.keycode == KEY_N:
		_toggle_notes()
	elif event.keycode == KEY_H:
		_hint()
	elif event.keycode == KEY_Z and (event.ctrl_pressed or event.meta_pressed):
		_undo()
	elif event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		var next := maxi(0, game.selected)
		match event.keycode:
			KEY_LEFT: next = (next / 9) * 9 + (next % 9 + 8) % 9
			KEY_RIGHT: next = (next / 9) * 9 + (next % 9 + 1) % 9
			KEY_UP: next = (next + 72) % 81
			KEY_DOWN: next = (next + 9) % 81
		_select_cell(next)
	else:
		return
	get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if not initialized:
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_progress()
		get_tree().quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(overlay):
			_close_sheet()
		else:
			_show_pause()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if not is_instance_valid(overlay) and not game.completed and not game.lost:
			_show_pause()
		_save_progress()

func _open_sheet(kind: String, title: String, subtitle: String, icon_name: String = "") -> VBoxContainer:
	_close_sheet()
	game.paused = true
	sheet_kind = kind
	_refresh()
	overlay = Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var shade := Button.new()
	shade.name = "Shade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_theme_stylebox_override("normal", _style(Color(0.08, 0.13, 0.23, 0.42), 0))
	shade.add_theme_stylebox_override("hover", _style(Color(0.08, 0.13, 0.23, 0.42), 0))
	shade.add_theme_stylebox_override("pressed", _style(Color(0.08, 0.13, 0.23, 0.42), 0))
	shade.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	shade.pressed.connect(_close_sheet)
	overlay.add_child(shade)
	sheet = PanelContainer.new()
	sheet.name = "Sheet"
	sheet.add_theme_stylebox_override("panel", _style(_surface(), 24))
	overlay.add_child(sheet)
	var margins := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, 12)
	sheet.add_child(margins)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margins.add_child(content)
	var close_row := HBoxContainer.new()
	content.add_child(close_row)
	if not icon_name.is_empty():
		var hero := _icon(icon_name, _blue(), 34)
		close_row.add_child(hero)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_row.add_child(space)
	var close := _icon_button("close", "Close", _close_sheet)
	close.name = "Close"
	close_row.add_child(close)
	var heading := _label(title, 26, _ink(), BOLD)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(heading)
	if not subtitle.is_empty():
		var description := _label(subtitle, 14, _muted())
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(description)
	call_deferred("_layout_sheet")
	overlay.modulate.a = 0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.14)
	return content

func _sheet_button(content: VBoxContainer, text: String, action: Callable, primary: bool = false) -> Button:
	var button := _button(text, action, primary)
	button.name = text.to_pascal_case()
	button.custom_minimum_size.y = 50
	content.add_child(button)
	return button

func _layout_sheet() -> void:
	if not is_instance_valid(sheet):
		return
	var width := minf(size.x - 32, 448)
	sheet.size.x = width
	# Container minimum sizes settle after width and autowrap have propagated.
	sheet.reset_size()
	sheet.size.x = width
	sheet.position = Vector2((size.x - width) / 2, maxf(16, (size.y - sheet.size.y) / 2))

func _close_sheet() -> void:
	if is_instance_valid(overlay):
		remove_child(overlay)
		overlay.queue_free()
	overlay = null
	sheet = null
	sheet_kind = ""
	game.paused = false
	_refresh()

func _show_pause() -> void:
	if game.completed:
		_show_victory()
		return
	if game.lost:
		_show_loss()
		return
	var content := _open_sheet("pause", "A moment to breathe.", "Your progress is saved. Pick up right where\nyou left off whenever you're ready.", "pause")
	_sheet_button(content, "Continue playing", _close_sheet, true)
	_sheet_button(content, "Start a new game", _show_new_game)
	_save_progress()

func _show_new_game() -> void:
	var content := _open_sheet("difficulty", "Find your next challenge.", "Six levels. Your pace. Choose a fresh puzzle.", "grid")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	for i in range(Library.LEVELS.size()):
		var level: String = Library.LEVELS[i]
		var card := _button("", _confirm_new.bind(level))
		card.name = level
		card.accessibility_name = "New " + level + " puzzle"
		card.custom_minimum_size = Vector2(150, 160)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("normal", _style(_soft() if level == game.level else _surface(), 12, _blue() if level == game.level else Color("dce5f3"), 1))
		grid.add_child(card)
		var title := _label(level, 17, _blue(), BOLD)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(title)
		title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		title.offset_top = 7
		title.offset_bottom = 32
		var preview := Preview.new()
		preview.puzzle.assign(Library.create(level, i + 900).givens)
		card.add_child(preview)
		preview.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		preview.offset_left = -47
		preview.offset_right = 47
		preview.offset_top = 36
		preview.offset_bottom = 130
		var descriptor := _label(DESCRIPTIONS[i], 10, _muted())
		descriptor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(descriptor)
		descriptor.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		descriptor.offset_top = -26
		descriptor.offset_bottom = -5
	call_deferred("_layout_sheet")

func _has_progress() -> bool:
	return not game.completed and not game.lost and (not game.history.is_empty() or game.mistakes > 0 or game.elapsed > 60)

func _confirm_new(level: String, date: String = "") -> void:
	if _has_progress():
		var content := _open_sheet("replace", "Start fresh?", "Your current puzzle will be replaced.\nA new %s challenge is waiting." % level.to_lower(), "grid")
		_sheet_button(content, "Start " + level, _start_game.bind(level, date), true)
		_sheet_button(content, "Keep my current puzzle", _close_sheet)
	else:
		_start_game(level, date)

func _start_game(level: String, date: String = "") -> void:
	_close_sheet()
	var new_seed := int(("daily-calm-v1:" + date).hash()) if not date.is_empty() else int(randi())
	game.new_game(level, new_seed, date)
	_refresh()
	_save_progress()
	_toast("A fresh start. You've got this.")

func _show_daily() -> void:
	var date := Time.get_date_string_from_system()
	var done: bool = date in stats.daily_dates
	var subtitle := "A shared puzzle for today. A fresh challenge every day.\nNo connection needed."
	var content := _open_sheet("daily", "Your daily moment.", subtitle, "calendar")
	var date_label := _label(_date_title(date), 23, _blue(), BOLD)
	content.add_child(date_label)
	content.add_child(_label("Medium difficulty · 3 hints · one clear mind", 12, _muted()))
	if done:
		content.add_child(_label("Today's challenge is complete. Nicely done!", 14, _ink(), SEMIBOLD))
		_sheet_button(content, "Back to my puzzle", _close_sheet, true)
	elif game.daily_date == date:
		_sheet_button(content, "Continue today's puzzle", _close_sheet, true)
	else:
		var play_daily := _sheet_button(content, "Play today's challenge", _confirm_new.bind("Medium", date), true)
		play_daily.name = "PlayDaily"
	call_deferred("_layout_sheet")

func _show_settings() -> void:
	var content := _open_sheet("settings", "Make it yours.", "Small details for a calmer game.", "settings")
	_setting_row(content, "Dark appearance", "A softer glow after hours", "dark")
	_setting_row(content, "Highlight related cells", "Follow the row, column and box", "highlight")
	_setting_row(content, "Highlight matching numbers", "See the same number at a glance", "same_numbers")
	_setting_row(content, "Clean up notes", "Remove candidates after a correct entry", "auto_notes")
	_setting_row(content, "Haptic feedback", "A gentle tap on supported phones", "haptics")
	var stats_label := _label("YOUR PROGRESS", 11, _blue(), BOLD)
	content.add_child(stats_label)
	var best: Variant = stats.best_times.get(game.level, null)
	var progress_text := "%d puzzles solved  ·  %d daily challenges" % [int(stats.wins), stats.daily_dates.size()]
	content.add_child(_label(progress_text, 14, _ink(), SEMIBOLD))
	if best != null:
		content.add_child(_label("Best %s time: %s" % [game.level.to_lower(), _time_string(float(best))], 13, _muted()))
	_sheet_button(content, "How to play", _show_help)
	call_deferred("_layout_sheet")

func _setting_row(content: VBoxContainer, title: String, description: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	content.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 2)
	row.add_child(text)
	text.add_child(_label(title, 14, _ink(), SEMIBOLD))
	text.add_child(_label(description, 10, _muted()))
	var toggle := _button("ON" if settings[key] else "OFF", func():
		settings[key] = not settings[key]
		_save_progress()
		if key == "dark":
			_rebuild_ui()
		_show_settings())
	toggle.name = key
	toggle.custom_minimum_size = Vector2(54, 44)
	toggle.add_theme_font_size_override("font_size", 11)
	if not settings[key]:
		toggle.add_theme_color_override("font_color", _muted())
	row.add_child(toggle)

func _rebuild_ui() -> void:
	_close_sheet()
	for node in [background, page, toast_label]:
		remove_child(node)
		node.queue_free()
	number_buttons.clear()
	number_counts.clear()
	_build_ui()
	_layout()
	_refresh()

func _show_help() -> void:
	var content := _open_sheet("help", "A few simple rules.", "Fill every row, column and 3 × 3 box with the numbers 1–9. Each number appears just once.", "grid")
	for entry in [
		["Select, then solve", "Tap an empty cell, then a number below. Blue numbers are yours; dark numbers are starting clues."],
		["Think in pencil", "Turn Notes on to keep track of possible numbers. Turn it off when you're ready to enter an answer."],
		["A nudge when you need it", "Each puzzle includes 3 hints. Undo reverses an entry, but doesn't refund mistakes or hints."],
		["Take your time", "After 3 mistakes, retry the puzzle or start fresh. The pause button saves your place and stops the clock."]]:
		content.add_child(_label(entry[0], 16, _ink(), SEMIBOLD))
		var body := _label(entry[1], 13, _muted())
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(body)
	_sheet_button(content, "I've got this", _close_sheet, true)

func _show_loss() -> void:
	var content := _open_sheet("loss", "Every try is progress.", "Three mistakes this time. Take a fresh look at\nthe same puzzle, or find a new challenge.", "sun")
	_sheet_button(content, "Try this puzzle again", func():
		var difficulty := game.level
		var seed_value := game.puzzle_seed
		var date := game.daily_date
		_close_sheet()
		game.new_game(difficulty, seed_value, date)
		_refresh()
		_save_progress(), true)
	_sheet_button(content, "Choose a new puzzle", _show_new_game)
	_save_progress()

func _show_victory() -> void:
	if not game.victory_recorded:
		game.victory_recorded = true
		stats.wins = int(stats.wins) + 1
		var best := float(stats.best_times.get(game.level, INF))
		if game.elapsed < best:
			stats.best_times[game.level] = game.elapsed
		if not game.daily_date.is_empty() and game.daily_date not in stats.daily_dates:
			stats.daily_dates.append(game.daily_date)
		_save_progress()
	var content := _open_sheet("victory", "Beautifully solved.", "One puzzle complete. A little more clarity.\nTake that good feeling with you.", "trophy")
	var result := _label("%s  ·  %s  ·  %d points" % [game.level, _time_string(game.elapsed), game.score], 17, _blue(), SEMIBOLD)
	content.add_child(result)
	content.add_child(_label("%d mistakes  ·  %d hints used" % [game.mistakes, 3 - game.hints], 14, _muted()))
	_sheet_button(content, "Another moment of calm", _show_new_game, true)
	_sheet_button(content, "Admire my puzzle", _close_sheet)

func _toast(message: String) -> void:
	if not is_instance_valid(toast_label):
		return
	if toast_tween:
		toast_tween.kill()
	toast_label.text = message
	toast_label.modulate.a = 0
	toast_tween = create_tween()
	toast_tween.tween_property(toast_label, "modulate:a", 0.96, 0.15)
	toast_tween.tween_interval(2.1)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)

func _time_string(seconds: float) -> String:
	var total := int(seconds)
	if total >= 3600:
		return "%d:%02d:%02d" % [total / 3600, (total % 3600) / 60, total % 60]
	return "%02d:%02d" % [total / 60, total % 60]

func _date_title(date: String) -> String:
	if date.length() < 10:
		return date
	var months := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
	var month := clampi(int(date.substr(5, 2)) - 1, 0, 11)
	return "%s %d" % [months[month], int(date.substr(8, 2))]

func _save_progress() -> void:
	if demo_mode or game.cells.is_empty():
		return
	var payload := {"game": game.serialize(), "settings": settings, "stats": stats}
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		push_warning("Could not save Sudoku progress: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(payload))
	file.close()
	var result := DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)
	if result != OK:
		push_warning("Could not finalize Sudoku progress: %s" % result)

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not payload is Dictionary:
		return
	if payload.get("settings") is Dictionary:
		for key in settings:
			if payload.settings.get(key) is bool:
				settings[key] = payload.settings[key]
	if payload.get("stats") is Dictionary:
		stats.wins = maxi(0, int(payload.stats.get("wins", 0)))
		if payload.stats.get("best_times") is Dictionary:
			for key in Library.LEVELS:
				var value: Variant = payload.stats.best_times.get(key)
				if (value is int or value is float) and float(value) >= 0:
					stats.best_times[key] = float(value)
		if payload.stats.get("daily_dates") is Array:
			for date in payload.stats.daily_dates:
				if date is String and date.length() == 10 and date not in stats.daily_dates:
					stats.daily_dates.append(date)
	if payload.get("game") is Dictionary:
		just_loaded = game.restore(payload.game)
