class_name GameState
extends RefCounted

const Library = preload("res://scripts/puzzle_library.gd")
const SAVE_VERSION := 1
var givens: Array[int] = []
var solution: Array[int] = []
var cells: Array[int] = []
var notes: Array[int] = []
var history: Array[Dictionary] = []
var level := "Medium"
var puzzle_seed := 0
var daily_date := ""
var selected := -1
var mistakes := 0
var score := 0
var hints := 3
var elapsed := 0.0
var note_mode := false
var paused := false
var completed := false
var lost := false
var victory_recorded := false

func new_game(difficulty: String = "Medium", new_seed: int = 0, date: String = "") -> void:
	level = difficulty if difficulty in Library.LEVELS else "Medium"
	puzzle_seed = new_seed
	daily_date = date
	var puzzle := Library.create(level, puzzle_seed)
	givens.assign(puzzle.givens)
	solution.assign(puzzle.solution)
	cells = givens.duplicate()
	notes.resize(81)
	notes.fill(0)
	history.clear()
	selected = -1
	mistakes = 0
	score = 0
	hints = 3
	elapsed = 0.0
	note_mode = false
	paused = false
	completed = false
	lost = false
	victory_recorded = false

func is_editable(index: int) -> bool:
	return index >= 0 and index < 81 and givens[index] == 0 and not paused and not completed and not lost

func enter(number: int, auto_notes: bool = true) -> String:
	if number < 1 or number > 9 or not is_editable(selected):
		return "ignored"
	if note_mode:
		if cells[selected] != 0:
			return "ignored"
		_snapshot()
		notes[selected] = notes[selected] ^ (1 << (number - 1))
		return "note"
	if cells[selected] == number:
		return "ignored"
	# Correct entries stay in place, so points cannot be farmed by replacing them.
	if cells[selected] == solution[selected]:
		return "ignored"
	_snapshot()
	cells[selected] = number
	notes[selected] = 0
	if number != solution[selected]:
		mistakes += 1
		lost = mistakes >= 3
		return "mistake"
	score += 10 * (Library.LEVELS.find(level) + 1)
	if auto_notes:
		_clean_notes(selected, number)
	_check_complete()
	return "complete" if completed else "correct"

func erase() -> bool:
	if not is_editable(selected) or (cells[selected] == 0 and notes[selected] == 0):
		return false
	# A correct entry can be erased; its points are removed with it.
	_snapshot()
	if cells[selected] == solution[selected]:
		score = maxi(0, score - 10 * (Library.LEVELS.find(level) + 1))
	cells[selected] = 0
	notes[selected] = 0
	return true

func undo() -> bool:
	if history.is_empty() or paused or completed or lost:
		return false
	var old: Dictionary = history.pop_back()
	cells.assign(old.cells)
	notes.assign(old.notes)
	score = int(old.score)
	selected = int(old.selected)
	# Mistakes and spent hints intentionally remain consumed.
	return true

func hint(auto_notes: bool = true) -> int:
	if paused or completed or lost or hints <= 0:
		return -1
	var target := selected
	if target < 0 or givens[target] != 0 or cells[target] == solution[target]:
		target = -1
		for i in range(81):
			if cells[i] != solution[i]:
				target = i
				break
	if target < 0:
		return -1
	_snapshot()
	selected = target
	cells[target] = solution[target]
	notes[target] = 0
	hints -= 1
	score += 10 * (Library.LEVELS.find(level) + 1)
	if auto_notes:
		_clean_notes(target, solution[target])
	_check_complete()
	return target

func remaining(number: int) -> int:
	var count := 0
	for i in range(81):
		if cells[i] == number and cells[i] == solution[i]:
			count += 1
	return maxi(0, 9 - count)

func filled_count() -> int:
	var count := 0
	for i in range(81):
		if cells[i] == solution[i]:
			count += 1
	return count

func _snapshot() -> void:
	history.append({"cells": cells.duplicate(), "notes": notes.duplicate(), "score": score, "selected": selected})
	if history.size() > 150:
		history.pop_front()

func _clean_notes(index: int, number: int) -> void:
	for i in range(81):
		if peers(i, index):
			notes[i] = notes[i] & ~(1 << (number - 1))

static func peers(a: int, b: int) -> bool:
	return a / 9 == b / 9 or a % 9 == b % 9 or (a / 27 == b / 27 and a % 9 / 3 == b % 9 / 3)

func _check_complete() -> void:
	completed = cells == solution

func serialize() -> Dictionary:
	return {"version": SAVE_VERSION, "level": level, "seed": puzzle_seed, "daily_date": daily_date,
		"givens": givens, "solution": solution, "cells": cells, "notes": notes,
		"selected": selected, "mistakes": mistakes, "score": score, "hints": hints,
		"elapsed": elapsed, "note_mode": note_mode, "completed": completed, "lost": lost,
		"history": history, "victory_recorded": victory_recorded}

func restore(data: Dictionary) -> bool:
	if int(data.get("version", 0)) != SAVE_VERSION or data.get("level", "") not in Library.LEVELS:
		return false
	for key in ["givens", "solution", "cells", "notes"]:
		if not data.get(key) is Array or data[key].size() != 81:
			return false
	for i in range(81):
		for key in ["givens", "solution", "cells", "notes"]:
			if not (data[key][i] is float or data[key][i] is int):
				return false
		var value := int(data.cells[i])
		var given := int(data.givens[i])
		var answer := int(data.solution[i])
		if value < 0 or value > 9 or given < 0 or given > 9 or answer < 1 or answer > 9:
			return false
		if int(data.notes[i]) < 0 or int(data.notes[i]) > 511:
			return false
		if given != 0 and (given != answer or given != value):
			return false
		for j in range(i):
			if peers(i, j) and int(data.solution[j]) == answer:
				return false
	level = str(data.level)
	puzzle_seed = int(data.get("seed", 0))
	daily_date = str(data.get("daily_date", ""))
	givens.assign(data.givens)
	solution.assign(data.solution)
	cells.assign(data.cells)
	notes.assign(data.notes)
	selected = clampi(int(data.get("selected", -1)), -1, 80)
	mistakes = clampi(int(data.get("mistakes", 0)), 0, 3)
	score = maxi(0, int(data.get("score", 0)))
	hints = clampi(int(data.get("hints", 3)), 0, 3)
	elapsed = maxf(0.0, float(data.get("elapsed", 0.0)))
	note_mode = bool(data.get("note_mode", false))
	completed = cells == solution
	lost = mistakes >= 3 and not completed
	victory_recorded = bool(data.get("victory_recorded", false))
	paused = false
	history.clear()
	# Validate each undo snapshot; damaged optional history never blocks recovery.
	var saved_history: Variant = data.get("history", [])
	if saved_history is Array:
		for item in saved_history.slice(-150):
			if not item is Dictionary:
				continue
			if not item.get("cells") is Array or not item.get("notes") is Array:
				continue
			if item.cells.size() != 81 or item.notes.size() != 81:
				continue
			var valid := true
			for i in range(81):
				if not (item.cells[i] is float or item.cells[i] is int) or not (item.notes[i] is float or item.notes[i] is int):
					valid = false
					break
				if int(item.cells[i]) < 0 or int(item.cells[i]) > 9 or int(item.notes[i]) < 0 or int(item.notes[i]) > 511:
					valid = false
				if givens[i] != 0 and int(item.cells[i]) != givens[i]:
					valid = false
			if valid:
				history.append({"cells": item.cells, "notes": item.notes,
					"score": maxi(0, int(item.get("score", 0))), "selected": clampi(int(item.get("selected", -1)), -1, 80)})
	return true
