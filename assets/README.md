# Asset library

Game assets live here, grouped by the visual or audio role that uses them.
Keep filenames and directory casing consistent with references in
`view/rendering/sprites.gd` and `view/audio/sfx.gd`.

- `player/`, `enemies/` — character poses and enemy animation frames, including
  silhouette variants used for outlines.
- `runes/`, `misc/` — rune stones, rune marks, and cast-circle symbols.
- `fireball/`, `puddle/`, `burst/`, `Impact/`, `Wet/`, `held/` — spell, hit,
  status, and held-spell effects.
- `background1.PNG`, `background2.PNG` — arena floor textures.
- `sfx/` — music and sound effects loaded by the view audio controller.
- `icon.PNG` — project icon source configured in `project.godot`. The root
  `icon.svg` is an additional vector asset and is not the configured app icon.

Godot `.import` sidecars are generated metadata associated with source assets;
keep them alongside their source files and let Godot update them when assets
change.
