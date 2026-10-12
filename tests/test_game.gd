extends SceneTree

const State = preload("res://scripts/game_state.gd")
const Library = preload("res://scripts/puzzle_library.gd")
var checks := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		printerr("FAIL: " + message)

func _run() -> void:
	for level in Library.LEVELS:
		for seed_value in range(20):
			var puzzle := Library.create(level, seed_value)
			check(puzzle == Library.create(level, seed_value), "Deterministic seed: " + level)
			check(puzzle.givens.count(0) == 81 - Library.CLUES[Library.LEVELS.find(level)], "Clue count: " + level)
			for i in range(81):
				check(puzzle.givens[i] == 0 or puzzle.givens[i] == puzzle.solution[i], "Clue matches solution")
				for j in range(i):
					if State.peers(i, j):
						check(puzzle.solution[i] != puzzle.solution[j], "Transformed solution obeys constraints")
	var game := State.new()
	game.new_game("Medium", 42)
	var blank: int = game.givens.find(0)
	game.selected = blank
	game.note_mode = true
	check(game.enter(3) == "note", "Notes can be entered")
	check(game.cells[blank] == 0 and game.notes[blank] == 4, "Notes do not commit numbers")
	game.enter(3)
	check(game.notes[blank] == 0, "Notes toggle off")
	game.enter(4)
	game.undo()
	check(game.notes[blank] == 0, "Undo restores notes")
	game.note_mode = false
	var correct: int = game.solution[blank]
	var wrong: int = correct % 9 + 1
	check(game.enter(wrong) == "mistake", "Wrong answers report mistakes")
	check(game.mistakes == 1 and game.score == 0, "Mistakes don't award points")
	game.undo()
	check(game.cells[blank] == 0 and game.mistakes == 1, "Undo doesn't refund mistakes")
	game.notes.fill(1 << (correct - 1))
	check(game.enter(correct) == "correct", "Correct answers accepted")
	check(game.score == 20, "Medium gives 20 points")
	for i in range(81):
		if State.peers(i, blank):
			check(game.notes[i] & (1 << (correct - 1)) == 0, "Peer notes cleared")
	check(game.enter(correct) == "ignored" and game.score == 20, "Cannot repeat score")
	game.erase()
	check(game.score == 0 and game.cells[blank] == 0, "Erase removes awarded points")
	game.undo()
	check(game.score == 20 and game.cells[blank] == correct, "Undo erase restores entry and score")
	game.selected = game.givens.find(game.givens.filter(func(n): return n > 0)[0])
	check(game.enter(1) == "ignored" and not game.erase(), "Clues are immutable")
	var hinted := game.hint()
	check(hinted >= 0 and game.cells[hinted] == game.solution[hinted], "Hint chooses an editable cell")
	check(game.hints == 2, "Hint count decreases")
	game.undo()
	check(game.cells[hinted] == 0 and game.hints == 2, "Undo hint doesn't refund it")
	game.hint()
	game.hint()
	check(game.hint() == -1, "Only 3 hints available")
	game.paused = true
	game.selected = game.cells.find(0)
	check(game.enter(2) == "ignored" and not game.undo() and not game.erase(), "Pause blocks edits")
	game.paused = false
	var restored := State.new()
	var serialized: Dictionary = JSON.parse_string(JSON.stringify(game.serialize()))
	check(restored.restore(serialized), "Save round trip loads")
	check(restored.cells == game.cells and restored.notes == game.notes and restored.hints == game.hints, "Save round trip preserves gameplay")
	check(restored.history.size() == game.history.size(), "Save preserves undo history")
	var corrupt := serialized.duplicate(true)
	corrupt.solution[0] = corrupt.solution[1]
	check(not State.new().restore(corrupt), "Corrupt solutions rejected")
	corrupt = serialized.duplicate(true)
	corrupt.cells = [0]
	check(not State.new().restore(corrupt), "Truncated saves rejected")
	corrupt = serialized.duplicate(true)
	corrupt.cells[0] = "bad"
	check(not State.new().restore(corrupt), "Malformed cell types rejected")
	game.new_game("Easy", 99)
	game.selected = game.cells.find(0)
	for i in range(3):
		wrong = (game.solution[game.selected] + i) % 9 + 1
		if wrong == game.solution[game.selected]:
			wrong = wrong % 9 + 1
		game.enter(wrong)
	check(game.lost and game.mistakes == 3, "Three mistakes end the game")
	check(game.enter(game.solution[game.selected]) == "ignored", "Lost game blocks entry")
	game.new_game("Extreme", 101)
	for i in range(81):
		if game.givens[i] == 0:
			game.selected = i
			game.enter(game.solution[i])
	check(game.completed and not game.lost, "Completing all cells wins")
	check(game.score == (81 - 23) * 60, "Win score is correct")
	check(not game.undo() and not game.erase(), "Completed board cannot change")
	check(game.filled_count() == 81 and game.remaining(1) == 0, "Completion counters correct")
	print("Gameplay: %d assertions, %d failures; 120 transformed puzzles checked." % [checks, failed])
	quit(1 if failed else 0)
