# Design — Rotasi Game Track

Deadline: **Kamis, 10 September 2026.** Presentasi Jumat 11.

Revisi 3 (3 September malam). Revisi 1 dan 2 membangun game bertahan berbasis
fase persiapan — dan itu **membunuh hook asli proyek ini**: "rune yang bisa
diefisiensikan atau disingkat" tidak berarti apa-apa kalau waktu berhenti saat
merakit. Pemendekan cuma punya gigi kalau merapal makan waktu dan ada yang
mengejar. Revisi ini memperbaiki itu.

---

# 1. Genre

**Aksi arena tampak atas dengan sistem rapalan kombinatorial.**

Tetangga terdekatnya: **Magicka** (antrian elemen, hasil emergen), **Hades**
(arena, mati, ulang), **Noita** (kombinasi yang mengejutkan perancangnya).

Bukan roguelite penuh — tidak ada prosedural, tidak ada meta-progression antar
run. Satu arena, gelombang bertingkat, mati dan ulang instan. Kalau nanti ada
waktu, run bertingkat bisa ditumpuk di atas ini tanpa membongkar apa pun.

---

# 2. Satu ronde

> Arena tampak atas. Player seorang penyihir. Musuh masuk bergelombang dan
> **mengejar player** — tidak ada yang perlu dilindungi selain diri sendiri.
>
> Merapal: tahan tombol rapal, tekan `1`/`2`/`3` untuk mengantrikan rune
> **api / air / angin**, lepas untuk melepaskan.
>
> Selama antrian terbuka, **waktu melambat** — momen "pencerahan" ala anime.
> Tapi perlambatannya **luntur**: makin lama ragu, makin cepat dunia kembali ke
> kecepatan normal, dan monster sudah di depan muka.
>
> Antrian yang panjang butuh waktu lepas yang lebih lama. Rapalan 3 rune
> meninggalkan player terbuka jauh lebih lama daripada 2 rune yang tepat.
>
> Mati = ulang instan, semuanya kembali utuh.

---

# 3. Sistem rapalan

## Tata bahasa: rune pertama menentukan bentuk, seluruh antrian menentukan isi

Ini yang bikin tiga rune terasa jauh lebih banyak dari tiga.

**Rune pertama = wujud:**

| Rune pertama | Wujudnya |
|---|---|
| Api | **peluru** yang melesat lurus |
| Air | **genangan** di lantai pada jarak tertentu |
| Angin | **kerucut** pendek dari badan player, mendorong |

**Seluruh rune di antrian = isinya:** tiap api menambah kerusakan, tiap air
menempelkan `Wet`, tiap angin menambah dorongan. Rune yang sama dua kali
memperbesar efeknya.

Hasilnya, dari tiga simbol:

| Antrian | Yang keluar |
|---|---|
| `api` | peluru api biasa |
| `api api` | peluru yang lebih sakit, lepasnya lebih lama |
| `api angin` | peluru yang membakar **dan** melempar mundur |
| `angin api` | kerucut api dari badan — **bahan sama, bentuk beda total** |
| `air api` | genangan yang membasahi **sekaligus** membakar — kombo klasik dalam satu rapalan |
| `angin air` | kerucut yang membasahi sekelompok musuh, disiapkan untuk peluru api berikutnya |

`api angin` dan `angin api` adalah momen "oh, urutannya ngaruh" — dan itu
penemuan pertama yang bikin player sadar ada tata bahasanya, bukan cuma daftar.

## Waktu rapal

```
cast_time = BASE + PER_RUNE * jumlah_rune        BASE = 0.25s, PER_RUNE = 0.25s
```

Waktu ini jalan di **kecepatan normal**, bukan diperlambat. Jadi rapalan panjang
= jendela terbuka yang panjang. Itu ongkos yang bikin pemendekan berarti.

## Perlambatan yang luntur

Selama antrian terbuka:

```
time_scale(t) = 1.0 - (1.0 - MIN_SCALE) * exp(-t / TAU)
MIN_SCALE = 0.12     TAU = 0.6 detik
```

- `t = 0` → 0.12 (dunia hampir berhenti, momen pencerahan)
- `t = 0.6` → 0.44
- `t = 1.2` → 0.72
- `t = 2.0` → 0.90 (praktis sudah normal)

Jadi player dapat sekitar **0,6 detik nyata yang benar-benar berharga**. Yang
tahu kombonya selesai di dalam jendela itu. Yang ragu-ragu keluar dari jendela
dan menghadapi monster di kecepatan penuh.

Dua angka itu (`MIN_SCALE`, `TAU`) adalah tuas rasa main utama. Disetel dengan
dimainkan, bukan ditebak.

**Kenapa luntur, bukan berhenti total:** kalau waktu berhenti, panel rapalan
jadi menu, dan panjang rapalan tidak ada ongkosnya lagi — persis kesalahan
revisi 1 dan 2.

## Tanpa mini-game terpisah

Antrian rune di bawah waktu yang meluntur **itu sendiri** sudah mini-game-nya:
ada input, ada tekanan waktu, ada kemahiran yang bisa naik. Mini-game terpisah
berarti game kedua yang harus dibangun dan dipoles, dan dia memutus player dari
pertarungan yang sedang berjalan.

---

# 4. Proficiency — dan garis yang tidak boleh dilewati

Player yang sering memakai kombinasi tertentu jadi mahir dengannya. Tapi
bentuk hadiahnya menentukan hidup-matinya value proyek ini:

| | Efek | Akibatnya |
|---|---|---|
| ❌ Proficiency → **damage naik** | grinding. Kekuatan diberikan game karena pengulangan | Membunuh independence. Player kuat karena mengulang, bukan karena paham |
| ✅ Proficiency → **lebih cepat merapal**, lalu boleh **diikat ke satu tombol** | Game mengakui apa yang sudah dibuktikan player | Spell-nya sama persis. Yang berubah cuma player |

**Aturan keras: proficiency tidak pernah mengubah apa yang spell lakukan.
Dia hanya mengubah seberapa cepat player bisa mengeluarkannya.**

Puncaknya: setelah cukup sering, kombinasi itu boleh **diikat ke satu tombol,
dengan nama yang player karang sendiri.** Rapalan 3 rune jadi satu ketukan.

Itu **chantless casting** dari fantasi hari pertama — dan dia tidak di-unlock
oleh game, dia **diperoleh dengan membuktikan**. Persis Ed di Fullmetal
Alchemist yang bisa transmutasi tanpa lingkaran karena dia sudah paham
lingkarannya.

Konsekuensi yang bagus: karena hadiahnya cuma kecepatan, **paham tetap
mengalahkan mengulang.** Orang yang spam `api api api api` dapat rapalan
4-rune yang cepat; orang yang paham pakai `air api` yang memang lebih pendek
sejak awal.

---

# 5. Teori yang harus ditemukan

Tetap sama, dan sekarang justru lebih tajam karena dipakai di bawah tekanan:

| Elemen | Kerjanya |
|---|---|
| **Api** | menyakiti apa pun yang menyentuh, berulang selama bersentuhan |
| **Air** | menempelkan `Wet` — melambat **50% selama 2 detik** |
| **Angin** | mendorong **menjauhi sumbernya** |

Tidak ada aturan `if api and air`. Yang lahir sendiri:

- Basahi dulu → musuh lambat → lebih lama di dalam api → dua kali lebih sakit
- Dorong ke dalam api → paparan ulang
- `air api` dalam satu genangan → basah dan terbakar di tempat yang sama

> **Kerusakan = seberapa lama musuh berada di dalam sesuatu yang menyakitkan.
> Semua hal lain cuma cara mengatur "seberapa lama" itu.**

Player yang paham menang dengan 2 rune. Yang tidak paham menghabiskan 4 rune,
merapal lebih lama, dan kena duluan. **Pemahaman terbayar sebagai kecepatan.**

---

# 6. MDA

## Mechanics — aturan yang ditulis

Antrian rune · rune pertama menentukan wujud · waktu rapal sebanding panjang
antrian · perlambatan yang luntur · api menyakiti · air memperlambat · angin
mendorong · musuh mengejar player lewat A\* · gelombang bertingkat · mati dan
ulang instan · proficiency menaikkan kecepatan, tidak pernah kekuatan.

## Dynamics — yang muncul saat dimainkan

- **Membasahi dulu, membakar kemudian** — ditemukan sendiri, tidak pernah
  diajarkan
- **Kiting sebagai alat, bukan pengecut** — mundur untuk membeli waktu rapal
- **Panik vs lancar** — pemula membeku di panel; yang mahir sudah melepas
  sebelum perlambatan luntur
- **Pemadatan** — kombinasi 4 rune yang berhasil pelan-pelan diganti 2 rune yang
  lebih tepat
- **Perbendaharaan pribadi** — tiap player berakhir dengan set kombinasi ikat
  yang berbeda, sesuai cara mainnya

## Aesthetics — rasa yang dikejar (dan yang sengaja tidak)

| Dikejar | Kenapa |
|---|---|
| **Discovery** (utama) | seluruh gamenya tentang menemukan bahwa kerusakan = waktu paparan |
| **Challenge** (utama) | tahu saja tidak cukup, harus bisa mengeluarkannya sebelum monster sampai |
| **Fantasy** (pendukung) | jadi penyihir yang **mengerti** sihirnya, bukan yang menghafal mantra |
| **Expression** (pendukung) | mengarang nama untuk kombinasi temuan sendiri |

Tidak dikejar: Fellowship (solo), Narrative (tidak ada cerita), Submission
(justru anti-grinding).

---

# 7. Value

**Independence** — tidak ada kekuatan yang diberikan game. Tidak ada damage
naik, tidak ada unlock. Satu-satunya yang tumbuh adalah kecepatan player
mengeluarkan apa yang sudah dia pahami.

**Resilience** — mati murah dan terbaca, ulang di bawah 5 detik, tidak ada yang
hilang. Kegagalan selalu bisa dijelaskan: rapalan kepanjangan, atau kombonya
salah untuk situasi itu.

Yang bikin terlihat: penghitung percobaan sebagai usaha (model Celeste),
ringkasan "rapalan terpanjang / terpendek yang kamu pakai", dan **tidak pernah
ada daftar resep di layar.**

---

# 8. Arena & musuh

**Satu arena tampak atas**, ada dinding untuk berlindung dan memutar. Ukuran
kira-kira 20x12 petak — cukup untuk kiting, cukup untuk terbaca sekali pandang.

**Musuh mengejar player** dengan A\*. Tidak ada kristal untuk sekarang. (Kristal
nanti = "player kedua tanpa `Velocity`" — komponen yang sama, tanpa kendali.
Karena itu dia bisa ditambahkan kapan saja tanpa membongkar apa pun.)

**Ulang jalur:** jalur dihitung ulang hanya kalau targetnya pindah petak —
target menempelkan komponen penanda, sistem A\* membaca lalu mencabutnya.
Bukan tiap frame.

**Gelombang:** 3-5 gelombang, jumlah dan kecepatan naik. Menang = semua
gelombang bersih. Kalah = player mati.

**Ada barang gratis di arena** — obor (sumber api), genangan (sumber air) —
supaya memanfaatkan lingkungan jadi jalan efisiensi yang tidak makan rune.

---

# 9. Tampilan & aset

**Logikanya tampak atas.** Sprite digambar dari **sudut 3/4** supaya terasa
2.5D — Hyper Light Drifter, Hades, Enter the Gungeon semuanya begitu. Player
melihat kedalaman, kodenya tidak tahu apa-apa soal itu. **Nol baris tambahan.**

2.5D sungguhan (isometrik, ketinggian) dipotong: itu ongkos presentasi, bukan
mekanik, dan tidak menambah satu pun keputusan buat player.

**Aset: cari yang gratis.** Keputusan sadar Xaviero — menggambar sendiri itu
ego, bukan tujuan rotasi. Tenaga dipindah ke mekanik. Kalau ternyata ada sisa
waktu, glyph rune saja yang digambar tangan (paling sering dilihat, paling
sedikit gambarnya).

---

# 10. Arsitektur (tidak berubah)

**GDScript, aplikasi macOS native.** Godot 4.7.2, renderer Compatibility.

| Lapisan | Menulis ke World? | Aturan |
|---|---|---|
| `sim/` | ya | pemilik aturan main. **Tidak boleh menyentuh Godot** |
| `view/renderer.gd` | tidak | cuma bertanya dan menggambar |
| lapisan input | ya | hanya lewat pintu depan sim, **tanpa aturan main** |

## Aturan ECS yang dipegang

- Entity cuma id kosong; yang menentukan perlakuan adalah komponen yang menempel
- Komponen = data. System = kelakuan, tanpa state antar frame (`static func`)
- **Ada-tidaknya komponen itu sendiri flag-nya**
- **Apa pun yang dibaca sebuah system, masukkan ke query-nya**
- **Komponen kejadian dikonsumsi di frame yang sama dia dibuat**
- System tidak pernah memanggil system lain — mereka bicara lewat World
- Urutan system ditulis eksplisit; hasil harus bisa diulang
- `duplicate()` tiap dictionary yang dipakai lebih dari sekali
- Archetype bukan tipe. **Jangan bikin pabrik turunan**
- Apa pun yang bisa diturunkan dari World, jangan disimpan di penghitung sendiri

Posisi pecahan, okupansi biner, `Position` = pojok kiri-atas, `Size` default
1x1, logika okupansi di satu fungsi.

**Catatan perlambatan waktu:** `time_scale` tidak boleh jadi variabel global
Godot. Dia komponen/keadaan di dalam `World`, dan `delta` yang dioper ke system
sudah dikalikan. Kalau tidak, keadaan bocor keluar World dan "ulang" berhenti
jadi satu baris.

---

# 11. Yang sudah jadi dan tetap terpakai

`World` · `DelaySystem` · `MoveSystem` · `LifetimeSystem` · `DeadSystem` ·
`FireContactSystem` → `BurnSystem` → `DamageSystem` → `InvulnerabilitySystem` ·
`MachineSystem` (jadi pelahir spell dari antrian) · `Spawn` · `renderer.gd`

`assembly_ui.gd` diparkir — penempatan mesin sebelum ronde sudah tidak ada.
Kodenya tetap disimpan; sebagian dipakai ulang untuk panel rapalan.

---

# 12. Rencana 6 hari

Scope ini **sengaja lebih besar dari yang aman.** Pengamannya bukan optimisme,
tapi checkpoint yang memotong **pada tanggalnya**, bukan saat sudah terlambat.

| Hari | Xaviero | Claude |
|---|---|---|
| **Jum 4** (~2j) | Player: gerak + `Health`. Komponen antrian rapalan | Input gerak, panel antrian rune, bar rapal |
| **Sab 5** (panjang) | A\* + musuh mengejar + menyerang player | Perlambatan waktu, kamera, umpan balik kena |
| **Min 6** (panjang) | Tata bahasa rapalan: rune pertama = wujud, sisanya isi | Wujud: peluru, genangan, kerucut |
| **Sen 7** (~2j) | `Wet` + perlambatan, dorongan angin, obor & genangan arena | Gelombang, layar menang/kalah |
| **Sel 8** (~2j) | Proficiency + ikat tombol + nama karangan player | Juice: partikel, shake, kilat kena |
| **Rab 9** (~2j) | Menyetel `MIN_SCALE`, `TAU`, damage, kecepatan musuh | Memasang aset gratis, polish |
| **Kam 10** | Buffer, build `.app`, presentasi | Bantu build & export |

## Checkpoint (pemotongan terjadwal)

- **Sabtu 5 malam — harus bisa dimainkan ujung ke ujung.** Player gerak, musuh
  mengejar, satu rune bisa dirapal, mati bisa diulang. Belum? **Tata bahasa
  urutan dipotong** — antrian jadi kumpulan tak berurut.
- **Senin 7 malam — tiga elemen dan tiga wujud jalan.** Belum? **Proficiency
  dan ikat tombol dipotong.**
- **Rabu 9 malam — feature freeze, tanpa kecuali.** Kamis khusus build dan
  presentasi.

## Tingkat cadangan

- **Tingkat 1 (wajib):** satu arena, player gerak, musuh mengejar, antrian rune
  dengan perlambatan luntur, tiga elemen, mati dan ulang. Ini sudah menunjukkan
  ECS, teori waktu paparan, dan kedua value.
- **Tingkat 2:** tata bahasa urutan (rune pertama = wujud), gelombang,
  obor & genangan arena.
- **Tingkat 3:** proficiency, ikat tombol bernama, uap.

**Tingkat 1 harus jalan utuh sebelum apa pun dari Tingkat 2 disentuh.**

## Yang dipotong

Fase persiapan · penempatan mesin sebelum ronde · ekonomi slot per ruangan ·
kristal · tampak samping · gravitasi · lantai bertingkat · isometrik sungguhan ·
mini-game rapalan terpisah · lebih dari tiga rune · prosedural · meta-progression
antar run.

## Refleksi (diisi Kamis, sebelum presentasi)

Kalau tidak kekejar: keberatan fitur, atau kurang disiplin? Jawab jujur.
