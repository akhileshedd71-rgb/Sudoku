extends SceneTree

const Main = preload("res://scenes/main.tscn")
var checks := 0
var failures := 0
var app: Control

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL UI: " + message)

func _run() -> void:
	root.size = Vector2i(480, 960)
	app = Main.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	app._close_sheet()
	app.stats = {"wins": 0, "best_times": {}, "daily_dates": []}
	if app.settings.dark:
		app.settings.dark = false
		app._rebuild_ui()
	app.game.new_game("Medium", 8802)
	app._refresh()
	var blank: int = app.game.cells.find(0)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = app.board.global_position + Vector2(blank % 9 + 0.5, blank / 9 + 0.5) * app.board.size.x / 9.0
	root.push_input(event, true)
	check(app.game.selected == blank, "Actual board pointer event selects intended cell")
	app.notes_button.pressed.emit()
	app.number_buttons[2].pressed.emit()
	check(app.game.notes[blank] == 4, "Notes button and keypad route to model")
	app.undo_button.pressed.emit()
	check(app.game.notes[blank] == 0, "Undo button restores note")
	app.notes_button.pressed.emit()
	var answer: int = app.game.solution[blank]
	app.number_buttons[answer - 1].pressed.emit()
	check(app.game.cells[blank] == answer and app.score_value.text == "20", "Keypad updates board and score label")
	app._show_pause()
	await process_frame
	var old_elapsed: float = app.game.elapsed
	app._process(2.0)
	check(app.game.elapsed == old_elapsed and app.game.paused, "Pause stops timer")
	app.overlay.find_child("ContinuePlaying", true, false).pressed.emit()
	check(not app.game.paused, "Continue resumes game")
	app._hint()
	await process_frame
	app.overlay.find_child("RevealANumber", true, false).pressed.emit()
	check(app.game.hints == 2, "Hint confirmation consumes one hint")
	app._show_new_game()
	await process_frame
	check(app.overlay.find_child("Extreme", true, false) != null, "Six-level picker includes Extreme")
	app.overlay.find_child("Hard", true, false).pressed.emit()
	await process_frame
	check(app.sheet_kind == "replace", "New puzzle protects current progress")
	app.overlay.find_child("StartHard", true, false).pressed.emit()
	check(app.game.level == "Hard" and app.game.history.is_empty(), "New puzzle changes difficulty and resets progress")
	app._show_daily()
	await process_frame
	app.overlay.find_child("PlayDaily", true, false).pressed.emit()
	check(app.game.daily_date == Time.get_date_string_from_system(), "Daily challenge starts today's seeded puzzle")
	app._show_settings()
	await process_frame
	app.overlay.find_child("dark", true, false).pressed.emit()
	await process_frame
	check(app.settings.dark and app.board.dark, "Dark theme reaches board and rebuilt interface")
	app._close_sheet()
	app.game.selected = app.game.cells.find(0)
	app.game.enter(app.game.solution[app.game.selected])
	app.game.elapsed = 125
	app._save_progress()
	var saved_cells: Array = app.game.cells.duplicate()
	app.game.new_game("Easy", 1)
	app._load_progress()
	check(app.game.cells == saved_cells and app.game.elapsed == 125, "Actual disk save restores state")
	app.game.new_game("Easy", 55)
	for i in range(81):
		if app.game.givens[i] == 0:
			app.game.selected = i
			app.game.enter(app.game.solution[i])
	var previous_wins: int = app.stats.wins
	app._show_victory()
	app._show_victory()
	check(app.stats.wins == previous_wins + 1, "Victory records statistics exactly once")
	check(app.sheet_kind == "victory", "Win opens completion screen")
	app._close_sheet()
	for viewport_size in [Vector2i(480, 960), Vector2i(480, 853), Vector2i(540, 1200)]:
		root.size = viewport_size
		await process_frame
		app._layout()
		check(app.footer.position.y + app.footer.size.y <= app.page.size.y + 1, "Footer fits portrait viewport " + str(viewport_size))
		check(app.board.size.x == app.board.size.y and app.board.size.x > 300, "Square board fits viewport")
	print("UI integration: %d assertions, %d failures." % [checks, failures])
	app.queue_free()
	await process_frame
	quit(1 if failures else 0)
