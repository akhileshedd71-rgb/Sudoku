# Sudoku — Daily Calm

A complete offline Sudoku game for Android, built in **Godot 4.6.3** with GDScript. The portrait interface takes its visual direction from classic mobile Sudoku: white surfaces, blue entries, clear box boundaries, pencil notes, and a number pad. It includes an original icon and a dark appearance.

## Play

Open `project.godot` in Godot 4.6.3 and press **F5**, or run:

```sh
godot --path .
```

Tap a cell, then a number. Use **Notes** for candidates, **Undo** to reverse moves, **Erase** to clear a cell, and **Hint** to reveal a number. Each puzzle allows three mistakes and three hints. Undo doesn't refund mistakes or hints. The small number below each key shows how many correct placements remain.

- Six levels, from Easy to Extreme, with 18 independently verified, unique-solution source puzzles and randomized Sudoku-preserving transformations.
- A deterministic daily challenge based on the phone's local calendar date; works without a connection.
- Automatic progress saving, including notes and undo history. Pause and app backgrounding stop the timer.
- A completion screen, best times by level, completed daily challenges, and total puzzles solved.
- Configurable related-cell highlights, matching-number highlights, note cleanup, haptics, and light/dark appearance.
- Portrait layouts adapt to phone proportions and Android safe areas.
- No ads, accounts, analytics, paid hints, or network dependencies.

Keyboard controls: **1–9** enter numbers, **arrows** select cells, **N** toggles notes, **H** opens a hint, **Backspace/Delete** erases, **Ctrl/Cmd+Z** undoes, and **Esc/P** pauses.

## Android build

The prepared cloud environment has the SDK and matching Godot Android templates. From this checkout:

```sh
bash tools/setup_cloud.sh
bash tools/build_android.sh
```

The development APK is written to **`build/sudoku-daily-calm.apk`**. Transfer it to your phone and open it to install. Android may ask you to allow installation from the file app you used. It supports ARM64 and ARMv7 devices. This is a debug-signed build for trying the game; a Play Store release requires your own release signing key and an AAB export. See [Android export](docs/ANDROID.md).

## Checks

```sh
bash tools/check.sh
```

This solves all 18 puzzles independently in Python, verifies 120 transformed puzzles in Godot, tests the gameplay rules and persistence, drives the actual UI, and performs a startup smoke check. Tests use separate temporary save directories.

For real rendered screenshots, run on a machine with a display:

```sh
godot --path . --audio-driver Dummy --script tests/capture_screens.gd -- --demo
```

Seven images are written to `build/screenshots/`. The screenshot fixture is deterministic and never overwrites a player's save.

## Project structure

| Path | Purpose |
| --- | --- |
| `scripts/main.gd` | Responsive interface, menus, input, lifecycle, saves, and statistics |
| `scripts/game_state.gd` | Testable gameplay rules and undo history |
| `scripts/puzzle_library.gd` | Seeded, Sudoku-preserving transformations |
| `scripts/board.gd` | Scalable grid, highlights, digits, notes, and selection |
| `data/puzzles.json` | Verified puzzle/solution pairs |
| `tools/generate_puzzles.py` | Reproducible uniqueness-preserving puzzle generation |
| `tests/` | Independent solver, gameplay, UI, and visual checks |

Difficulty currently corresponds to clue counts (43, 36, 31, 28, 25, 23), rather than a certified rating of the logical techniques needed. Randomized variants preserve uniqueness but share the structures of the 18 source puzzles. The game stores one active puzzle; starting another asks before replacing meaningful progress.

## Development environment

In this cloud environment, run `source tools/cloud_env.sh` before starting Godot. It points caches, export templates, and Android tools to `/workspace/.sudoku-tools`. The existing checkout is already isolated; no Git worktree is necessary.

There are no long-running backend services, required secrets, or application environment variables. See [validation notes](docs/VALIDATION.md) for what has been exercised and what still needs a real phone.

Third-party notices are included in `assets/GODOT-LICENSE.txt` and `assets/fonts/`. Open Sans is licensed under Apache 2.0; Godot is licensed under MIT.
