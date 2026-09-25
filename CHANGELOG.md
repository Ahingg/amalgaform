# Changelog

All notable changes to Amalgaform are documented here. This file follows
[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) and the project
uses Semantic Versioning.

## [Unreleased]

## [1.1.0] - 2026-09-25

### Added

- Added a standalone title menu, pause screen, and settings for audio and
  keyboard rebinding.
- Added editor-authored gameplay and room scenes with 16:9 defaults and
  viewport-aware scaling.
- Added two hand-authored dungeon rooms, obstacles, room exits, wave progression,
  health carryover, and a final victory state.
- Added gameplay regression coverage for menus, settings, rooms, obstacles,
  exits, waves, and victory; CI runs it on pushes and pull requests.
- Added Windows x86_64 export and a CI smoke test for the exported executable.
- Added randomized room order and larger authored room layouts for each run.

### Changed

- Made the room size configurable in the simulation.
- Simplified displayed keybind labels by hiding the physical-key indicator.
- Changed Wind Burst into a directional cone with matching collision and visual
  shapes.
- Kept scripted demo input behind an explicit `--demo` launch flag.
- Updated GitHub Actions runtimes and use Godot's console executable for
  synchronous Windows export checks.

### Fixed

- Updated displayed gameplay hints when key bindings change.
- Excluded the editor-only Git plugin from macOS and Windows game exports.
- Paused macOS CI and public builds; this release is Windows-only.

## [1.0.0] - 2026-09-09

This entry reconstructs the rotation build recorded by the repository's `v1.0`
tag. The historical tag itself is unchanged.

### Added

- Released the top-down spell-crafting arena with Fire, Water, and Wind runes;
  rune order determines spell shape and effects.
- Added player movement, dash, enemy waves, arena boundaries, and win and lose
  screens.
- Added the rune queue, aim-and-cast controls, time-slow casting window, HUD,
  hand-drawn art, and custom sound effects.
- Added an optional macOS build and notarization workflow plus CI project checks.

### Changed

- Established the English-language interface, dark ink-and-paper visual style,
  and the ten-day rotation build as the project's first playable version.
