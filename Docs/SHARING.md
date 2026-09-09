# Round Robin Sharing — naskah 5 menit

## [10 detik] Value

> **Independence dan Resilience.**

Itu saja. Jangan dijelaskan di sini — penjelasannya ada di bagian berikutnya.

---

## [1 menit] Apa itu berhasil buat saya

> Berhasil itu **kalau saya bisa jelaskan kenapa setiap keputusan arsitektur
> diambil**, bukan kalau gamenya bagus.
>
> Latar belakangnya: saya pernah ikut tutorial bikin paint app macOS, dan saya
> biarkan AI menulis semua kodenya. Jadi, tapi saya tidak bisa menjelaskan
> satu pun keputusan di dalamnya. Saya tidak mau mengulang itu di bagian yang
> paling berharga.
>
> Jadi saya bagi dua dengan sengaja. Simulasi dan ECS-nya saya tulis sendiri —
> 22 system, 12 komponen, sekitar 1.500 baris. Lapisan tampilan dan juice saya
> serahkan, karena itu bukan yang sedang saya kuasai.
>
> Ukuran berhasilnya bukan "kelar", tapi: **kalau ada yang tanya kenapa
> komponen ini dipisah dari itu, saya punya jawabannya.**

---

## [1 menit] Hubungan deliverable dengan value

> Gamenya sendiri **tentang** dua value itu, bukan cuma dikerjakan dengan cara itu.
>
> **Independence:** tidak ada satu pun kekuatan yang diberikan game. Tidak ada
> unlock, tidak ada level up, tidak ada daftar resep di layar. Satu-satunya cara
> jadi lebih kuat adalah benar-benar paham sistem sihirnya.
>
> **Resilience:** mati itu murah dan terbaca. Ulang di bawah 5 detik, tidak ada
> yang hilang. Penghitung percobaan ditampilkan sebagai usaha, bukan sebagai
> kegagalan.
>
> Dan kemarin saya membuktikan sendiri bahwa itu bekerja: saya kalah berkali-kali,
> lalu **menemukan sendiri** bahwa rune air kalau ditaruh di slot pertama jadi
> alat penghadang. Tidak ada yang memberi tahu saya. Saya menemukannya justru
> karena kalahnya murah.

---

## [2 menit] WIP

Tunjukkan gamenya jalan. Sambil main, sebut ini:

> **Sistem sihirnya kombinatorial.** Tahan Shift, ketik J/K/L untuk mengantrikan
> rune api/air/angin, lepas untuk merapal. Waktu melambat selama antrian terbuka,
> tapi perlambatannya luntur — makin lama ragu, makin cepat dunia kembali normal.
>
> **Rune pertama menentukan WUJUD, seluruh antrian menentukan ISI.**
> Api = peluru satu target. Air = bola yang pecah jadi genangan. Angin = ledakan area.
>
> Jadi `api air` dan `air api` — bahan sama, urutan beda — menghasilkan spell
> yang berbeda total.
>
> **Dan tidak ada satu baris pun yang menyebut "genangan lava".** Itu lahir
> sendiri dari air-sebagai-wujud bertemu api-sebagai-muatan. 22 system saya tidak
> ada yang tahu apa itu fireball; mereka cuma tahu komponen.
>
> Kalau ditanya soal ECS: entity itu cuma angka. Yang menentukan perlakuan adalah
> komponen apa yang menempel. Nambah jenis serangan baru = nambah baris di tabel
> data, bukan nambah `if`.

---

## [1 menit] Lesson learned

Pilih **satu**, jangan tiga. Yang paling kuat:

> **Saya membawa asumsi mati melewati dua kali pivot tanpa sadar.**
>
> Di desain awal, gamenya soal memasang jebakan, dan teori intinya "kerusakan =
> berapa lama musuh berada di dalam sesuatu yang menyakitkan". Lalu desainnya
> berubah dua kali — jadi game aksi, tidak ada lagi jebakan.
>
> Tapi kalimat itu tetap saya tulis di dokumen, dan saya tetap membangun ke
> arahnya. Sampai saya duduk dan **main sendiri**, lalu sadar: membasahi musuh
> tidak membuatnya lebih cepat mati. Teorinya tidak pernah bisa berlaku.
>
> Pelajarannya: **dokumen desain tidak otomatis ikut berubah waktu desainnya
> berubah.** Dan cuma memainkannya yang bisa membuktikan itu — bukan membacanya
> ulang, karena membaca ulang cuma mengulang asumsi yang sama.

---

# Guiding questions untuk learning plan

1. **Bagaimana saya tahu sebuah mekanik benar-benar terasa oleh pemain, bukan
   sekadar sudah terimplementasi?** — Waktu rapal saya "ada" di dokumen dan di
   panel, tapi tidak ada satu pun kode yang menegakkannya. Baru ketahuan saat
   dimainkan.

2. **Kapan sebuah aturan lebih baik disimpan sebagai DATA daripada sebagai KODE?**
   — Tiap kali saya memindahkan aturan ke tabel, jumlah `if` berhenti tumbuh.
   Tapi saya belum bisa menyebut batasnya di mana.

3. **Apa yang membuat saya membawa asumsi mati melewati dua pivot tanpa sadar,
   dan bagaimana cara menangkapnya lebih awal lain kali?**

4. **Bagaimana membedakan "memotong scope" dari "menghindari yang sulit"?** —
   Saya memotong banyak hal minggu ini. Sebagian jelas benar; sebagian saya
   belum yakin.

---

# Reflections

**Apakah saya bisa menunjukkan value lewat karya?**
Bisa, dan di dua lapis. Gamenya sendiri tentang independence dan resilience.
Dan cara saya mengerjakannya juga: simulasi dan ECS-nya saya tulis sendiri,
justru karena pernah gagal dengan cara yang sebaliknya.

**Bagaimana menunjukkannya?**
Bukan lewat tema atau cerita, tapi lewat ekonomi gamenya. Tidak ada unlock,
tidak ada daftar resep, kalah itu murah. Itu keputusan struktural, bukan hiasan.

**Bagaimana rasanya?**
Momen paling memuaskan bukan waktu fiturnya jadi, tapi waktu saya main dan
menemukan strategi yang tidak pernah saya rancang.

**Ada revelation?**
Ada: desain yang bisa dinalar mengalahkan desain yang harus dihafal. Dan satu
lagi yang lebih tidak enak — dokumen bisa berbohong, dan cuma memainkannya yang
bisa membuktikan.

**Apa selanjutnya?**
Senin-Selasa aset, Rabu feature freeze, Kamis build dan presentasi.
