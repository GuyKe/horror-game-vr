# Fifi's Forest — a native Meta Quest port

An atmospheric VR experience for Meta Quest, built with **Godot 4.3** and
**OpenXR**. You spawn at sunrise at the edge of a sand clearing in the
middle of a forest that's noticeably larger than you are. Trees ring the
clearing on every side; a bonfire sits cold at its center. Sticks and rocks
are scattered around — pick them up and feed sticks to the fire to light it
and push back the dark; each stick buys about a minute of burn time. The sky
cycles through a full day and night as you play.

This is a **native port** of [first-vr-game](https://github.com/GuyKe/first-vr-game)
("Fifi's Forest" / "Firelight Clearing"), which is a browser-based
WebXR/Three.js experience. Same look, same scattered layout (identical seeded
placement for the forest and pickups), same day/night cycle timing, same
bonfire and grab mechanics — reimplemented from scratch in Godot/GDScript
since the two engines share no code, and packaged as a standalone
installable APK instead of a page you open in the Quest Browser.

## Controls

| Input | Action |
|---|---|
| Left thumbstick | Smooth locomotion (head-relative, no snap turn — same as the original) |
| Either trigger, pointed at a stick/rock | Hold to pull it into your hand |
| Either trigger, near the bonfire | Feed it a held stick |
| Either trigger, pointed at a menu button | Select |

The world starts on an in-headset menu with **PLAY** (drops you at the
bonfire) and **TUTORIAL** (a bare practice platform where you walk to a
glowing dot to learn locomotion, then return to the menu automatically).

## What's ported vs. approximated

Faithfully ported (same constants/formulas as the source):
- Forest floor + sand clearing + seeded tree scatter (seed `1337`)
- Seeded stick/rock scatter (seed `4242`) and pickup/grab mechanics
- Day/night sky, fog, ambient and sun/moon keyframes, 8-minute cycle
- Bonfire logs, flicker, embers, fuel timer (60s/stick)
- World scale (1.6x environment around a real-scale player)

Necessarily approximated (no equivalent primitive, or an engine-forced
change):
- The clearing's decorative boundary ring is omitted — Godot has no flat
  annulus primitive and a torus reads as a bulging donut, not a flat ring.
- Menu/HUD text uses Godot's `Label3D` instead of hand-drawn canvas
  textures, and rocks use a low-poly sphere instead of an icosahedron
  (Godot's primitive mesh set has neither a canvas nor an icosahedron).
- No physics/collision anywhere (matching the source, which has none
  either — locomotion is flat XZ translation, and you can walk through
  trees). OpenXR floor-tracking replaces the source's desktop-only
  1.6m eye-height fallback.

## Project layout

```
project.godot            Engine + OpenXR config
export_presets.cfg        "Meta Quest" Android/OpenXR export preset
scenes/
  main.tscn                Root scene: environment, day/night, menu wiring
  xr_player.tscn             XR rig: origin, camera, controllers (locomotion only)
  bonfire.tscn                Fire light + embers container (built in script)
  tutorial.tscn                Walk-to-the-dot practice platform
scripts/
  main.gd                     Mode state (menu/play/tutorial), spawn points, HUD
  xr_player.gd                  Head-relative smooth locomotion
  day_night_cycle.gd             Sky/fog/ambient/sun keyframe cycle
  forest.gd                       Seeded tree scatter (MultiMesh)
  bonfire.gd                       Logs, flame, embers, fuel timer
  pickups_spawner.gd               Seeded stick/rock scatter + pickup wiring
  interactable.gd / interaction_manager.gd   Shared "nearby + press to interact"
  grab_system.gd                    Point-and-hold VR pull-to-hand
  world_menu.gd                      In-world 3D PLAY/TUTORIAL panel
  tutorial.gd                         Practice platform logic
  mulberry32.gd                       Seeded PRNG, ported bit-for-bit from the source
  procedural_textures.gd               Runtime-generated glow/grid/panel textures
keystore/debug.keystore     Standard Android debug key (for sideload builds)
tools/
  setup_godot.sh               Installs Godot + export templates + Android build template
  build_apk.sh                  Runs the export to build/fifis_forest.apk
.github/workflows/build-apk.yml   CI: builds the APK on every push
```

## Getting the APK

**Easiest: GitHub Actions.** Every push builds `build/fifis_forest.apk` and
uploads it as a workflow artifact ("fifis-forest-quest-apk") under the
Actions tab — download it and skip straight to sideloading below.

**Locally**, you need a real Android SDK (this only works on a machine with
unrestricted internet — Godot's OpenXR export requires Android's Gradle
build, which pulls the Android Gradle Plugin and platform jars from Google's
Maven, `dl.google.com`):

```bash
export ANDROID_SDK_ROOT=/path/to/your/Android/sdk   # needs platforms;android-34, build-tools;34.0.0
bash tools/setup_godot.sh      # downloads Godot 4.3 + export templates, once
bash tools/build_apk.sh debug  # -> build/fifis_forest.apk
```

## Sideloading to your Quest

1. Enable Developer Mode on the headset via the Meta Horizon phone app.
2. Connect the headset over USB, accept the "Allow USB debugging" prompt in
   the headset.
3. `adb install -r build/fifis_forest.apk`

The app will appear in your Quest's app library under "Unknown Sources".

## Why OpenXR needs a vendored plugin

Godot's core engine ships no Meta/Quest OpenXR loader and adds none of the
Android manifest entries a standalone headset needs to launch straight into
VR. `addons/godotopenxrvendors` (the Godot OpenXR Vendors plugin, pruned to
just the Meta loader) supplies both — see the export preset's
`xr_features/enable_meta_plugin` and `meta_xr_features/*` options.

## Where to go next

The source project's own README lists good next steps that apply here too:
a reason to venture into the tree line, more uses for rocks, a way to see
remaining fuel without standing at the fire, ambient sound.
