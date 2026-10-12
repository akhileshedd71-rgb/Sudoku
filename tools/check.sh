#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# A separate user-data directory keeps tests away from a player's saved game.
test_directory="$(mktemp -d /tmp/sudoku-checks.XXXXXX)"
trap 'rm -rf "$test_directory"' EXIT
export XDG_DATA_HOME="$test_directory/data"
export XDG_CONFIG_HOME="$test_directory/config"
export XDG_CACHE_HOME="$test_directory/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
run_godot() {
  local log_file="$test_directory/godot.log"
  if ! timeout 45s godot "$@" > "$log_file" 2>&1; then
    cat "$log_file"
    return 1
  fi
  cat "$log_file"
  if grep -Eq 'SCRIPT ERROR:|^ERROR:|^FAIL' "$log_file"; then return 1; fi
}
run_godot --headless --path . --editor --import --quit
python3 tests/test_puzzles.py
run_godot --headless --path . --script tests/test_game.gd
run_godot --headless --path . --script tests/test_ui.gd
run_godot --headless --path . --quit-after 5 -- --demo
printf 'All Sudoku checks passed.\n'
