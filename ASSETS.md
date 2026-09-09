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


## Lantai, garis tepi musuh, dan icon (9 September)

### Lantai

`assets/background1.PNG` dan `background2.PNG` — goresan putih transparan di
kanvas 2048. Ditimpa ke warna dasar gelap, dua lapis dengan **skala ulangan
berbeda** (6 petak dan 9 petak). Angkanya sengaja bukan kelipatan: kalau sama,
keduanya berulang di jarak yang sama dan polanya justru jadi lebih kentara.

Pendekatan ubin bergambar penuh dibuang. Ubin selalu terbaca sebagai petak
berapa pun besar bloknya, karena setiap ubin punya batas dan mata menemukan
batas. Goresan transparan tidak punya batas — yang terlihat cuma guratannya,
dan latar gelap di bawahnya menyambung tanpa putus.

Dinding juga dibuang. Arena sekarang memakai tinggi layar penuh.

### Garis tepi musuh

Seni musuh 97% hitam pekat (kecerahan rata-rata 4 dari 255). `modulate` di
Godot itu PERKALIAN, jadi **tidak ada** nilai modulate yang bisa mencerahkan
piksel hitam. Versi lama menggambar spritenya berkali-kali dengan warna terang
untuk membuat rim, dan itu menghasilkan halo hitam di atas latar hitam —
sia-sia selama berhari-hari tanpa ada yang sadar.

Yang dipakai sekarang: gambar siluet putih yang dibangkitkan dari spritenya
sendiri.

    python3 tools/make_silhouette.py assets/enemies/

Menghasilkan `*_silhouette.png` — bentuk dan alpha sama persis, seluruh piksel
putih. Renderer menggambarnya di delapan arah pada skala YANG SAMA di belakang
badannya. Bukan sekali lebih besar: memperbesar menumbuhkan gambar dari titik
jangkarnya, dan jangkarnya ada di KAKI, jadi garisnya jadi tebal di kepala dan
hilang di kaki.

### Icon

`assets/icon.PNG` (2048x2048), dipasang di `project.godot` (`config/icon`) dan
`export_presets.cfg` (`application/icon`). Godot yang mengubahnya jadi `.icns`
saat ekspor.

### Impact/ dan Wet/

- `Impact/frame1_1.PNG` … `frame4_2.PNG` — empat frame, dua lapis tiap frame.
  Dipakai dua kali dengan ukuran berbeda: kecil dan cepat untuk kilat kena,
  besar dan lambat untuk ledakan mati. Satu bahasa visual, dan yang membedakan
  cuma ukuran dan lamanya — yang memang perbedaan sebenarnya.
  Frame dipilih dari **umur** lukanya, bukan dari jam dinding, supaya dua musuh
  yang kena di waktu berbeda tidak melangkah serempak.
- `Wet/wet1.PNG`, `wet2.PNG` — dua keadaan tetesan. Bergantian **sambil
  meluncur turun**: pergantian gambar saja terbaca sebagai kedipan, yang bikin
  dia terbaca sebagai air jatuh itu perpindahannya.

**Catatan penamaan:** `frame_1_2.PNG` diganti jadi `frame1_2.PNG` supaya
sepola dengan tujuh berkas lainnya, karena nama berkasnya dibentuk lewat
`"frame%d_%d.PNG"` — satu berkas yang beda pola berarti satu cabang khusus di
kode.

## Suara (9 September, dini hari)

Mentahnya di `assets/sfx/mentah/`, yang dipakai game di `assets/sfx/`.
**Godot tidak membaca `.m4a`** — cuma WAV, Ogg, MP3. Rekaman ponsel harus
dikonversi (`afconvert`, bawaan macOS; sudah dipanggil `sfx_prep.py`).

### Peta bunyi

| Kejadian di World | Berkas | Catatan |
|---|---|---|
| Rune masuk antrian | `rune_1..4` | nada naik per SLOT, bukan per jenis rune |
| `CastQueue.open` jadi true | `cast_riser` | |
| Entity ber-`Runes` lahir | `spell_fire` / `spell_water` / `cast_whoosh_1` | dipilih dari rune PERTAMA, sama seperti wujudnya |
| `Invulnerable` menempel di musuh | `impact_1..21` + `enemy_hurt_1` | 21 varian, dipilih acak |
| `Invulnerable` menempel di pemain | `player_hurt_1` | |
| id musuh baru muncul | `enemy_growl_1..4` | |
| id musuh hilang | `enemy_death_1` | |
| Ronde selesai | `round_win` / `round_lose` | musik dihentikan |
| Sepanjang ronde | `music_game` | loop diatur di `.import`, bukan di kode |

Semua dipicu dari **perubahan keadaan**, bukan dari panggilan. Sim tidak pernah
bilang "bunyikan ini" — dia cuma berubah, dan `view/sfx.gd` yang menyadari.
Konsekuensinya: kalau sim berubah, suaranya ikut, dan tidak ada satu pun tempat
di sim yang perlu tahu suara itu ada.

Suara kena dan hit stop dipicu keadaan yang SAMA (`Invulnerable` muncul,
`HitStop` muncul), jadi bunyi, kilat, dan bekunya dunia tidak pernah bisa lepas
sinkron.

**Pukulan yang mematikan cuma membunyikan `enemy_death`, bukan `impact`.**
Musuhnya sudah dihapus dalam tick fisika yang sama, jadi lapisan suara tidak
pernah sempat melihat `Invulnerable`-nya. Terdengar benar — kematian menimpa
kena — tapi ini kebetulan dari urutan sistem, bukan keputusan. Kalau nanti
keduanya harus bunyi, itu perlu jejak yang bertahan satu frame.

### Alat

| Perintah | Guna |
|---|---|
| `python3 tools/sfx_check.py <folder> --jenis kena\|rapal\|mati\|umum` | periksa teknis; TIDAK menilai cocok atau tidak |
| `python3 tools/sfx_prep.py <berkas> --nama X [--pisah N] [--maks-detik D]` | konversi, potong sunyi, samakan kekerasan, pecah kompilasi |
| `python3 tools/pitch.py <berkas> --nama X --langkah 0,2,4,7` | geser nada lewat resampling |
| `python3 tools/sfx_pick.py <folder> --kata a,b` | saring pustaka besar jadi satu berkas pratinjau |
| `python3 tools/make_rune_blips.py` | bangkitkan blip rune sintetis (cadangan, tidak dipakai) |

Kekerasan disamakan lewat **RMS**, bukan puncak. Menyamakan puncak bikin bunyi
pendek-tajam terdengar jauh lebih keras daripada bunyi panjang-halus walaupun
angkanya sama, karena telinga menilai rata-rata tenaga.
