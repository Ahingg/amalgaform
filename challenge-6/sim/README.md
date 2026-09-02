# sim/ — simulasi murni

Aturan keras: TIDAK ADA satu pun file di folder ini yang boleh menyentuh Godot.
Tidak ada `extends Node`, tidak ada `Vector2` dari engine kalau bisa dihindari,
tidak ada `Area2D`, tidak ada signal.

Alasannya: kalau simulasi bergantung ke engine, state-nya bocor keluar dari World
dan "retry instan" berhenti jadi satu baris. Semua yang bisa berubah harus hidup
di dalam World supaya reset = buang World, bikin lagi.

Isi:
- `world.gd`        — penyimpan entity + komponen, dan query
- `components/`     — definisi data komponen (data polos, tanpa perilaku)
- `systems/`        — satu file per system (perilaku, tanpa data milik sendiri)

Kalau butuh sesuatu dari Godot, itu tandanya barangnya milik `view/`, bukan sini.
