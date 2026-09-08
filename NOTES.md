# Catatan — utang yang sengaja ditunda

Hal-hal yang sudah diketahui tapi tidak dikerjakan sekarang, supaya tidak
mengganggu jalan ke deadline. Diisi saat ketemu, bukan saat sempat.

## Lunas (dulu ada di daftar kerja)

- ~~**Aqua tidak terasa.**~~ LUNAS. `Wet` masuk `TIMERS` dan dibaca
  `SpeedModifierSystem`, yang memotong dari `Speed.base` — bukan dari `value`,
  jadi dua efek berurutan tidak saling menumpuk dan kecepatannya selalu pulih.
- ~~**Ventus tidak terasa.**~~ LUNAS. Arah dorongan diisi `Inflict` saat
  menempel, dan `ImpulseSystem` menerapkannya meluruh kuadratik.
- ~~**`Comp.CHASE` dikomentari.**~~ LUNAS, musuh mengejar.
- ~~**`Speed.base` disiapkan tapi belum dipakai.**~~ LUNAS, lihat butir Aqua.

## Suara — sudah terpasang (9 September)

Lapisan pemutar ada di `view/sfx.gd`, peta bunyinya di ASSETS.md. Yang belum:
suara untuk dash dan langkah kaki (sengaja dilewat), dan `theme_menu.mp3` belum
dipakai karena belum ada layar menu.

## Penuntun rapalan pertama (9 September)

`view/onboarding.gd`. Satu langkah pada satu waktu, dibaca dari World, hilang
selamanya begitu satu spell dilempar. Legenda permanen di sudut tetap ada —
dia menjawab "apa tombolnya", penuntun menjawab "apa berikutnya".

## Guncangan terasa terlalu sering saat Aqua+Ignis (9 September)

Sebabnya bukan kekuatan guncangannya, tapi seberapa sering dia dipicu.
Rapalan aqua-dulu-ignis melahirkan GENANGAN yang membawa `Damaged`, dan
genangan itu bertahan 3 detik. Tiap musuh di dalamnya kena lagi tiap kali
`Invulnerable`-nya habis (0,5 detik), dan tiap kena memasang `HitStop` baru.
Empat musuh di satu genangan = guncangan tiap ~0,12 detik, jadi terasa
bergetar terus-menerus.

Ini gejala dari utang "kontak dinilai ulang tiap frame" di bawah, muncul
sebagai masalah rasa alih-alih masalah aturan.

Tiga pilihan, urut dari paling murah:
1. **Masa tenang guncangan** di `view/renderer.gd` — abaikan pemicu baru
   kalau `_shake` masih di atas ambang. Satu baris, tidak menyentuh sim.
2. Turunkan `SHAKE_HIT` saja (sekarang 6,0) dan biarkan yang mati tetap 10,0.
3. Jangan pasang `HitStop` untuk sumber yang bertahan (lane sim, lebih benar
   tapi butuh sumbernya tahu dia "bertahan" atau "sekali kena").

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

## Ditemukan saat migrasi ke class (6 September)

- ~~**`IntentSystem` dan mouse berebut `Facing`.**~~ LUNAS 7 September:
  penanda `FaceMovement` menentukan siapa yang menulis Facing. Musuh dari arah
  gerak, player dari mouse. Tidak ada lagi yang benar karena urutan node.
  (catatan aslinya:) `IntentSystem` menulis
  `face.x = ceili(intent.x)` tiap frame, sementara `player_input` menulis
  `Facing` dari posisi mouse tiap frame juga. Keduanya menimpa satu sama lain.
  Dan `ceili(-0.7)` = 0, jadi arah negatif hilang — bergerak ke kiri memberi
  facing.x = 0, bukan -1.
  Kemungkinan yang diinginkan: musuh mengambil Facing dari intent, player dari
  mouse. Kalau begitu, baris itu perlu disaring (misalnya hanya untuk entity
  tanpa `Player`), dan `signf` lebih tepat daripada `ceili`.

- **`view/assembly_ui.gd` sudah mati** (tidak ada di scene sejak revisi desain 3)
  dan isinya sekarang usang: masih membaca Position sebagai Dictionary. Aman
  karena tidak pernah dijalankan, tapi layak dihapus kalau sudah pasti tidak
  dipakai lagi untuk panel rapalan.

## Temuan playtest pertama (6 September, sore)

- **Waktu rapal tidak pernah ada.** CAST_BASE dan CAST_PER_RUNE cuma dipakai
  untuk menulis angka di panel; tidak ada system yang menunda apa pun. Ditambah
  root-saat-merapal sudah dibuang, rapalan 4 rune ongkosnya sama persis dengan
  1 rune: nol. Itu membunuh hook utama proyek dan bikin SPREAD tidak ada
  gunanya.
- **Suku konstan cast_time kemakan transit tangan.** Player memang harus pindah
  dari JKL ke mouse, jadi ~0.25 detik pertama gratis. Yang menggigit cuma bagian
  marginalnya. Karena itu CAST_BASE diturunkan dan CAST_PER_RUNE dinaikkan.
- **Bola air yang meleset hilang tanpa jejak.** on_expire-nya {Dead}, jadi
  genangan cuma bisa ditaruh di tempat musuh berada — padahal penolakan area
  justru soal menaruh sesuatu di jalur yang belum dilewati.
- **Musuh menumpuk di satu titik** setelah dikejar beberapa lama, jadi terlihat
  seperti satu musuh. Scatter acak cuma menambal gejala; penyebabnya penumpukan.
- **Ignis mengenai semua musuh yang bertumpuk** — seharusnya satu target, dan
  area jadi jatah Ventus sebagai wujud.

## Rencana juice (8 September — semuanya sudah terpasang)

Awalnya cuma ASET dan TATA LETAK, tanpa satu pun efek rasa-main. Ketujuhnya
sudah terpasang per 8 September sore. Urut dari dampak per menit tertinggi:

| # | Efek | Punya siapa | Kira-kira | Diturunkan dari | Status |
|---|---|---|---|---|---|
| 1 | **Kilat kena** — musuh berkedip putih sesaat saat terluka | Claude | 15 mnt | `Invulnerable.elapsed < 0.1` | ✅ |
| 2 | **Hit stop** — dunia membeku ~40ms saat kena keras | Xaviero | 20 mnt | `time_scale` di entity ronde | ✅ |
| 3 | **Guncang layar** — saat kena dan saat musuh mati | Claude | 20 mnt | sama seperti #1 | ✅ |
| 4 | **Ledakan mati** — percikan saat musuh lenyap | Claude | 30 mnt | id yang hilang antar frame | ✅ |
| 5 | **Bayangan dash** — 3 siluet tertinggal | Claude | 20 mnt | riwayat posisi di lapisan tampilan | ✅ |
| 6 | **Tampilan basah** — musuh ber-`Wet` jadi kebiruan + menetes | Claude | 15 mnt | komponen `Wet` | ✅ |
| 7 | **Kilat lepas** — cahaya sesaat di titik spell lahir | Claude | 10 mnt | `LaunchSpell` | ✅ |

**#2 itu yang paling kuat dan paling murah**, dan dia satu-satunya yang ada di
lane sim: saat sesuatu kena keras, `time_scale` dijatuhkan ke ~0.05 selama
40ms lalu kembali. Efek impact terkuat di game aksi 2D, dan nol frame animasi.

**Angka kerusakan melayang sengaja TIDAK masuk daftar** — skill game-ui-design
menyebutnya anti-pola "cluttered HUD", dan di layar yang sudah ada 8 musuh dia
menambah kebisingan tanpa memberi tahu apa pun yang belum terlihat dari bar HP.


### Catatan pemasangan (8 September)

Semua efek di atas hidup di `view/renderer.gd`, di blok "efek yang butuh
ingatan antar frame". Tiga hal yang menentukan bentuknya:

- **Tidak ada satu pun keadaan permainan yang disimpan di lapisan tampilan.**
  Yang disimpan cuma jejak: id musuh yang ada frame lalu, posisi terakhirnya,
  id spell yang sudah pernah dilihat. Kematian tidak punya komponen dan tidak
  perlu punya — musuh yang mati itu id yang ada frame lalu dan tidak ada
  sekarang.
- **Guncangan dipicu oleh `HitStop`, bukan kejadian tersendiri.** Dua-duanya
  jadi tidak bisa lepas sinkron, dan menyetel `HIT_STOP_TIME` di Tuning
  otomatis menyetel keduanya.
- **Semua efek pakai delta ASLI.** Guncangan yang ikut melambat saat hit stop
  justru hilang di saat dia paling dibutuhkan.

Guncangan masuk hanya lewat `screen_of_tile()`. `tile_at()` dan `world_at()`
sengaja tetap memakai margin mentah — itu pemetaan input, dan bidikan yang ikut
bergoyang mengubah guncangan dari rasa jadi cacat kontrol. `ui_origin()` juga
tidak ikut, supaya HUD diam saat lapangannya berguncang.

Kilat kena dan tampilan basah TIDAK mewarnai sprite musuhnya. Modulate itu
perkalian dan seni musuhnya hampir hitam, jadi dikali warna apa pun tetap
hitam. Kilat kena dibuat dari cahaya di belakang badan, basah dari genangan
kecil di kaki dan tetesan — dua-duanya di luar siluet gelapnya.

### Alat periksa

`tools/probe_launch.gd` — jalankan `godot --headless --path . --script
res://tools/probe_launch.gd`. Dia melempar Ventus ke delapan arah dan mencetak
ke mana pusat ledakannya mendarat relatif ke pusat pemain. Kolom terakhir harus
persis `facing x offset`. Dibuat waktu memburu bug arah angin, dan tetap
berguna tiap kali angka penempatan spell disentuh.

### Aset yang berguna kalau sempat (putih, transparan, 1024x1024)

- `impact.png` — percikan kecil untuk saat kena. Dipakai berkali-kali, diputar
  dan diwarnai lewat kode
- `death_splatter.png` — cipratan tinta untuk musuh yang lenyap
- Sisanya (basah, bayangan dash, kilat lepas) bisa prosedural, tidak perlu aset
