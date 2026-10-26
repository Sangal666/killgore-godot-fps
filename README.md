# Killgore

A first-person game prototype built with **Godot 4 and GDScript**, combining fast combat, movement experiments and a flashlight-driven horror chapter.

![Killgore gameplay](media/combat-gameplay.jpg)

[Watch an 18-second gameplay clip](media/gameplay-excerpt.mp4) · [Horror creature preview](media/horror-flashlight.png)

## Features

- First-person combat with multiple weapons, enemies, grenades and pickups.
- Sliding, charged jumps and grappling in combat levels.
- Grid-based environments, a TrenchBroom map and experimental levels.
- A horror chapter with a flashlight, battery management, hiding and an animated creature.
- Spatial sound effects, ambience, HUD, level selection and settings.

## Run

1. Open **Godot 4.6.2**.
2. Import this folder's `project.godot` and wait for asset imports.
3. Press **F5**, then choose **Play** or **Level Select**.

**Controls:** WASD to move, mouse to look, left/right click to attack, Space to jump, Shift to slide or sprint, Q to grapple, E to interact, R to reload, G for grenades, Esc to pause. In the horror chapter, F toggles the flashlight.

## Code structure

The main code is in `scripts/`: player movement, weapons, world logic, creature animation and audio are handled by separate controllers. The horror chapter has dedicated modules in `scripts/world/horror/` for room construction, missions, events, audio, geometry and materials, with shaders in `assets/shaders/horror/`. `HorrorSequenceLevel.gd` coordinates these modules. `scripts/tools/` contains runtime validation scripts; `tools/` contains optional Blender authoring scripts. Blender is not needed to play.

## Current state

This is a work-in-progress prototype. Five headless checks passed after the horror chapter was split into modules: module boundaries, level construction, the kitchen reveal, mission flow and route connectivity. The pre-refactor and modular level construction snapshots matched after excluding per-process object IDs. A full graphical playthrough and every level/weapon were not tested for this update. The clip shows an earlier combat build; the creature image is a staged runtime capture.

This portfolio version uses my legacy weapon visuals. Downloaded 3D weapon models are excluded. See `CREDITS.txt` for other asset credits.
