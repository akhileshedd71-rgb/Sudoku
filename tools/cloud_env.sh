#!/usr/bin/env bash
# Source this file in the cloud workspace. No credentials are stored here.
export SUDOKU_TOOLS_DIR="${SUDOKU_TOOLS_DIR:-/workspace/.sudoku-tools}"
export XDG_DATA_HOME="$SUDOKU_TOOLS_DIR/xdg-data"
export XDG_CONFIG_HOME="$SUDOKU_TOOLS_DIR/xdg-config"
export XDG_CACHE_HOME="$SUDOKU_TOOLS_DIR/cache"
export ANDROID_USER_HOME="$SUDOKU_TOOLS_DIR/android-user"
export ANDROID_HOME="$SUDOKU_TOOLS_DIR/android-sdk"
export PATH="$SUDOKU_TOOLS_DIR/bin:$ANDROID_HOME/platform-tools:$PATH"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$ANDROID_USER_HOME"
