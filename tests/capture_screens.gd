extends SceneTree

const Main = preload("res://scenes/main.tscn")
var app: Control

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	app = Main.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	app._close_sheet()
	app.game.new_game("Medium", 20261012)
	app.game.elapsed = 163
	var entered := 0
	for i in range(81):
		if app.game.cells[i] == 0:
			app.game.selected = i
			app.game.enter(app.game.solution[i])
			entered += 1
			if entered == 5:
				break
	app.game.selected = 40
	for i in [31, 40, 41, 49]:
		if app.game.cells[i] == 0:
			app.game.notes[i] = (1 << (app.game.solution[i] - 1)) | 18
	app._refresh()
	await capture("gameplay")
	app._show_new_game()
	await capture("difficulty")
	app._show_settings()
	await capture("settings")
	app._close_sheet()
	app.settings.dark = true
	app._rebuild_ui()
	await capture("dark")
	app.settings.dark = false
	app._rebuild_ui()
	root.size = Vector2i(480, 853)
	await process_frame
	app._layout()
	await capture("compact")
	app._show_new_game()
	await capture("compact-difficulty")
	app._close_sheet()
	for i in range(81):
		if app.game.givens[i] == 0:
			app.game.selected = i
			app.game.enter(app.game.solution[i])
	app._show_victory()
	await capture("victory")
	print("Captured 7 actual Godot screens.")
	quit()

func capture(filename: String) -> void:
	await create_timer(0.3).timeout
	app._layout_sheet()
	await process_frame
	await RenderingServer.frame_post_draw
	var folder := "res://build/screenshots"
	DirAccess.make_dir_recursive_absolute(folder)
	var image := root.get_texture().get_image()
	var result := image.save_png(folder + "/" + filename + ".png")
	if result != OK:
		printerr("Screenshot failed: ", result)
		quit(1)
