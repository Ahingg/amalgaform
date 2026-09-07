# assets/

Nama berkas dipakai langsung oleh kode, jadi harus persis. Semua PNG transparan.

## sprites/
    player_idle.png        256x256   penyihir, diam
    player_move.png        256x256   penyihir, bergerak / dash
    player_cast.png        256x256   penyihir, merapal (tangan terangkat)
    enemy_blob.png         256x256   gumpalan bermata
    enemy_walker.png       256x256   makhluk berkaki panjang, frame 1
    enemy_walker_b.png     256x256   frame 2 (kaki bergantian) — opsional

Titik jangkar harus sama di semua frame karakter, kalau tidak spritenya akan
melompat saat berganti pose.

## runes/
    ignis_stone.png   ignis_mark.png
    aqua_stone.png    aqua_mark.png
    ventus_stone.png  ventus_mark.png

Semua 256x256. `_stone` bertinta hitam; `_mark` PUTIH di atas transparan supaya
bisa diwarnai lewat kode.

## fx/
    cast_ring.png          256x256   LINGKARAN penuh (bukan elips), putih.
                                     Dipipihkan dan diputar lewat kode.

## sfx/
    rune.wav  cast.wav  launch.wav  hit.wav  death.wav  hurt.wav
