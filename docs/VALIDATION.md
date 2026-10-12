# Validation

Validated in the cloud environment with Godot **4.6.3**, Python **3.12**, OpenJDK **21**, and Android Build Tools **36.0.0**.

| Check | Result |
| --- | --- |
| Godot project import and startup | Passed; no gameplay script errors |
| Independent puzzle solver | All 18 source puzzles have exactly one solution and the stored answer matches |
| Seeded puzzle transformation | 120 puzzles across all six levels; reproducible seeds, correct clues, valid rows, columns, and boxes |
| Gameplay suite | 107,211 assertions passed (most exhaustively check transformed grid constraints) |
| UI integration suite | 21 assertions passed, including actual pointer selection, keypad, notes, undo, hint confirmation, pause timer, difficulty replacement, daily challenge, theme changes, disk saves, and victory statistics |
| Portrait layout | Square board and controls verified at 480×960, 480×853, and 540×1200 viewport sizes |
| Visual review | Seven actual Godot renders captured; gameplay, difficulty picker, settings, dark mode, compact layout, compact picker, and victory |
| Android export | Development APK successfully produced with official 4.6.3 templates |
| APK signatures | APK Signature Schemes v2 and v3 verified |
| APK alignment | `zipalign -c -P 16 4` passed |
| APK resources | Main game and JSON puzzle library included; development tests/tools excluded |
| Android metadata | Package `com.akhileshedd71.sudoku`, version 1.0.0, minimum API 24, target API 36, ARM64 + ARMv7 |
| Android permissions | Vibration only; Internet permission absent |
| Setup repeatability | Local setup script rerun successfully without changing game source or losing player saves |

The cloud renderer uses Mesa software rendering under Xvfb. Its unsupported V-Sync warning is a display-driver limitation. Godot's editor can also report that it cannot connect to an adb daemon when no device service is running; neither message prevents gameplay or APK export. No Android device or emulator is attached.

**Still to verify on a physical phone:** installation, actual touch and haptic behavior, safe areas on devices with cutouts, and Android lifecycle behavior. The supplied APK is a debug-signed development build. Store submission, production signing, and Google Play publication have not been performed.

## Reproduce

```sh
cd /workspace/Sudoku
bash tools/setup_cloud.sh
bash tools/check.sh
bash tools/build_android.sh
```

For screenshots in the prepared cloud image, start its retained virtual display if none is running:

```sh
source tools/cloud_env.sh
LD_LIBRARY_PATH=/workspace/.sudoku-tools/apt/root/usr/lib/x86_64-linux-gnu \
  /workspace/.sudoku-tools/apt/root/usr/bin/Xvfb :99 \
  -screen 0 1280x1440x24 -ac -nolisten tcp \
  -fp /workspace/.sudoku-tools/apt/root/usr/share/fonts/X11/misc
```

Run that process in a managed background terminal, then run in another terminal:

```sh
source tools/cloud_env.sh
DISPLAY=:99 godot --path . --audio-driver Dummy \
  --script tests/capture_screens.gd -- --demo
```

Xvfb is an optional visual-test tool, not an application runtime dependency. It was installed locally from Debian's signed repository without changing system packages. The prepared filesystem retains it; `tools/setup_cloud.sh` installs the required Godot Android workflow, not the optional virtual display. Do not assume running processes survive a new cloud task.
