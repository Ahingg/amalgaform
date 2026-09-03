# Design — Rotasi Game Track

Deadline: **Kamis, 10 September 2026.** Dokumen ini ditulis ulang 3 September
malam, setelah sadar mekaniknya dibangun sebelum gamenya diputuskan.

Baca bagian 1 saja kalau cuma mau tahu gamenya apa. Sisanya aturan dan rencana.

---

# 1. Satu ronde, dari awal sampai habis

> Ruangan 12x8 dilihat dari atas. Ada pintu di kiri, kristal di kanan. Musuh
> akan jalan dari pintu ke kristal lewat jalur yang selalu sama.
>
> **Fase persiapan.** Waktu berhenti. Player punya 8 slot. Dia menaruh beberapa
> mesin di petak yang boleh ditempati, memberi tiap mesin arah hadap, dan
> mengisinya dengan elemen: api, air, angin.
>
> **Fase eksekusi.** Player menekan Space. Musuh masuk dan berjalan. Mesin
> menyala sesuai jeda masing-masing. Sekitar 20-30 detik.
>
> **Hasil.** Kalau satu musuh menyentuh kristal, kalah. Kalau semua musuh mati
> sebelum sampai, menang. Tekan R untuk mengulang — semuanya kembali utuh,
> tidak ada yang hilang, tidak ada yang perlu di-grind.
>
> Ruangan yang sama diulang tiga kali, dengan jatah **8 slot, lalu 6, lalu 4.**

Itu seluruh gamenya. Yang bikin dia bukan sekadar pasang jebakan ada di
bagian 2.

---

# 2. Teori yang harus ditemukan player

Ini inti gamenya. Kalau cuma satu hal yang dipertahankan dari seluruh dokumen
ini, pertahankan bagian ini.

## Tidak ada aturan reaksi khusus. Satu-satunya mata uang adalah waktu paparan.

Tiga elemen, masing-masing satu pekerjaan sederhana:

| Elemen | Yang dia lakukan |
|---|---|
| **Api** | menyakiti apa pun yang menyentuhnya, berulang selama masih bersentuhan |
| **Air** | menempelkan `Wet` — yang basah bergerak lebih lambat |
| **Angin** | mendorong apa pun yang menyentuhnya ke arah hadap mesin |

Tidak ada satu baris pun yang berbunyi "api + air = uap". Yang ada cuma tiga
aturan di atas. Tapi lihat apa yang lahir sendiri:

- **Air lalu api** — musuh basah jalannya lambat, jadi dia lebih lama di dalam
  api, jadi kena lebih banyak. Dua slot mengerjakan pekerjaan empat slot.
- **Angin lalu api** — musuh terdorong mundur, melewati api yang sama dua kali.
- **Air + angin + api** — lambat *dan* terdorong mundur: paparan maksimum.

Player tidak pernah diberi tahu ini. Dia mengamati bahwa air sebelum api
membunuh lebih cepat daripada api saja, lalu bertanya kenapa, lalu sampai pada
kalimat yang jadi seluruh teorinya:

> **Kerusakan = seberapa lama musuh berada di dalam sesuatu yang menyakitkan.
> Semua elemen lain cuma cara mengatur "seberapa lama" itu.**

Begitu dia paham kalimat itu, ruangan dengan 4 slot yang tadinya mustahil jadi
bisa. Itu momen yang dikejar seluruh proyek ini.

**Kenapa desainnya begini:** kalau reaksi ditulis sebagai tabel pasangan, player
cuma bisa menghafal. Kalau lahir dari state yang saling menumpuk, player bisa
**menalar** — dan bisa menebak kombinasi yang belum pernah dia coba. Itu beda
antara resep dan teori.

## Uap — bonus, kerjakan hanya kalau sempat

Kalau petak menampung api dan air sekaligus, muncul uap: area yang bertahan
lebih lama dari dua sumbernya dan memperlambat apa pun di dalamnya. Ini satu
fenomena eksplisit, dan dia masuk daftar "kalau sempat", bukan syarat.

---

# 3. Keputusan yang dikunci (dan yang dipotong)

## Sudut pandang: tampak atas. Terkunci.

Tampak samping berarti gravitasi, lompat, dan ketinggian — tiga sistem baru
yang tidak menambah apa pun ke teori di bagian 2. **Tidak ada gravitasi**,
karena di tampak atas dia tidak berarti apa-apa.

## Arena: satu ruangan. Tidak ada lantai bertingkat.

Bertingkat berarti perpindahan level, keadaan antar lantai, dan tata ruang
berkali lipat. Progresi datang dari **jatah slot yang mengecil** (8 → 6 → 4),
bukan dari ruangan baru. Ruangan yang sama, budget berbeda: player yang cuma
hafal akan mentok, player yang paham akan lewat. Itu justru pengukur pemahaman
yang lebih jujur daripada level baru.

## Mesin: apa gunanya, dan kenapa dia punya posisi

Ini lubang yang bikin dokumen ini ditulis ulang. Jawabannya: **mesin menentukan
dari mana dan ke arah mana efeknya keluar.** Karena itu dia punya `Position`
**dan** arah hadap.

Dua cara penyaluran:

| Penyaluran | Yang terjadi | Posisi mesin berarti apa |
|---|---|---|
| **Area** | efek muncul di petak mesin dan bertahan beberapa detik | di mana efeknya berada |
| **Proyektil** | efek melesat ke arah hadap sampai kena sesuatu | dari mana dan ke mana |

Tanpa arah hadap, angin tidak punya arti (mendorong ke mana?) dan proyektil
tidak mungkin. Dengan arah hadap, penempatan jadi keputusan sungguhan.

**Homing dipotong.** Menarik, tapi tidak menambah apa pun ke teori waktu paparan.

## Satu mesin = satu resep. Bukan beberapa spell per mesin.

Ide "satu mesin menampung 3-4 spell" itu sah, tapi dipotong: **urutan waktu
sudah bisa didapat dari beberapa mesin dengan jeda berbeda.** Menaruh mesin air
berjeda 1 detik dan mesin api berjeda 2 detik menghasilkan urutan yang sama,
tanpa lapisan baru di data, di `MachineSystem`, dan di UI.

Kalau nanti terasa kurang, lapisan itu bisa ditambahkan tanpa membongkar apa pun
— tapi jangan sekarang.

## Kedalaman dari sedikit komponen — dari mana datangnya

Kekhawatiran "komponennya cuma tiga, apa nggak dangkal" terjawab bukan dengan
menambah elemen, tapi dengan empat sumbu yang sudah ada:

1. **Urutan waktu** — jeda tiap mesin berbeda, jadi player mengarang urutan
2. **Tempat dan arah** — petak mana, menghadap ke mana
3. **Penyaluran** — area atau proyektil
4. **Keadaan bertumpuk** — basah, terdorong, dan efeknya ke waktu paparan

Tiga elemen dengan empat sumbu itu ruang yang jauh lebih besar daripada delapan
elemen tanpa sumbu.

## Ongkos slot

- **Menaruh mesin: gratis.** Jumlah mesin dibatasi petak yang boleh ditempati,
  bukan slot. Mengecas mesin itu mengecas dua kali untuk hal yang sama, karena
  resep di-key oleh nama komponen — satu mesin tidak mungkin punya dua `Fire`.
- **Tiap elemen di dalam resep: 1 slot.**
- **Penyaluran: gratis.**

Jatah per percobaan: **8, lalu 6, lalu 4.** Angka ini disetel setelah reaksinya
jalan, dengan cara: selesaikan ruangan pakai cara bodoh, catat berapa slot; pakai
cara pintar, catat berapa. Angka bodoh jadi jatah pertama, angka pintar jadi
jatah terakhir. Jangan ditebak sebelum ada yang bisa diukur.

## Musuh

Satu jenis. Jalur tetap dari pintu ke kristal. Kecepatan tetap (bisa berubah
hanya karena `Wet` atau dorongan angin — supaya player tetap bisa menalar).
2-4 musuh per ronde. Tidak ada pathfinding.

---

# 4. Value yang dibawa

**Independence** dan **Resilience**, dan keduanya ada di ekonominya, bukan di
temanya.

**Independence** — tidak ada satu pun sumber kekuatan yang diberikan game.
Tidak ada unlock, tidak ada level up, tidak ada stat naik. Ruangan ketiga cuma
punya 4 slot; satu-satunya cara lewat adalah benar-benar mengerti bahwa
kerusakan itu waktu paparan. Kemampuan datang dari pemahaman, bukan dari izin.

**Resilience** — gagal harus murah dan terbaca: ulang dalam hitungan detik,
tidak ada yang hilang. Dan kesulitan naik dengan cara **memaksa merevisi solusi
yang tadinya sudah berhasil** ("solusimu jalan; sekarang lakukan lagi dengan
bahan lebih sedikit"), bukan dengan menambah musuh.

Grinding bukan mekanisme resilience — itu melatih toleransi frustrasi. Yang
menghasilkan ketekunan adalah kegagalan yang murah dan terbaca.

**Yang bikin value ini terlihat, bukan cuma terasa:**
- Penghitung percobaan dibingkai sebagai usaha, bukan aib (model Celeste)
- Ringkasan slot di akhir ronde: "Solusimu: 6 slot. Batas: 8."
- Tidak pernah ada daftar resep di layar. Kalau ada hint, dia cuma menunjuk apa
  yang harus diperhatikan, tidak pernah memberi jawaban

---

# 5. Arsitektur (sudah jalan, tidak berubah)

**GDScript. Target aplikasi macOS native.** Godot 4.7.2, renderer Compatibility.

Tiga lapisan, dan batasnya keras:

| Lapisan | Boleh menulis ke World? | Aturannya |
|---|---|---|
| `sim/` | ya | pemilik seluruh aturan main. **Tidak boleh menyentuh Godot** |
| `view/renderer.gd` | tidak | cuma bertanya dan menggambar |
| `view/assembly_ui.gd` | ya | input. Menulis hanya lewat pintu depan sim (`Spawn.*`), dan **tidak boleh memuat aturan main** |

Alasan `sim/` tidak boleh menyentuh Godot: kalau ada state yang hidup di luar
`World`, "ulang" berhenti jadi satu baris. Semua yang bisa berubah harus di
dalam World, supaya reset = buang World, bikin baru.

## Aturan ECS yang sudah dipegang

- Entity itu cuma id kosong. Yang menentukan perlakuan adalah **komponen apa
  yang menempel**, bukan id-nya
- Komponen = data. System = kelakuan. System tidak menyimpan state antar frame
  (dipaksa lewat `static func`)
- **Ada-tidaknya komponen itu sendiri adalah flag-nya.** Jangan bikin boolean
  untuk sesuatu yang sudah dijawab oleh keberadaan komponen
- **Apa pun yang dibaca sebuah system, masukkan ke query-nya.** Query itulah
  cara mengeceknya
- **Komponen kejadian harus dikonsumsi di frame yang sama dia dibuat.** Kalau
  ada system yang melewatinya tanpa mencabut, kejadian itu jadi bom waktu
- System tidak pernah memanggil system lain. Mereka berkomunikasi lewat World:
  satu menempelkan komponen, yang lain membacanya
- Urutan pemanggilan system adalah keputusan desain yang ditulis eksplisit,
  bukan kebetulan. Hasil harus bisa diulang — itu syarat mati untuk loop riset
- Cetakan tidak boleh dipakai langsung sebagai barang jadi. `duplicate()` tiap
  kali sebuah dictionary dipakai lebih dari sekali
- Archetype (`Spawn.*`) bukan tipe. **Jangan pernah bikin pabrik turunan**
  (`Spawn.fast_enemy`, `Spawn.armored_enemy`) — itu inheritance lewat pintu
  belakang. Pabrik memberi bentuk awal, sisanya ditumpuk di pemanggil
- Apa pun yang bisa diturunkan dari World, jangan disimpan di penghitung sendiri

## Konvensi posisi

Posisi pecahan, **okupansi biner**: kalau badan menyentuh sebuah petak,
seberapa pun sedikitnya, dia dianggap di petak itu. Tidak ada persentase.

- `Position` = **pojok kiri-atas**, satuan petak
- `Size` default 1x1
- Petak tersentuh = `floori(x)` sampai `ceili(x + w) - 1`
- Logika okupansi hidup di **satu fungsi** (`Helper`), supaya keputusan pecahan
  bisa dibalik dalam 10 menit kalau ternyata merepotkan

---

# 6. Yang sudah jadi

- `World` — penyimpanan komponen per jenis, query AND, reset satu panggilan
- `DelaySystem`, `MoveSystem`, `LifetimeSystem`, `DeadSystem`
- `FireContactSystem` → `BurnSystem` → `DamageSystem` → `InvulnerabilitySystem`
- `MachineSystem` — melahirkan entity dari resep
- `Spawn` — archetype `enemy` dan `machine`
- `renderer.gd` — grid, entity, bar HP, bar delay, kedip i-frame, badge komponen
- `assembly_ui.gd` — taruh mesin, rakit resep, hitung slot

**Semua di atas selamat dari perubahan desain ini.** Yang berubah cuma isi
resep, ongkos slot, dan tata ruangan — data, bukan system. Itu memang hadiah
dari ECS: proyek ini bukan satu game, tapi mesin untuk mencoba banyak game.

---

# 7. Rencana 7 hari

| Hari | Xaviero | Claude |
|---|---|---|
| **Jum 4** (~2j) | Lingkaran ronde: fase persiapan/eksekusi, menang/kalah, retry | UI fase + pemilih arah hadap |
| **Sab 5** (panjang) | `Wet` + perlambatan, dorongan angin | Kristal, pintu, petak yang boleh ditempati |
| **Min 6** (panjang) | Jalur musuh + gelombang, penyaluran proyektil | Penghitung percobaan, ringkasan slot |
| **Sen 7** (~2j) | Menyetel tiga jatah slot dengan mengukur, bukan menebak | Juice: partikel, shake, kilat kena |
| **Sel 8** (~2j) | Menyeimbangkan angka, memperbaiki yang aneh | Layar menang/kalah |
| **Rab 9** (~2j) | Art (11 gambar, tinta monokrom) | Memasang art, polish |
| **Kam 10** | Buffer, build `.app`, siapkan presentasi | Bantu build & export |

## Tingkat cadangan

- **Tingkat 1 — amankan dulu:** satu ruangan, satu jatah slot, api + air + angin,
  penyaluran area saja, menang/kalah/retry. Ini sudah menunjukkan ECS, teori
  waktu paparan, dan kedua value.
- **Tingkat 2:** progresi slot 8 → 6 → 4, penyaluran proyektil, penghitung
  percobaan.
- **Tingkat 3 — kalau ajaib:** uap, panel spell jadi yang bisa dibongkar.

**Aturan:** bikin Tingkat 1 **jalan utuh** dulu, baru menumpuk. Jangan pernah
mengerjakan semuanya setengah-setengah bersamaan.

## Yang dipotong, supaya tidak dipikirkan lagi

Tampak samping · gravitasi · lantai bertingkat · homing · beberapa spell per
mesin · pathfinding · lebih dari tiga elemen · layar pembongkaran spell terpisah
· ekonomi mata uang · upgrade senjata.

---

# 8. Yang masih milik Xaviero untuk diputuskan

1. **Angin mendorong ke arah hadap mesin, atau menjauh dari sumbernya?**
   Berpengaruh ke seberapa rumit UI arah hadap.
2. **Musuh basah melambat berapa persen?** Ini tuas yang menentukan seberapa
   besar hadiah dari menemukan teorinya. Terlalu kecil, penemuannya tidak
   terasa; terlalu besar, api saja jadi tidak berguna.
3. **Berapa musuh dan berapa HP-nya** di ronde pertama.
4. **Nama gamenya.**
