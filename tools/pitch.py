#!/usr/bin/env python3
"""
Menaikkan/menurunkan nada satu berkas WAV, lalu menyimpannya jadi beberapa
langkah nada sekaligus.

Caranya resampling: berkas dibaca dengan laju yang berbeda. Itu mengubah nada
DAN durasi bersamaan — persis seperti memutar kaset lebih cepat.

Untuk bunyi pendek, itu justru yang diinginkan: nada makin tinggi ikut makin
pendek, dan hasilnya terdengar makin ringan alih-alih seperti nada yang sama
digeser. Untuk suara panjang atau vokal, cara ini salah — suaranya akan
terdengar seperti tupai.

Stdlib saja.

    python3 tools/pitch.py rune_base.wav --nama rune --langkah 0,2,4,7
    python3 tools/pitch.py growl.wav --nama monster_low --langkah -5
"""
import argparse
import array
import math
import os
import struct
import sys
import wave


def baca(path):
    with wave.open(path, "rb") as w:
        n, rate, ch, width = (w.getnframes(), w.getframerate(),
                              w.getnchannels(), w.getsampwidth())
        raw = w.readframes(n)
    if width != 2:
        raise ValueError("hanya 16-bit")
    s = array.array("h", raw)
    if sys.byteorder == "big":
        s.byteswap()
    if ch > 1:
        s = [sum(s[i:i + ch]) / float(ch) for i in range(0, len(s) - ch + 1, ch)]
    return [v / 32768.0 for v in s], rate


def tulis(path, x, rate):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b"".join(
            struct.pack("<h", max(-32768, min(32767, int(v * 32767.0)))) for v in x))


def geser(x, semiton):
    """Resampling dengan interpolasi linier.

    Interpolasi, bukan sampel terdekat: mengambil sampel terdekat pada laju
    pecahan menghasilkan derau tangga yang terdengar jelas di bunyi bernada.
    """
    if semiton == 0:
        return list(x)
    rasio = 2.0 ** (semiton / 12.0)
    n = int(len(x) / rasio)
    keluar = []
    for i in range(n):
        p = i * rasio
        k = int(p)
        f = p - k
        a = x[k] if k < len(x) else 0.0
        b = x[k + 1] if k + 1 < len(x) else a
        keluar.append(a + (b - a) * f)
    return keluar


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("berkas")
    ap.add_argument("--nama", default="", help="nama keluaran; nomor slot ditambahkan")
    ap.add_argument("--langkah", default="0", help="daftar semiton, dipisah koma")
    ap.add_argument("--keluar", default="challenge-6/assets/sfx")
    a = ap.parse_args()

    x, rate = baca(a.berkas)
    langkah = [int(s) for s in a.langkah.split(",") if s.strip()]
    nama = a.nama or os.path.splitext(os.path.basename(a.berkas))[0]
    os.makedirs(a.keluar, exist_ok=True)

    for i, st in enumerate(langkah):
        y = geser(x, st)
        # Fade mikro di ujung: resampling memotong di tengah gelombang, dan
        # sampel terakhir yang tidak nol bunyinya "klik".
        ekor = min(len(y) // 4, int(rate * 0.005))
        for k in range(ekor):
            y[len(y) - 1 - k] *= k / float(ekor)
        akhiran = "" if len(langkah) == 1 else "_%d" % (i + 1)
        out = os.path.join(a.keluar, "%s%s.wav" % (nama, akhiran))
        tulis(out, y, rate)
        print("%-44s %+2d semiton  %.0f ms" % (out, st, len(y) * 1000.0 / rate))


if __name__ == "__main__":
    main()
