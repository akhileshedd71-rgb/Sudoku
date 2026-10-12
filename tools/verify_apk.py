#!/usr/bin/env python3
"""Check that the offline Android game includes its actual gameplay resources."""
import os
import subprocess
import sys
import zipfile
from pathlib import Path

apk = Path(sys.argv[1])
sdk = Path(os.environ.get("ANDROID_HOME", "/workspace/.sudoku-tools/android-sdk"))
badging = subprocess.check_output([str(sdk / "build-tools/36.0.0/aapt"), "dump", "badging", str(apk)], text=True)
assert "name='com.akhileshedd71.sudoku'" in badging
assert "android.permission.INTERNET" not in badging, "Offline build must not request Internet access"
assert "android.permission.VIBRATE" in badging
assert "arm64-v8a" in badging and "armeabi-v7a" in badging
with zipfile.ZipFile(apk) as archive:
    entries = archive.namelist()
    assert "assets/data/puzzles.json" in entries, "Puzzle library is required at runtime"
    assert any("scripts/main.gd" in name for name in entries), "Main game script is missing"
    assert not any(name.startswith("assets/tests/") or name.startswith("assets/tools/") for name in entries)
for line in badging.splitlines():
    if line.startswith(("package:", "sdkVersion:", "targetSdkVersion:", "native-code:", "uses-permission:")):
        print(line)
print("APK contains the game and puzzle data, both ARM architectures, and no Internet permission.")
