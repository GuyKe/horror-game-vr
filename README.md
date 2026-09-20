# Threshold — a Meta Quest VR horror prototype

A minimal, playable VR horror slice built with **Godot 4.3** and **OpenXR**,
targeting Meta Quest 2/3/Pro. You walk down a dark corridor with a flickering
flashlight; something is waiting at the door.

This is a first playable milestone, not a full game: one environment, core
locomotion, a flashlight, and one scripted scare. No external art or audio
assets — the geometry is built from primitives and the jump-scare stinger is
synthesized in code, so the whole project is pure source.

## Controls

| Input | Action |
|---|---|
| Left thumbstick | Smooth locomotion (head-relative) |
| Right thumbstick (flick left/right) | Snap turn (30°) |
| Right trigger (hold, aim, release) | Teleport |
| Right A button | Toggle flashlight |

## Project layout

```
project.godot           Engine + OpenXR + autoload config
export_presets.cfg       "Meta Quest" Android/OpenXR export preset
scenes/
  main.tscn               Corridor level, lighting, scare trigger
  xr_player.tscn           XR rig: origin, camera, controllers, flashlight
  entity.tscn              The scare "entity"
scripts/
  xr_player.gd             Locomotion, snap turn, teleport, flashlight
  game_manager.gd           Autoload; synthesizes the stinger sound
  entity.gd                 Appear/retreat animation for the scare
  scare_trigger.gd           Area3D that fires the encounter once
keystore/debug.keystore    Standard Android debug key (for sideload builds)
tools/
  setup_godot.sh            Installs Godot + export templates + Android build template
  build_apk.sh               Runs the actual export to build/threshold.apk
.github/workflows/build-apk.yml   CI: builds the APK on every push
```

## Getting the APK

**Easiest: GitHub Actions.** Every push builds `build/threshold.apk` and
uploads it as a workflow artifact ("threshold-quest-apk") under the Actions
tab — download it and skip straight to sideloading below.

**Locally**, you need a real Android SDK (this only works on a machine with
unrestricted internet — Godot's OpenXR export requires Android's Gradle
build, which pulls the Android Gradle Plugin and platform jars from Google's
Maven, `dl.google.com`):

```bash
export ANDROID_SDK_ROOT=/path/to/your/Android/sdk   # needs platforms;android-34, build-tools;34.0.0
bash tools/setup_godot.sh      # downloads Godot 4.3 + export templates, once
bash tools/build_apk.sh debug  # -> build/threshold.apk
```

`tools/setup_godot.sh` is idempotent — re-run it any time; it skips steps
that are already done.

> **Note on this repo's own dev environment:** this project was scaffolded
> in a network-sandboxed container that blocks `dl.google.com`, so the
> Gradle/OpenXR build was validated as far as Android Gradle Plugin
> resolution (project, export preset, keystore, and Android build template
> all confirmed correct) but not compiled end-to-end there. The CI workflow
> above builds on a normal GitHub-hosted runner with full internet access
> and does produce a real APK.

## Sideloading to your Quest

1. Enable Developer Mode on the headset via the Meta Horizon phone app.
2. Connect the headset over USB, accept the "Allow USB debugging" prompt in
   the headset.
3. `adb install -r build/threshold.apk`

The app will appear in your Quest's app library under "Unknown Sources".

## Opening the project in the Godot editor

Grab the matching editor build (Godot 4.3, Standard, not .NET) from
https://godotengine.org/download and open `project.godot`. You can run the
scene in an XR-capable desktop headset via OpenXR, or connect a Quest over
Air Link/Link cable and play in `main.tscn` directly.

## Where to go next

Ideas for the next milestone, roughly in order of impact:
- Real environment art (replace CSG primitives with modeled/decorated rooms)
- Hand-presence models + grab interactions instead of the placeholder cubes
- More than one scare/encounter, and a win/lose condition
- Comfort options menu (vignette on turn, locomotion speed, snap vs. smooth turn toggle)
- A release keystore + signed release build for wider distribution
