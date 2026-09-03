# Design — Rotasi Game Track

Deadline: **Kamis, 10 September 2026.** Presentasi Jumat 11.

Revisi 2 (3 September malam). Revisi 1 kehilangan "dirapal langsung" dan
akibatnya jatuh jadi tower defense. Dokumen ini memperbaikinya.

---

# 1. Satu ronde, dari awal sampai habis

> Ruangan 14x9 dilihat dari atas: dinding, lantai, dua pintu di kiri, dan
> **kristal** di kanan yang harus dilindungi. Ada juga barang bawaan ruangan —
> sebuah **kipas** yang meniup ke satu arah, dan satu **genangan air**.
>
> Player mengendalikan seorang **penyihir** yang berdiri di dalam ruangan itu.
>
> **Fase persiapan.** Waktu berhenti. Player punya 8 slot. Dia berjalan
> keliling, menaruh mesin di petak lantai, memberi tiap mesin arah hadap, dan
> mengisinya dengan elemen: api, air, angin. Sisa slot yang tidak dipakai jadi
> cadangan untuk dirapal langsung nanti.
>
> **Fase eksekusi.** Space. Musuh masuk lewat pintu, satu-satu, tidak
> berbarengan. Mereka berjalan ke arah kristal — **dan mesin yang player taruh
> menghalangi jalan mereka**, jadi rutenya berubah. Player tetap bisa bergerak,
> dan bisa merapal langsung dari cadangannya. Sekitar 30 detik.
>
> **Hasil.** Satu musuh menyentuh kristal = kalah. Semua musuh mati = menang.
> R untuk mengulang — semuanya kembali utuh, instan.
>
> Ruangan yang sama diulang dengan jatah **8 slot, lalu 6, lalu 4.**

---

# 2. Kenapa ini bukan tower defense

Tiga pembeda, diurutkan dari yang paling langsung kelihatan orang lain — karena
sistem yang dalam tapi tidak terbaca itu gagal sebagai demo.

## a. Player ada di dalam ruangan

Tower defense tidak punya avatar. Di sini player punya badan: dia berjalan,
dia bisa merapal saat pertarungan berlangsung, dan dia bisa mati. Ini yang
menghidupkan tiga gaya main:

| Gaya | Caranya | Kenapa susah |
|---|---|---|
| Perancang murni | Habiskan semua slot untuk mesin sebelum mulai | Tebakan rutenya harus benar, tidak ada penyelamat |
| Campuran | Pasang yang pasti, sisakan cadangan untuk kejutan | Butuh dua-duanya |
| Improvisasi | Simpan hampir semua slot untuk dirapal langsung | Boros — rapalan langsung lebih mahal |

**Rapalan langsung lebih mahal daripada yang dipasang** (spontaneous vs
formulaic di Ars Magica). Yang mahal itu fleksibilitas, bukan damage.

## b. Musuh dituntun, bukan ditembaki

Di TD musuh lewat jalur tetap dan tower merusak yang lewat. Di sini
**mesin menghalangi jalan**, angin mendorong, air memperlambat. Kerjaan player
bukan menaruh damage di atas rute — tapi **membentuk rutenya**.

Ini juga yang bikin ruangan 14x9 berarti: harus ada minimal dua rute alternatif,
supaya menutup satu rute adalah keputusan, bukan cuma penempatan.

## c. Loop-nya optimasi, bukan bertahan

TD menaikkan kesulitan dengan gelombang yang makin besar. Di sini ruangan yang
sama diulang dengan **jatah yang makin kecil**. TD memuai; ini memampat.

---

# 3. Teori yang harus ditemukan player

Kalau cuma satu bagian dokumen ini yang bertahan, pertahankan yang ini.

## Tidak ada aturan reaksi khusus. Mata uangnya waktu paparan.

| Elemen | Yang dia lakukan | Ongkos |
|---|---|---|
| **Api** | menyakiti apa pun yang menyentuh, berulang selama bersentuhan | 1 slot |
| **Air** | menempelkan `Wet`: **melambat 50% selama 2 detik** | 1 slot |
| **Angin** | mendorong yang menyentuh, **menjauhi sumbernya** | 1 slot |

Tidak ada baris `if api and air: uap`. Tapi yang lahir sendiri:

- **Air lalu api** — musuh lambat 50%, jadi dua kali lebih lama di dalam api,
  jadi dua kali lebih sakit. Dua slot mengerjakan pekerjaan empat slot.
- **Angin lalu api** — musuh terdorong mundur, melewati api yang sama dua kali.
- **Mesin sebagai dinding** — rute dipaksa memutar, waktu di ruangan bertambah,
  semua sumber kerusakan jadi lebih lama bekerja.

Teorinya, yang tidak pernah ditulis di layar mana pun:

> **Kerusakan = seberapa lama musuh berada di dalam sesuatu yang menyakitkan.
> Semua hal lain cuma cara mengatur "seberapa lama" itu.**

Player bego pakai 6 slot untuk 6 api yang disebar. Player yang paham pakai
2 slot dan menang lebih cepat. Ruangan 4 slot memisahkan keduanya.

**Barang gratis ruangan** — kipas dan genangan — ada supaya efisiensi punya
sumber lain: memanfaatkan yang sudah ada tidak makan slot sama sekali.

---

# 4. Musuh

## Cara jalannya: bukan rel, bukan pathfinding

Tiap langkah, musuh mencoba bergerak **satu petak lebih dekat ke kristal**.
Kalau petak itu terhalang (dinding atau mesin), dia mencoba sumbu satunya.
Kalau dua-duanya terhalang:

> **musuh menyerang mesin yang menghalanginya.**

Aturan terakhir itu penting — dia yang membunuh strategi degeneratif "tembok
rapat". Menutup semua rute bukan kemenangan; itu cuma memindahkan pertarungan
ke mesin lo. Player harus **menyisakan rute**, dan itulah keputusan intinya.

Cukup beberapa baris. Tidak ada A*, tidak ada graf.

## Berapa musuh

Jawaban untuk keberatan yang benar: menambah musuh sejenis memang tidak
menambah apa-apa. Yang menambah adalah **kedatangan bertahap**.

**4 musuh, masuk satu per satu tiap 3 detik.** Musuh pertama basah dan mati
pelan; yang kedua masuk saat api masih menyala dan lantai masih basah; yang
keempat masuk ke ruangan yang keadaannya sudah berubah total. Yang menarik
bukan jumlahnya — tapi kenyataan bahwa **keadaan ruangan berkembang**.

HP awal: 100. Api: 20 kerusakan per detik paparan.

---

# 5. Peta

## Kenapa 14x9

Dua batasan yang menentukan:
- Harus muat **minimal dua rute berbeda** dari pintu ke kristal — kalau cuma
  satu rute, menghalangi tidak berarti apa-apa dan kita kembali jadi TD
- Harus **terbaca sekali pandang** tanpa geser layar, karena player harus bisa
  membaca seluruh papan saat merancang

14x9 pada petak 56px = 784x504, muat di jendela default. Rute terpendek sekitar
14 petak = ~14 detik pada kecepatan 1 petak/detik. Cukup panjang untuk dijebak,
cukup pendek untuk diulang berkali-kali.

## Isi peta

| Isi | Bisa dilewati | Bisa ditempati mesin |
|---|---|---|
| Lantai | ya | **ya** |
| Dinding | tidak | tidak |
| Pintu masuk (2, di kiri) | ya | tidak |
| Kristal (kanan) | — | tidak |
| Kipas (meniup satu arah tetap) | ya | tidak |
| Genangan air | ya | tidak |

Dinding disusun supaya ada dua koridor dari pintu ke kristal, dengan satu
persimpangan di tengah. Kipas ditaruh di salah satu koridor, genangan di
koridor satunya — supaya dua rute punya karakter berbeda dan player punya alasan
memilih mau menutup yang mana.

---

# 6. Tema

**Arkana, bukan sci-fi.** Alasannya bukan selera: seluruh gaya visual sudah
diputuskan sebagai **tinta monokrom ala catatan peneliti**, dan itu nyambung ke
penyihir yang membedah teori sihir, bukan ke teknologi.

**Musuh: makhluk, bukan manusia.** Alasan praktis — siluet makhluk sederhana
jauh lebih cepat digambar dan lebih mudah dibaca dalam gaya sketsa. Manusia
butuh proporsi yang benar untuk tidak terlihat aneh.

Glyph elemen **sengaja tidak swalayan**: jangan gambar api yang jelas-jelas api.
Gambar simbol yang artinya baru ketahuan setelah player melihat efeknya —
supaya memecahkan arti glyph ikut jadi bagian dari risetnya.

Nama game: belum. Diputuskan setelah ada yang bisa dimainkan.

---

# 7. Value

**Independence** — tidak ada satu pun sumber kekuatan yang diberikan game.
Tidak ada unlock, level up, atau stat naik. Ruangan 4 slot cuma bisa dilewati
kalau player benar-benar paham bahwa kerusakan itu waktu paparan.

**Resilience** — gagal murah dan terbaca (ulang < 5 detik, tidak ada yang
hilang), dan kesulitan naik dengan **memaksa merevisi solusi yang sudah
berhasil**, bukan dengan menambah musuh.

Yang bikin terlihat: penghitung percobaan dibingkai sebagai usaha (model
Celeste), ringkasan slot di akhir ronde, dan **tidak pernah ada daftar resep di
layar**.

---

# 8. Arsitektur (tidak berubah)

**GDScript, target aplikasi macOS native.** Godot 4.7.2, renderer Compatibility.

| Lapisan | Menulis ke World? | Aturan |
|---|---|---|
| `sim/` | ya | pemilik aturan main. **Tidak boleh menyentuh Godot** |
| `view/renderer.gd` | tidak | cuma bertanya dan menggambar |
| `view/assembly_ui.gd` | ya | input. Hanya lewat pintu depan sim, **tanpa aturan main** |

## Aturan ECS yang dipegang

- Entity cuma id kosong. Yang menentukan perlakuan adalah komponen yang menempel
- Komponen = data. System = kelakuan, tanpa state antar frame (`static func`)
- **Ada-tidaknya komponen itu sendiri flag-nya**
- **Apa pun yang dibaca sebuah system, masukkan ke query-nya**
- **Komponen kejadian dikonsumsi di frame yang sama dia dibuat**
- System tidak pernah memanggil system lain — mereka bicara lewat World
- Urutan system ditulis eksplisit. Hasil harus bisa diulang
- `duplicate()` tiap dictionary yang dipakai lebih dari sekali
- Archetype bukan tipe. **Jangan bikin pabrik turunan**
- Apa pun yang bisa diturunkan dari World, jangan disimpan di penghitung sendiri

## Konvensi posisi

Posisi pecahan, okupansi biner (menyentuh = di dalam). `Position` = pojok
kiri-atas, satuan petak. `Size` default 1x1. Logika okupansi hidup di **satu
fungsi** supaya keputusan pecahan bisa dibalik dalam 10 menit.

---

# 9. Yang sudah jadi

`World` · `DelaySystem` · `MoveSystem` · `LifetimeSystem` · `DeadSystem` ·
`FireContactSystem` → `BurnSystem` → `DamageSystem` → `InvulnerabilitySystem` ·
`MachineSystem` · `Spawn` · `renderer.gd` · `assembly_ui.gd`

**Semuanya selamat dari revisi ini.** Yang bertambah adalah system baru, bukan
bongkaran. Itu memang hadiah dari ECS.

---

# 10. Rencana 7 hari, dengan checkpoint keras

Scope ini **sengaja lebih besar dari yang aman**. Yang bikin itu tidak
berbahaya bukan optimisme, tapi tiga tanggal di bawah: pemotongan **dijadwalkan**,
bukan diharapkan. Di tiap checkpoint, yang belum jadi dipotong hari itu juga —
bukan ditunda.

| Hari | Xaviero | Claude |
|---|---|---|
| **Jum 4** (~2j) | Lingkaran ronde: fase, menang/kalah, retry | UI fase + pemilih arah hadap |
| **Sab 5** (panjang) | Peta: dinding, lantai, kristal, pintu. Musuh jalan menuju kristal + menyerang mesin kalau buntu | Penggambar peta, penempatan mesin ikut aturan petak |
| **Min 6** (panjang) | `Wet` + perlambatan, dorongan angin, kipas & genangan | Penyihir: gerak + rapalan langsung |
| **Sen 7** (~2j) | Penyaluran proyektil + arah hadap | Penghitung percobaan, ringkasan slot |
| **Sel 8** (~2j) | Menyetel 8/6/4 dengan mengukur, bukan menebak | Juice: partikel, shake, kilat kena |
| **Rab 9** (~2j) | Art (11 gambar, tinta monokrom) | Layar menang/kalah, memasang art |
| **Kam 10** | Buffer, build `.app`, presentasi | Bantu build & export |

## Checkpoint

- **Sabtu 5 malam — harus sudah bisa dimainkan ujung ke ujung.** Persiapan →
  eksekusi → menang/kalah → ulang, walaupun cuma api. Kalau belum: **penyihir
  dipotong**, kembali ke rancang-saja.
- **Senin 7 malam — tiga elemen dan penuntunan rute harus jalan.** Kalau belum:
  **proyektil dipotong**, cuma area.
- **Rabu 9 malam — feature freeze. Tanpa kecuali.** Apa pun yang belum jadi
  malam itu tidak akan pernah jadi. Kamis khusus build dan presentasi.

## Tingkat cadangan

- **Tingkat 1 (wajib):** satu ruangan, satu jatah slot, tiga elemen, penyaluran
  area, menang/kalah/retry. Tanpa penyihir. Ini sudah menunjukkan ECS, teori
  waktu paparan, dan kedua value.
- **Tingkat 2:** penyihir + rapalan langsung, penuntunan rute lewat mesin,
  progresi 8/6/4.
- **Tingkat 3:** proyektil, uap, kipas & genangan.

**Aturan:** Tingkat 1 harus **jalan utuh** sebelum apa pun dari Tingkat 2
disentuh. Kegagalan proyek 10 hari hampir selalu berbentuk sepuluh hal yang
semuanya 80%, bukan lima hal yang selesai.

## Yang tetap dipotong

Tampak samping · gravitasi · lantai bertingkat · homing · beberapa spell per
mesin · A* · lebih dari tiga elemen · layar pembongkaran terpisah · ekonomi
mata uang · upgrade senjata.

## Refleksi (diisi setelah selesai)

Kalau tidak kekejar, jawab jujur: keberatan fitur, atau kurang disiplin? Isi
di sini setelah Kamis, sebelum presentasi.
