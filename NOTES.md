# Catatan — utang yang sengaja ditunda

Hal-hal yang sudah diketahui tapi tidak dikerjakan sekarang, supaya tidak
mengganggu jalan ke deadline. Diisi saat ketemu, bukan saat sempat.

## Belum jalan (ada di daftar kerja)

- **Aqua tidak terasa.** `Wet` sudah ditempel ke target, tapi belum masuk daftar
  `TIMERS` dan `IntentSystem` belum membacanya. Sampai itu, air cuma menempel
  dan tidak melakukan apa-apa.
- **Ventus tidak terasa.** `Knocked` ditempel tanpa arah — `Make.knocked` cuma
  menyimpan `duration` dan `strength`. `ContactSystem` yang tahu arahnya
  (`pos_target - pos_sumber`), jadi dia yang harus mengisi `x`/`y` saat menempel.
  Dan `KnockbackSystem` belum ada.
- **`Comp.CHASE` di `Spawn.enemy` masih dikomentari**, jadi musuh diam di tempat.

## Utang desain

- **Kontak dinilai ulang tiap frame.** Selama sumber dan target masih
  bersinggungan, isi `OnHit` ditempel terus-menerus. Tidak masalah untuk peluru
  (langsung mati kena), tapi begitu ada bentuk yang bertahan — genangan, atau
  peluru tembus — efeknya akan menempel berkali-kali per detik. Butuh entah
  daftar "sudah kena siapa" di sumber, atau jeda antar-kena.

- **Lingkup `OnHit` baru dua: `self` dan `target`.** Menambah lingkup baru
  (`world`, `everyone`, `area`) berarti `ContactSystem` harus tahu cara
  menerjemahkan tiap lingkup jadi daftar entity — dan itu memang pertumbuhan
  cabang yang nyata, bukan bisa dihindari dengan tabel. Batasnya: selama lingkup
  bisa dihitung dengan jari dan tidak bertambah tiap kali ada spell baru, ini
  masih sehat. Kalau nanti tiap spell butuh lingkupnya sendiri, itu tandanya
  lingkup harus jadi data (misalnya query yang disimpan di dalam action), bukan
  cabang.

- **`Grammar.build` mengasumsikan `PAYLOAD` selalu punya `self` dan `target`.**
  Kalau salah satu lupa ditulis, spell-nya diam-diam tidak melakukan apa pun —
  tidak ada error. Layak dijaga kalau nanti rune-nya bertambah.

## Setelah deadline

- Kerucut yang sebenarnya (butuh tabrakan berputar, `Helper.overlap` hanya AABB)
- Migrasi komponen Dictionary -> class (lihat DESIGN.md)
