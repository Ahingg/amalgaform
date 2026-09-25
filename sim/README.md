# sim/ — pure simulation

Hard rule: NO file in this folder may touch Godot.
No `extends Node`, no `Area2D`, no signals, no engine clock.

Why: if the simulation depends on the engine, its state leaks outside World and
"instant retry" stops being one line. Everything that can change must live
inside World, so reset = throw the World away and build a new one.

Contents:
- `core/`           — World storage, component identifiers, spawn factories,
  shared rules, tuning, and run progression
- `components/`     — component data shapes (plain data, no behaviour)
- `helpers/`        — read-only query helpers and navigation/pathfinding
- `systems/`        — one file per system (behaviour, owning no data)

If something in here needs Godot, that is a sign it belongs in `view/` instead.
