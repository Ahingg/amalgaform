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

- **`Speed.base` sudah disiapkan tapi belum dipakai.** Wet nanti harus memotong
  dari `base`, bukan dari `value` — kalau memotong dari `value`, dua efek
  berurutan saling menumpuk dan kecepatan tidak pernah pulih.

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
