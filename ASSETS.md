# Spesifikasi Aset — Senin & Selasa

Deadline Kamis. Feature freeze Rabu malam. Jadi aset harus **selesai Selasa
malam**, bukan Rabu.

---

## Aturan yang paling menghemat waktu: JANGAN BIKIN SPRITESHEET

Gambar **satu sprite diam per entity**. Gerakannya dibuat lewat kode:

- Bergoyang naik-turun pelan saat diam
- Miring ke arah gerak
- Memipih dan memanjang saat dash
- Berkedip putih saat kena
- Berputar saat terpental

Semua itu saya kerjakan di lapisan tampilan, dan hasilnya **lebih hidup**
daripada animasi 3 frame — sambil menghemat satu hari penuh menggambar.

Kalau ternyata ada sisa waktu Selasa malam, baru tambahkan 1 frame idle kedua.
Jangan direncanakan dari sekarang.

---

## Daftar aset, urut dari yang paling tinggi nilainya

### 1. Tiga glyph rune — PRIORITAS TERTINGGI

Ini yang paling sering dilihat pemain: dia melototinya tiap kali merapal, di
bawah tekanan waktu. Juga yang paling cepat digambar.

| | |
|---|---|
| Jumlah | 3 (Ignis, Aqua, Ventus) |
| Ukuran file | **256 x 256 px**, PNG transparan |
| Warna | tinta gelap saja — pewarnaan dilakukan kode |
| Gaya | simbol, bukan ilustrasi |

**Sengaja tidak swalayan.** Jangan gambar api yang jelas-jelas api. Gambar
simbol yang artinya baru ketahuan setelah pemain melihat efeknya — supaya
memecahkan arti glyph ikut jadi bagian dari risetnya.

Yang penting: **ketiganya harus bisa dibedakan dalam 0,2 detik** pada ukuran
52px. Uji dengan mengecilkannya, bukan dengan melihatnya besar-besar.

### 2. Penyihir (player)

| | |
|---|---|
| Ukuran file | **256 x 256 px**, PNG transparan |
| Sudut pandang | 3/4 dari atas — badan terlihat, wajah sedikit menunduk |
| Isi kanvas | figurnya sekitar 80% tinggi kanvas, sisanya ruang kosong |
| Menghadap | gambar menghadap KANAN. Arah lain dibuat kode (dicerminkan/diputar) |

Satu gambar saja. Jangan bikin empat arah.

### 3. Musuh — 2 jenis

| | |
|---|---|
| Ukuran file | **256 x 256 px** masing-masing, PNG transparan |
| Gaya | siluet gumpalan tinta, mata 1-2, tanpa detail dalam |

Dua yang berbeda **bentuk siluetnya**, bukan cuma warnanya — karena warnanya
akan sama-sama tinta. Misal: satu bulat gempal, satu tinggi kurus.

### 4. Kalau masih ada waktu (jangan dipaksa)

- Tekstur lantai kertas (bisa diulang / tileable), 256x256
- Ikon bola siap-tembak
- Bingkai halaman untuk pinggir arena

---

## Format, ringkas

- **PNG transparan.** Bukan JPG
- **256 x 256** untuk semuanya. Satu entity = 1 petak = 52px di layar, jadi 256
  memberi ruang untuk diperbesar tanpa pecah
- **Satu berkas satu benda.** Jangan digabung dalam satu kanvas
- **Nama berkas:** `rune_ignis.png`, `rune_aqua.png`, `rune_ventus.png`,
  `player.png`, `enemy_a.png`, `enemy_b.png`
- Taruh di `challenge-6/assets/`

---

## Suara

**Jangan dibuat sendiri.** Ambil dari yang gratis — ini investasi rasa-main
tertinggi per menit yang tersisa, dan tidak memakan waktu menggambar sama
sekali.

Sumber: **Kenney.nl** (CC0, tanpa atribusi) atau **freesound.org**.

Enam berkas, itu cukup:

| Suara | Kapan |
|---|---|
| `rune.wav` | tiap rune masuk antrian — nada beda tiap rune kalau ada |
| `cast.wav` | bola siap |
| `launch.wav` | spell dilepas |
| `hit.wav` | musuh kena |
| `death.wav` | musuh mati |
| `hurt.wav` | player kena |

Format WAV atau OGG, pendek (di bawah 1 detik kecuali `death`).
Taruh di `challenge-6/assets/sfx/`.

Waktu yang dibutuhkan: sekitar 30 menit mengunduh. Dampaknya ke rasa main lebih
besar daripada gambar mana pun.
