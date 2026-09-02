# sim/ — pure simulation

Hard rule: NO file in this folder may touch Godot.
No `extends Node`, no `Area2D`, no signals, no engine clock.

Why: if the simulation depends on the engine, its state leaks outside World and
"instant retry" stops being one line. Everything that can change must live
inside World, so reset = throw the World away and build a new one.

Contents:
- `world.gd`        — entity + component storage, and queries
- `comp.gd`         — component name constants (typos caught by the editor)
- `components/`     — component data shapes (plain data, no behaviour)
- `systems/`        — one file per system (behaviour, owning no data)

If something in here needs Godot, that is a sign it belongs in `view/` instead.
