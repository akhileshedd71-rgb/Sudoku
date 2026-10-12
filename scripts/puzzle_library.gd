class_name PuzzleLibrary
extends RefCounted

const LEVELS := ["Easy", "Medium", "Hard", "Expert", "Master", "Extreme"]
const CLUES := [43, 36, 31, 28, 25, 23]

static func create(level: String, puzzle_seed: int) -> Dictionary:
	var library: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/puzzles.json"))
	var rng := RandomNumberGenerator.new()
	rng.seed = puzzle_seed
	var choices: Array = library.get(level, library["Medium"])
	var source: Dictionary = choices[rng.randi_range(0, choices.size() - 1)]
	var digits := _shuffle([1, 2, 3, 4, 5, 6, 7, 8, 9], rng)
	var rows: Array = []
	var cols: Array = []
	for band in _shuffle([0, 1, 2], rng):
		for row in _shuffle([0, 1, 2], rng):
			rows.append(band * 3 + row)
	for stack in _shuffle([0, 1, 2], rng):
		for col in _shuffle([0, 1, 2], rng):
			cols.append(stack * 3 + col)
	var transpose := rng.randf() > 0.5
	var givens: Array[int] = []
	var solution: Array[int] = []
	for i in range(81):
		var r: int = rows[i / 9]
		var c: int = cols[i % 9]
		var source_index: int = c * 9 + r if transpose else r * 9 + c
		var given := int(source["givens"][source_index])
		givens.append(0 if given == 0 else int(digits[given - 1]))
		solution.append(int(digits[int(source["solution"][source_index]) - 1]))
	return {"givens": givens, "solution": solution}

static func _shuffle(items: Array, rng: RandomNumberGenerator) -> Array:
	var result := items.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var value: Variant = result[i]
		result[i] = result[j]
		result[j] = value
	return result
