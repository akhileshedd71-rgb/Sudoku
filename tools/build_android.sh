#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/cloud_env.sh
mkdir -p build
touch build/.gdignore
godot --headless --path . --export-debug Android build/sudoku-daily-calm.apk
"$ANDROID_HOME/build-tools/36.0.0/apksigner" verify --verbose build/sudoku-daily-calm.apk
"$ANDROID_HOME/build-tools/36.0.0/zipalign" -c -P 16 4 build/sudoku-daily-calm.apk
python3 tools/verify_apk.py build/sudoku-daily-calm.apk
printf 'Verified development APK: build/sudoku-daily-calm.apk\n'
