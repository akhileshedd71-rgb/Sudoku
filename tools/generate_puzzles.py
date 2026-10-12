#!/usr/bin/env python3
"""Regenerate the bundled, unique-solution puzzle library. No dependencies."""
import json
import random
from pathlib import Path

FULL = (1 << 9) - 1
LEVELS = [("Easy", 43), ("Medium", 36), ("Hard", 31),
          ("Expert", 28), ("Master", 25), ("Extreme", 23)]


def solutions(board, limit=2):
    board = list(board)
    rows, cols, boxes = [0] * 9, [0] * 9, [0] * 9
    for i, n in enumerate(board):
        if n:
            r, c, b = i // 9, i % 9, (i // 27) * 3 + i % 9 // 3
            bit = 1 << (n - 1)
            if (rows[r] | cols[c] | boxes[b]) & bit:
                return []
            rows[r] |= bit
            cols[c] |= bit
            boxes[b] |= bit
    found = []

    def search():
        choice, possible, best = -1, 0, 10
        for i, n in enumerate(board):
            if n:
                continue
            r, c, b = i // 9, i % 9, (i // 27) * 3 + i % 9 // 3
            mask = FULL & ~(rows[r] | cols[c] | boxes[b])
            count = mask.bit_count()
            if count == 0:
                return
            if count < best:
                choice, possible, best = i, mask, count
                if count == 1:
                    break
        if choice == -1:
            found.append(board.copy())
            return
        r, c, b = choice // 9, choice % 9, (choice // 27) * 3 + choice % 9 // 3
        while possible and len(found) < limit:
            bit = possible & -possible
            possible ^= bit
            board[choice] = bit.bit_length()
            rows[r] |= bit
            cols[c] |= bit
            boxes[b] |= bit
            search()
            rows[r] ^= bit
            cols[c] ^= bit
            boxes[b] ^= bit
        board[choice] = 0

    search()
    return found


def make_puzzle(rng, clues):
    # Randomized solved boards, followed by uniqueness-preserving clue removal.
    for _ in range(120):
        bands, stacks = rng.sample(range(3), 3), rng.sample(range(3), 3)
        rows = [3 * b + r for b in bands for r in rng.sample(range(3), 3)]
        cols = [3 * b + c for b in stacks for c in rng.sample(range(3), 3)]
        digits = rng.sample(range(1, 10), 9)
        answer = [digits[(r * 3 + r // 3 + c) % 9] for r in rows for c in cols]
        puzzle = answer.copy()
        remaining = 81
        for cell in rng.sample(range(81), 81):
            old = puzzle[cell]
            puzzle[cell] = 0
            if len(solutions(puzzle)) == 1:
                remaining -= 1
                if remaining == clues:
                    return {"givens": "".join(map(str, puzzle)),
                            "solution": "".join(map(str, answer))}
            else:
                puzzle[cell] = old
    raise RuntimeError(f"Unable to create puzzle with {clues} clues")


if __name__ == "__main__":
    rng = random.Random(240519)
    library = {}
    for level, clues in LEVELS:
        library[level] = [make_puzzle(rng, clues) for _ in range(3)]
        print(f"{level}: 3 unique puzzles, {clues} clues", flush=True)
    target = Path(__file__).resolve().parents[1] / "data" / "puzzles.json"
    target.write_text(json.dumps(library, indent=2) + "\n")
