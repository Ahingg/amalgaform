# Simulation architecture

This is a small, project-owned ECS—not an archetype/third-party ECS framework.
Entities are integer IDs, components are data stored by component name in
`World`, and systems query entities and apply gameplay rules. `Comp` centralizes
component names; `SystemManager` makes update order explicit.

Keep gameplay rules and authoritative per-room state in `sim/`. Components
should remain data-only; systems own behavior. Entity factories in `core/`
assemble components, but should not decide gameplay behavior. Prefer this
straightforward structure until profiling or a concrete feature requires more.

Simulation code must not depend on the scene tree, `Node` lifecycle, signals,
input, rendering, audio playback, or wall-clock engine state. Godot value types
such as `Rect2` are fine when useful to the rules. The view may read the `World`
and translate authored room-scene data into simulation setup input. Input/UI
adapters may submit transient player-intent components (movement, cast, and
launch requests); only simulation systems should turn those intents into
gameplay outcomes. Other view code must not edit components or apply gameplay
rules.

`view/app/main.gd` owns the current-World reference and session lifecycle, but
passes room-scene data to `RoomFactory` for World/entity initialization. Keep
that boundary: new simulation initialization and state changes should go
through simulation-owned APIs, not direct view-side gameplay-state mutation.

Resetting a room should remain cheap: discard its `World` and construct another
one. Run-level progression may live outside a room's `World`, but it stays in
`sim/` rather than becoming authoritative state in a view node.

Contents:
- `core/`           — World storage, component identifiers, spawn factories,
  shared rules, tuning, and run progression
- `components/`     — component data shapes (plain data, no behaviour)
- `helpers/`        — read-only query helpers and navigation/pathfinding
- `systems/`        — one file per system (behaviour, owning no data)

If something in here needs Godot, that is a sign it belongs in `view/` instead.
