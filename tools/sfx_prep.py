#!/usr/bin/env python3
"""
Menyiapkan rekaman mentah jadi efek suara yang siap dipakai game:
buang DC, potong sunyi di depan-belakang, samakan kekerasan, beri fade
mikro, dan (kalau diminta) pecah satu berkas jadi beberapa suara.

Kenapa keempatnya sekaligus, bukan satu-satu: rekaman mentah selalu kena
keempatnya, dan memperbaikinya satu-satu berarti membuka berkas yang sama
empat kali.

Kekerasan disamakan lewat RMS, bukan puncak. Menyamakan puncak bikin suara
pendek-tajam terdengar jauh lebih keras daripada suara panjang-halus walaupun
angkanya sama, karena telinga menilai rata-rata tenaga, bukan titik tertinggi.
Puncak tetap dijaga sebagai atap supaya tidak ada yang mentok.

Dekode m4a/mp3 lewat `afconvert` (bawaan macOS). Selain itu stdlib saja.

Pakai:
    python3 tools/sfx_prep.py rekaman.m4a --nama monster_growl_1
    python3 tools/sfx_prep.py whoosh.mp3 --nama cast_whoosh --pisah 4
    python3 tools/sfx_prep.py rekaman/ --keluar assets/sfx
"""
import argparse
import array
import math
import os
import struct
import subprocess
import sys
import tempfile
import wave

RMS_TARGET_DB = -18.0   # kekerasan yang dituju
PUNCAK_ATAP_DB = -1.0   # tidak boleh lewat ini
AMBANG_SUNYI = 0.05     # relatif terhadap puncak, sama seperti sfx_check
JEDA_MIN_MS = 120.0     # jeda lebih pendek dari ini bukan batas antar suara
POTONG_MIN_DETIK = 0.18 # potongan lebih pendek dari ini bukan suara, cuma letupan
PREROLL_MS = 5.0        # sisa sunyi di depan, supaya serangannya tidak terpotong
FADE_MS = 4.0           # fade mikro: tanpa ini tiap potongan bunyi "klik"


def db_ke_lin(d):
    return 10.0 ** (d / 20.0)


def dekode(path):
    """Apa pun formatnya -> WAV mono 44.1k 16-bit."""
    if path.lower().endswith(".wav"):
        return path, None
    tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    tmp.close()
    r = subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16@44100", "-c", "1",
                        path, tmp.name], capture_output=True)
    if r.returncode != 0:
        os.unlink(tmp.name)
        raise RuntimeError("afconvert gagal: %s" % r.stderr.decode()[:200])
    return tmp.name, tmp.name


def baca(path):
    with wave.open(path, "rb") as w:
        n, rate, ch, width = (w.getnframes(), w.getframerate(),
                              w.getnchannels(), w.getsampwidth())
        raw = w.readframes(n)
    if width != 2:
        raise ValueError("hanya 16-bit; ubah dulu lewat afconvert")
    s = array.array("h", raw)
    if sys.byteorder == "big":
        s.byteswap()
    if ch > 1:
        s = [sum(s[i:i + ch]) / float(ch) for i in range(0, len(s) - ch + 1, ch)]
    x = [v / 32768.0 for v in s]
    return x, rate


def tulis(path, x, rate):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b"".join(
            struct.pack("<h", max(-32768, min(32767, int(v * 32767.0)))) for v in x))


def potong_sunyi(x, rate):
    puncak = max((abs(v) for v in x), default=0.0)
    if puncak <= 0.0:
        return x
    batas = puncak * AMBANG_SUNYI
    a = 0
    while a < len(x) and abs(x[a]) < batas:
        a += 1
    b = len(x) - 1
    while b > a and abs(x[b]) < batas:
        b -= 1
    pre = int(rate * PREROLL_MS / 1000.0)
    return x[max(0, a - pre):b + 1]


def fade(x, rate):
    n = int(rate * FADE_MS / 1000.0)
    n = min(n, len(x) // 2)
    for i in range(n):
        f = i / float(n)
        x[i] *= f
        x[len(x) - 1 - i] *= f
    return x


def normalkan(x):
    n = len(x)
    if n == 0:
        return x
    rms = math.sqrt(sum(v * v for v in x) / n)
    if rms <= 1e-9:
        return x
    g = db_ke_lin(RMS_TARGET_DB) / rms
    puncak = max(abs(v) for v in x)
    # Atap puncak menang atas target RMS. Kalau tidak, suara dengan satu
    # hentakan tajam akan digeber sampai mentok demi mengejar rata-rata.
    if puncak * g > db_ke_lin(PUNCAK_ATAP_DB):
        g = db_ke_lin(PUNCAK_ATAP_DB) / puncak
    return [v * g for v in x]


def buang_dc(x):
    if not x:
        return x
    m = sum(x) / len(x)
    return [v - m for v in x]


def pecah(x, rate, jumlah):
    """Pecah jadi `jumlah` suara, dipotong di JEDA SUNYI TERPANJANG.

    Versi pertama alat ini menggabung blok dengan jeda terpendek berulang kali,
    dan hasilnya beberapa serpihan 20 md: satu letupan kecil yang jauh dari
    yang lain tidak pernah kebagian digabung, tapi tetap dihitung satu suara.

    Yang benar kebalikannya — cari jeda terpanjang, potong di situ. Jeda
    terpanjang memang batas antar suara; jeda pendek itu napas di dalam satu
    suara, dan memotong di sana membelah suaranya sendiri.
    """
    puncak = max((abs(v) for v in x), default=0.0)
    if puncak <= 0.0 or jumlah <= 1:
        return [x]
    batas = puncak * 0.06
    jendela = max(1, int(rate * 0.01))

    keras = []
    for i in range(0, len(x) - jendela + 1, jendela):
        keras.append(max(abs(v) for v in x[i:i + jendela]) >= batas)

    # Jeda sunyi DI ANTARA dua bagian berbunyi. Sunyi di ujung tidak dihitung:
    # itu bukan batas, itu cuma sisa rekaman.
    mulai = 0
    while mulai < len(keras) and not keras[mulai]:
        mulai += 1
    henti = len(keras) - 1
    while henti > mulai and not keras[henti]:
        henti -= 1

    jeda = []
    i = mulai
    while i <= henti:
        if keras[i]:
            i += 1
            continue
        j = i
        while j <= henti and not keras[j]:
            j += 1
        jeda.append((j - i, i, j))
        i = j

    minimal = JEDA_MIN_MS / 1000.0 * rate / jendela
    jeda = [g for g in jeda if g[0] >= minimal]
    jeda.sort(reverse=True)
    potong = sorted((a + b) // 2 for _, a, b in jeda[:jumlah - 1])

    batas_sampel = [mulai * jendela] + [p * jendela for p in potong] \
        + [min(len(x), (henti + 1) * jendela)]
    keluar = []
    for k in range(len(batas_sampel) - 1):
        keluar.append(x[batas_sampel[k]:batas_sampel[k + 1]])
    return keluar


def batasi(x, rate, maks_detik):
    """Potong di panjang maksimum, dengan fade keluar supaya tidak terpenggal."""
    n = int(rate * maks_detik)
    if maks_detik <= 0.0 or len(x) <= n:
        return x
    x = x[:n]
    ekor = min(len(x) // 3, int(rate * 0.12))
    for i in range(ekor):
        x[len(x) - 1 - i] *= i / float(ekor)
    return x


def olah(path, nama, keluar_dir, jumlah_pisah, maks_detik):
    dec, tmp = dekode(path)
    try:
        x, rate = baca(dec)
    finally:
        if tmp:
            os.unlink(tmp)

    x = buang_dc(x)
    bagian = pecah(x, rate, jumlah_pisah) if jumlah_pisah > 1 else [x]

    siap = []
    for p in bagian:
        p = potong_sunyi(p, rate)
        p = batasi(list(p), rate, maks_detik)
        p = normalkan(p)
        p = fade(list(p), rate)
        # Letupan pendek dibuang, bukan disimpan sebagai berkas bernomor. Kalau
        # tidak, satu napas yang kelewat ikut jadi "suara" dan nanti benar-benar
        # diputar sebagai geraman.
        if len(p) < int(rate * POTONG_MIN_DETIK):
            continue
        siap.append(p)

    # Penomoran dilakukan SETELAH penyaringan, supaya nomornya tidak bolong.
    hasil = []
    for i, p in enumerate(siap):
        akhiran = "" if len(siap) == 1 else "_%d" % (i + 1)
        out = os.path.join(keluar_dir, "%s%s.wav" % (nama, akhiran))
        tulis(out, p, rate)
        hasil.append((out, len(p) / float(rate)))
    return hasil


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("target", help="berkas atau folder")
    ap.add_argument("--nama", default="", help="nama keluaran tanpa ekstensi")
    ap.add_argument("--pisah", type=int, default=1, help="pecah jadi berapa suara")
    ap.add_argument("--maks-detik", type=float, default=0.0,
                    help="potong di panjang ini, dengan fade keluar (0 = biarkan)")
    ap.add_argument("--keluar", default="challenge-6/assets/sfx")
    a = ap.parse_args()

    os.makedirs(a.keluar, exist_ok=True)
    berkas = []
    if os.path.isdir(a.target):
        for n in sorted(os.listdir(a.target)):
            if n.lower().endswith((".wav", ".mp3", ".m4a", ".aiff", ".caf")):
                berkas.append(os.path.join(a.target, n))
    else:
        berkas = [a.target]

    for path in berkas:
        nama = a.nama or os.path.splitext(os.path.basename(path))[0]
        try:
            for out, detik in olah(path, nama, a.keluar, a.pisah, a.maks_detik):
                print("%-42s %5.2fs" % (out, detik))
        except Exception as e:
            print("%-42s GAGAL: %s" % (os.path.basename(path), e))


if __name__ == "__main__":
    main()
