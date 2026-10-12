"""Independently solve the shipped puzzles and check their declared answers."""
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from generate_puzzles import LEVELS, solutions


class PuzzleLibraryTests(unittest.TestCase):
    def test_all_eighteen_puzzles_are_unique_and_correct(self):
        data = json.loads((ROOT / "data/puzzles.json").read_text())
        self.assertEqual(list(data), [level for level, _ in LEVELS])
        checked = 0
        for level, clues in LEVELS:
            self.assertEqual(len(data[level]), 3)
            for entry in data[level]:
                with self.subTest(level=level, puzzle=checked):
                    givens = list(map(int, entry["givens"]))
                    answer = list(map(int, entry["solution"]))
                    self.assertEqual(len(givens), 81)
                    self.assertEqual(sum(n > 0 for n in givens), clues)
                    found = solutions(givens)
                    self.assertEqual(len(found), 1, "Puzzle must have exactly one solution")
                    self.assertEqual(found[0], answer)
                    checked += 1
        self.assertEqual(checked, 18)
        print("Verified all 18 puzzles have exactly one solution.")

    def test_solver_rejects_invalid_and_detects_ambiguous_grids(self):
        invalid = [0] * 81
        invalid[0] = invalid[1] = 1
        self.assertEqual(solutions(invalid), [])
        self.assertEqual(len(solutions([0] * 81)), 2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
