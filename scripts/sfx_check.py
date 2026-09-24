#!/usr/bin/env python3
"""
Memeriksa berkas WAV secara TEKNIS: apakah dia layak jadi efek suara game.

Yang diperiksa alat ini bisa diukur. Yang TIDAK bisa diukur — apakah suaranya
terdengar seperti monster, apakah dia masih enak di dengar ke-50 kalinya —
tidak ada di sini, dan memang tidak bisa ditambahkan.

Cuma memakai pustaka bawaan Python: WAV saja.

Pakai:
    python3 tools/sfx_check.py rekaman/
    python3 tools/sfx_check.py rekaman/monster1.wav
    python3 tools/sfx_check.py rekaman/ --jenis kena     # ambang lebih ketat
"""
import argparse
import array
import math
import os
import sys
import wave

# Ambang per jenis. "kena" paling ketat karena dia yang paling sering bunyi:
# suara yang 100 md terlalu panjang tidak terasa saat didengar sendirian, tapi
# jadi lumpur begitu tiga musuh kena dalam satu detik.
AMBANG = {
    "kena":   {"maks_detik": 0.45, "maks_awal_ms": 25.0},
    "rapal":  {"maks_detik": 1.20, "maks_awal_ms": 40.0},
    "mati":   {"maks_detik": 1.00, "maks_awal_ms": 30.0},
    "umum":   {"maks_detik": 1.50, "maks_awal_ms": 40.0},
}

PUNCAK_MIN_DB = -12.0    # lebih pelan dari ini, akan tenggelam saat dicampur
PUNCAK_MAKS_DB = -0.5    # lebih keras dari ini, sudah menyentuh atap
LANTAI_MAKS_DB = -45.0   # desis ruangan di atas ini akan terdengar
DC_MAKS = 0.01           # offset DC bikin "klik" tiap kali suara mulai


def db(x):
    return -99.0 if x <= 1e-9 else 20.0 * math.log10(x)


def baca(path):
    with wave.open(path, "rb") as w:
        n, rate, ch, width = (w.getnframes(), w.getframerate(),
                              w.getnchannels(), w.getsampwidth())
        raw = w.readframes(n)
    if width == 1:
        s = array.array("b", bytes(b - 128 for b in raw))
        skala = 128.0
    elif width == 2:
        s = array.array("h", raw)
        skala = 32768.0
    elif width == 4:
        s = array.array("i", raw)
        skala = 2147483648.0
    else:
        raise ValueError("lebar sampel %d byte belum didukung" % width)
    if sys.byteorder == "big":
        s.byteswap()
    # Digabung jadi mono: efek suara game hampir selalu diputar mono, dan yang
    # diukur di sini sifat suaranya, bukan penempatannya di stereo.
    if ch > 1:
        s = array.array("d", (sum(s[i:i + ch]) / float(ch)
                              for i in range(0, len(s) - ch + 1, ch)))
    else:
        s = array.array("d", (float(v) for v in s))
    return [v / skala for v in s], rate, ch, width


def ukur(x, rate):
    n = len(x)
    if n == 0:
        return None
    puncak = max(abs(v) for v in x)
    rms = math.sqrt(sum(v * v for v in x) / n)
    dc = sum(x) / n
    terpotong = sum(1 for v in x if abs(v) >= 0.999)

    # Sunyi di depan = jeda sebelum suaranya benar-benar mulai. Ini langsung
    # jadi keterlambatan yang terasa: pemain menekan, lalu menunggu.
    batas = puncak * 0.05
    awal = 0
    while awal < n and abs(x[awal]) < batas:
        awal += 1
    akhir = n - 1
    while akhir > awal and abs(x[akhir]) < batas:
        akhir -= 1

    # Lantai desis diukur HANYA dari bagian SEBELUM suaranya mulai. Itu satu-
    # satunya bagian yang pasti cuma berisi ruangan.
    #
    # Ekornya sengaja tidak dipakai walaupun kelihatan sunyi: suara yang meluruh
    # tetap suara, dan mengukur desis di sana bikin rekaman bersih dituduh
    # berisik. Kalau tidak ada jeda di depan sama sekali, angkanya memang tidak
    # bisa diukur — dan itu dibilang "n/a", bukan ditebak.
    tepi = x[:awal]
    lantai = None
    if len(tepi) >= int(rate * 0.02):
        jendela = max(1, min(int(rate * 0.1), len(tepi)))
        for i in range(0, max(1, len(tepi) - jendela + 1), max(1, jendela // 2)):
            p = tepi[i:i + jendela]
            r = math.sqrt(sum(v * v for v in p) / len(p))
            lantai = r if lantai is None else min(lantai, r)

    # Kecerahan lewat laju lintas-nol: murah, tanpa FFT, dan cukup untuk
    # membedakan gumaman berat dari desis tajam.
    inti = x[awal:akhir + 1] or x
    lintas = sum(1 for i in range(1, len(inti))
                 if (inti[i - 1] < 0) != (inti[i] < 0))
    zcr = lintas * rate / (2.0 * max(1, len(inti)))

    return {
        "detik": n / float(rate),
        "puncak_db": db(puncak),
        "rms_db": db(rms),
        "lantai_db": None if lantai is None else db(lantai),
        "dc": dc,
        "terpotong": terpotong,
        "awal_ms": awal * 1000.0 / rate,
        "ekor_ms": (n - 1 - akhir) * 1000.0 / rate,
        "isi_detik": (akhir - awal + 1) / float(rate),
        "zcr": zcr,
    }


def nilai(m, jenis):
    a = AMBANG.get(jenis, AMBANG["umum"])
    masalah = []
    if m["isi_detik"] > a["maks_detik"]:
        masalah.append("KEPANJANGAN %.2fs (maks %.2fs untuk '%s') - potong ekornya"
                       % (m["isi_detik"], a["maks_detik"], jenis))
    if m["awal_ms"] > a["maks_awal_ms"]:
        masalah.append("SUNYI DI DEPAN %.0f ms - ini jadi keterlambatan yang terasa, potong"
                       % m["awal_ms"])
    if m["terpotong"] > 0 or m["puncak_db"] > PUNCAK_MAKS_DB:
        masalah.append("MENTOK ATAP (%d sampel di 0 dB) - rekam ulang lebih pelan"
                       % m["terpotong"])
    if m["puncak_db"] < PUNCAK_MIN_DB:
        masalah.append("TERLALU PELAN puncak %.1f dB - akan tenggelam saat dicampur"
                       % m["puncak_db"])
    if m["lantai_db"] is not None and m["lantai_db"] > LANTAI_MAKS_DB:
        masalah.append("DESIS RUANGAN %.1f dB - terdengar saat sunyi, rekam lebih dekat"
                       % m["lantai_db"])
    if abs(m["dc"]) > DC_MAKS:
        masalah.append("OFFSET DC %.4f - akan bunyi 'klik' tiap kali mulai" % m["dc"])
    return masalah


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("target", help="berkas .wav atau folder")
    ap.add_argument("--jenis", default="umum", choices=sorted(AMBANG),
                    help="kena / rapal / mati / umum")
    a = ap.parse_args()

    berkas = []
    if os.path.isdir(a.target):
        for nama in sorted(os.listdir(a.target)):
            if nama.lower().endswith(".wav"):
                berkas.append(os.path.join(a.target, nama))
    else:
        berkas = [a.target]
    if not berkas:
        sys.exit("tidak ada .wav di %s" % a.target)

    lolos = 0
    for path in berkas:
        try:
            x, rate, ch, width = baca(path)
            m = ukur(x, rate)
        except Exception as e:
            print("%-28s GAGAL DIBACA: %s" % (os.path.basename(path), e))
            continue
        if m is None:
            print("%-28s KOSONG" % os.path.basename(path))
            continue

        masalah = nilai(m, a.jenis)
        tanda = "OK  " if not masalah else "CEK "
        desis = "  n/a " if m["lantai_db"] is None else "%6.1f" % m["lantai_db"]
        print("%s%-26s %5.2fs isi %5.2fs | puncak %6.1f dB | desis %s dB | "
              "awal %4.0f ms | %d Hz %dch %dbit | terang %.0f"
              % (tanda, os.path.basename(path), m["detik"], m["isi_detik"],
                 m["puncak_db"], desis, m["awal_ms"],
                 rate, ch, width * 8, m["zcr"]))
        for p in masalah:
            print("      - %s" % p)
        if not masalah:
            lolos += 1

    print("\n%d / %d lolos pemeriksaan teknis." % (lolos, len(berkas)))
    print("Yang TIDAK diperiksa di sini: apakah suaranya cocok, dan apakah dia")
    print("masih enak didengar ke-50 kalinya. Itu cuma telinga yang bisa jawab.")


if __name__ == "__main__":
    main()
