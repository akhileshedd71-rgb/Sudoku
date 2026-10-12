# Android export

## Tested cloud configuration

- Godot 4.6.3 standard build, Compatibility renderer.
- OpenJDK 21, Android SDK Platform 36, Build Tools 36.0.0, and Platform Tools 37.0.1.
- Matching official 4.6.3 Android debug/release templates, verified against the official SHA-512 manifest.
- SDK command-line tools archive `commandlinetools-linux-16111833_latest.zip`, checked against Google's repository checksum.
- Templates, SDK, cache, and development keystore live outside the checkout in `/workspace/.sudoku-tools`.

The standard APK export uses Godot's precompiled Android template. A Gradle build, CMake, and the NDK are unnecessary for this GDScript-only APK. SDK minimum/target overrides are deliberately empty because the standard template controls them.

## On another development machine

1. Install Godot 4.6.3 and its matching export templates using **Editor → Manage Export Templates**.
2. Install a compatible JDK and Android SDK, including Platform Tools and Build Tools. Set their paths in **Editor Settings → Export → Android**.
3. Import `project.godot`. The **Android** export preset is already configured for portrait, ARM64/ARMv7, haptics, and offline operation.
4. Choose **Project → Export → Android → Export Project** with **Export With Debug** checked to create a development APK.

The cloud helper `tools/configure_android.py` updates only the Android fields in local editor settings; it does not put machine paths or signing keys in the project export preset.

## Release distribution

For Google Play, install Godot's Android build template, enable **Use Gradle Build**, select **AAB**, and configure your own release signing key securely. Keep keystores and passwords out of Git. Before release, choose your permanent application ID, update the version code/name, and check the current Play target API requirement.

The included debug key is only a local development identity. This task does not publish anything to Google Play or sign with a production identity.

## Phone acceptance check

Install the APK on a real phone and verify: first launch, board selection, notes, keyboard-free play, hint confirmation, undo, win/loss/retry, app background/restore, force-stop/relaunch, Android Back, light/dark mode, notch and gesture-area spacing, and haptic feedback. Check both a compact display and a tall display. Hardware-specific behavior is not established by desktop rendering or an APK signature check.
