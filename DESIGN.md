# Design Decisions — Rotasi Game Track (10 hari kerja)

Dokumen keputusan, bukan spesifikasi. Isinya cuma hal yang udah dikunci
plus hal yang masih terbuka. Kalau ada yang berubah, ubah di sini.

## Bentuk game

Satu ruangan per level. Tiga ruangan total.

**Fase 1 — Persiapan.** Waktu berhenti. Player punya jatah slot. Dia menaruh
mesin di ruangan, mengisi tiap mesin dengan rakitan komponen, dan menyisakan
sedikit slot untuk rapalan langsung.

**Fase 2 — Eksekusi.** ~20-30 detik. Musuh masuk dan bergerak sendiri. Mesin
menyala sesuai pemicunya. State ruangan berubah (basah, panas, uap, angin).
Player bisa menyelipkan rapalan langsung dari cadangan kecilnya.

**Fase 3 — Hasil.** Menang atau gagal. Gagal = semua dikembalikan utuh,
ruangan reset, retry instan. Tidak ada yang hilang, tidak ada grinding.

**Antar-ruangan (bagian risetnya).** Player dapat spell utuh sebagai hadiah,
lalu bisa MEMBONGKARNYA jadi komponen. Di sinilah dia menyadari dua spell
berbeda ternyata berbagi bagian yang sama, dan mulai merakit yang belum ada.

## Terkunci

**Bahasa:** GDScript. Iterasi tanpa compile, dokumentasi Godot GDScript-first,
cocok untuk sesi malam pendek. ECS tetap kelatih penuh — composition itu soal
struktur, bukan bahasa.

**Verb inti: MEMBONGKAR, bukan mengumpulkan.** Player dapat spell yang sudah
berfungsi, lalu memretelinya. Ini yang membedakan dari Noita. Efek samping yang
diinginkan: grammar-nya mengajarkan dirinya sendiri.

**Elemen lahir dari state, bukan dari tabel.** Uap muncul karena panas bertemu
lembab, bukan karena ada aturan `(api, air) -> uap`. Alasannya: benda ruangan
(kipas, genangan) jadi ikut bermain tanpa menulis aturan per-pasangan. Tumbuh
linier, bukan kuadratik. State dijaga kecil — beberapa angka per petak, bukan
simulasi fisika.

**Satu jenis mesin saja.** Variasi datang dari isinya, bukan dari mesinnya.
Mesin berjenis-jenis = diam-diam kembali ke inheritance (`MesinApi extends Mesin`).

**Rakitan tak berurut, waktu berurut.** `api+air+delay` sama saja dengan
`air+delay+api`. Urutan yang penting adalah urutan kejadian di ruangan, dan itu
diatur lewat delay. Alasan tambahan: komponen yang nempel di entity memang tak
berurut — itu sifat dasar ECS. Urutan rakitan bisa ditambahkan belakangan
sebagai lapisan di atas kalau perlu.

**Bukan tower defense.** Tidak ada gelombang bertumpuk, ekonomi antar-gelombang,
atau path building.

## Ongkos

**Slot = ongkos utama.** Efisien artinya: efek sama, slot lebih sedikit.

**Rapalan langsung (live):** slot terpisah yang lebih sedikit + ada waktu rapal.
Waktu rapal punya gigi karena di fase eksekusi musuh sedang bergerak.

**Damage itu opsional dan mahal.** Menyiapkan kondisi (bikin genangan, bikin
area lembab) itu murah. Memanennya yang bayar.

**Musuh bertransformasi, bukan menahan.** Basah -> menghantar listrik.
Kepanasan -> lari lebih cepat. Bukan "kebal api". Resistance bikin player
menghindari sesuatu; transformasi bikin player memanfaatkan sesuatu.

## Progresi kesulitan (urut dari yang paling disukai)

1. **Kurangi jatah slot.** Masalah mirip, budget lebih kecil. Player yang hafal
   mentok; yang paham bisa bikin efek sama dengan lebih sedikit bagian.
   Kesulitan yang isinya persis tema game ini.
2. Ubah bentuk ruangan (dua pintu, petak lebih sedikit, kipas yang menyusahkan).
3. Perilaku musuh baru yang mematahkan solusi lama.
4. Terakhir baru tambah jumlah musuh.

## Value yang dibawa: Independence & Resilience

Ini bukan tema naratif, tapi ada di struktur ekonomi game-nya.

**Independence**
- Tidak pernah menampilkan daftar resep -> player bikin hipotesis sendiri.
- Verb "membongkar" -> player menurunkan aturannya dari contoh, bukan dari manual.
- Rakitan buatan sendiri -> solusi dikarang, bukan dipilih dari menu.
- Progresi lewat pengurangan slot -> kemampuan datang dari PEMAHAMAN, bukan dari
  izin yang dikasih game. Tidak ada satu pun sumber kekuatan yang diberikan game;
  tidak ada unlock, level up, atau stat naik.

**Resilience**
- Gagal murah dan kebaca (<15 detik, tidak ada yang hilang) -> player bertahan di
  loop cukup lama untuk mengerti. Kegagalan jadi data, bukan hukuman.
- Kesulitan lewat pengurangan budget -> player dipaksa MEREVISI solusi yang tadinya
  sudah berhasil. "Solusi kamu jalan. Sekarang lakukan lagi dengan bahan lebih
  sedikit." Ketekunan yang produktif, bukan toleransi frustrasi.
- Catatan: grinding BUKAN mekanisme resilience. Grinding melatih toleransi
  frustrasi. Yang menghasilkan ketekunan adalah kegagalan yang murah dan terbaca.

**Tambahan murah supaya value-nya terlihat, bukan cuma terasa:**
1. Penghitung percobaan dibingkai sebagai usaha, bukan aib (model death counter
   Celeste). ~1 jam.
2. Ringkasan slot di akhir ruangan: "Solusi kamu: 6 slot. Batas: 8." Bikin
   efisiensi — dan berarti pemahaman — jadi angka yang kelihatan. ~1 jam.
3. Kalau ada hint: hint tidak boleh memberi jawaban, hanya menunjuk apa yang harus
   diperhatikan. ("Coba lihat apa yang terjadi ke lantai setelah spell air.")

## Platform

**Target: aplikasi macOS native.** Dikunci 1 September 2026.
Mesin: Apple Silicon (arm64), macOS 26.6.2, Xcode 26.6 tersedia.

Alasan: Godot jalan native di Apple Silicon dan export macOS itu bawaan — nol
toolchain tambahan, testing tinggal F5. Mouse cocok dengan desain (klik menaruh
mesin, hover melihat isi mesin, drag komponen). Academy tidak mewajibkan iOS/iPadOS.

Godot yang dipakai: build STANDAR (bukan .NET), karena bahasanya GDScript.

## Batas scope (jangan dilanggar tanpa alasan kuat)

- 5 komponen. Bukan lebih.
- 3 ruangan. Bukan 10.
- Slot mulai dari 8, mengecil tiap ruangan.
- 2-4 musuh di ruangan pertama.

Kalau sempat (bukan prioritas): item +1 slot, fitur player kasih nama sendiri
ke kombinasi temuannya.

## Prinsip yang gak boleh dilanggar

1. Aturan tidak pernah bohong. 5 rune dengan aturan konsisten kerasa lebih
   "berteori" daripada 30 rune yang aturannya bolong.
2. Jangan pernah tampilkan daftar resep. Penemuan dicatat player, bukan game.
3. Batasan lebih menarik daripada kekuatan (Sanderson's 2nd Law).
4. Grinding bukan resilience. Resilience = kegagalan murah + umpan balik yang
   kebaca. Target: < 15 detik dari gagal ke coba lagi.
5. Jangan sebut "senjata"/"rifle". Begitu jadi senjata, godaan nambah
   aim/recoil/ammo bikin ini diam-diam berubah jadi game aksi real-time.

## Komponen (draft, belum final)

- **Api** — elemen. Menaikkan suhu.
- **Air** — elemen. Menambah kebasahan.
- **Angin** — elemen. Dorongan area yang bertahan.
- **Delay** — pengatur waktu. Sumber semua urutan kejadian.
- **Gaya** — hentakan sesaat di satu titik. Damage adalah salah satu akibatnya,
  bukan definisinya. Bisa mendorong musuh ke genangan, melempar balik ke pintu.
  Mahal. Lulus tes "kapan player memilih untuk TIDAK memasangnya" — yaitu saat
  dia cuma mau menyiapkan kondisi.

Catatan: gaya dan angin sama-sama mendorong. Perannya harus dibedakan jelas
atau salah satu jadi mubazir. Arah: angin = dorongan area yang bertahan
(dari benda ruangan), gaya = hentakan sesaat (dari spell player).

## Penyaluran (menentukan DI MANA, bukan APA)

Minimal dua supaya jadi pilihan. Tiga kalau sempat:
- **Proyektil** — melesat ke depan, kena yang pertama disenggol.
- **Area** — meledak sebidang di sekitar mesin.
- **Bertahan** — nempel di petak beberapa detik, kena siapa pun yang lewat.
  Ini yang bikin jebakan terasa seperti jebakan.

## Masih terbuka

- [ ] Penyaluran itu komponen juga (makan slot) atau properti mesin?
- [ ] Pemicu mesin (kapan dia nyala) itu komponen juga atau setelan terpisah?
- [ ] Membongkar spell itu permanen (spell-nya hilang) atau bisa dibalik?
      Permanen bikin keputusannya berarti, tapi bisa terasa menghukum.
- [ ] Struktur project & arsitektur ECS (dibahas sesi berikutnya).

## Rencana sisa waktu (dibuat akhir hari ke-2, 2 September 2026)

Sisa 8 hari kerja. Perkiraan waktu tersedia ~30 jam (6 malam pendek @1,5 jam +
4 hari weekend @6 jam). WEEKEND YANG NANGGUNG PROJECT INI — kalau satu weekend
hilang, turun ke Tingkat 1 saja.

### Potongan scope yang disepakati

1. **Tiga ruangan -> satu ruangan, tiga percobaan.** Progresi lewat jatah slot
   (8 -> 6 -> 4), bukan lewat bikin ruangan baru. Ganti satu angka, bukan berjam-jam.
2. **Layar pembongkaran spell dibuang, verb-nya tetap hidup.** Panel samping
   menampilkan 2-3 spell jadi sebagai kumpulan komponen yang kelihatan isinya;
   player menarik komponen dari situ ke mesinnya. UI-nya sama dengan UI merakit,
   jadi nol tambahan, tapi momen "dua spell ini punya bagian yang sama" tetap ada.
3. **Musuh satu jenis, gerak lurus.** Tidak ada pathfinding.

Yang TIDAK dipotong: penghitung percobaan dan ringkasan slot. Murah, dan justru
mereka yang bikin value kebaca.

### Pembagian kerja

- **`sim/` 100% Xaviero** — semua system, komponen, logika. Ini yang sedang dipelajari.
- **`view/` + UI: Claude** — Control node, drag-and-drop, sinkronisasi sprite, juice.
  Alasannya: itu Godot plumbing, kategori yang sama dengan juice. Bisa paralel tanpa
  tabrakan file justru karena `sim/` tidak boleh tahu Godot ada.

### Peta hari

| Hari | Xaviero | Claude |
|---|---|---|
| 3 (Kam) | Runner system + system Delay | — |
| 4 (Jum) | Overlap + rantai Burn->Damaged->Health | — |
| Weekend 1 | System elemen (suhu/basah/uap) | Lapisan gambar + penempatan mesin |
| 5-6 (Sen-Sel) | Menyambungkan sistem, aturan menang/kalah | UI perakitan |
| 7-8 (Rab-Kam) | Retry, jatah slot, penghitung percobaan | Beresin UI |
| Weekend 2 | Art (11 gambar) + menyetel angka | Juice: partikel, shake, tween |
| 9-10 | Buffer, build .app, siapkan presentasi | Bantu build & export |

### Tingkat cadangan

- **Tingkat 1 (amankan dulu):** satu ruangan, satu jatah slot, tanpa progresi.
  Tetap menunjukkan ECS, sistem sihir, dan kedua value.
- **Tingkat 2 (kalau lancar):** progresi slot 8->6->4 + panel spell jadi.

Aturan: bikin Tingkat 1 JALAN UTUH dulu, baru menumpuk. Jangan mengerjakan semuanya
setengah-setengah bersamaan — itu cara tercepat sampai di hari ke-10 dengan sepuluh
hal yang semuanya 80%.

## Status (akhir hari ke-2)

- Godot 4.7.2 di /Applications, project di `challenge-6/`, renderer Compatibility.
- Struktur folder: `sim/` (murni, tanpa Godot), `sim/components/`, `sim/systems/`,
  `view/`, `assets/`.
- `sim/world.gd` SELESAI dan sudah dites: add_entity, attach/detach_component,
  entity_have_component, get_entities_with_comp (AND), clear_everything.
- `sim/Comp.gd` — konstanta nama komponen, supaya typo ketahuan editor.
- `view/main.gd` — scene bootstrap + tes World.

### Sisa kecil di world.gd
- Komentar baris 4 dan 18 masih menggambarkan struktur lama (array & nama entity).

### Pertanyaan terbuka berikutnya (hari ke-3)
- System itu class atau fungsi biasa?
- Siapa yang memegang daftar system dan memanggilnya tiap frame?
- Urutan jalannya system ditentukan di mana?
Setelah itu: system pertama = Delay (memaksa pakai detach, dan godaan callback
terbesar ada di situ).
