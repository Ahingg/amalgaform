#!/usr/bin/env python3
"""
Membangkitkan tiga bunyi pendek untuk rune yang masuk antrian.

Kenapa dibangkitkan, bukan dicari: bunyi ini harus terdengar sebagai SATU
sistem — tindakan yang sama dengan nilai yang berbeda. Tiga berkas dari
pustaka yang berbeda akan terdengar seperti tiga kejadian berbeda, dan pemain
harus belajar tiga bunyi alih-alih satu bunyi dengan tiga nada.

Jadi ketiganya memakai timbre yang sama persis dan cuma beda nada, dan
nadanya diambil dari satu akor supaya urutan apa pun tetap enak — pemain akan
menekan J-K-L dalam urutan apa saja, jadi tidak ada urutan yang boleh sumbang.

Nada dipetakan ke sifat runenya: api paling rendah dan hangat, angin paling
tinggi dan ringan.

Stdlib saja.

    python3 tools/make_rune_blips.py
"""
import math
import os
import random
import struct
import wave

RATE = 44100
KELUAR = os.path.join(os.path.dirname(__file__), "..",
                      "challenge-6", "assets", "sfx")

# Akor A mayor: apa pun urutan tekannya, tidak ada pasangan yang sumbang.
NADA = [
    ("rune_ignis", 440.00),   # A4  — paling rendah, paling hangat
    ("rune_aqua", 554.37),    # C#5
    ("rune_ventus", 659.25),  # E5  — paling tinggi, paling ringan
]

PANJANG = 0.11      # detik. Lebih panjang dari ini, mengetik cepat jadi lumpur.
LURUH = 34.0        # makin besar makin pendek buntutnya
DERAU = 0.0035      # transien di awal: tanpa ini bunyinya "bip", bukan "tik"
PUNCAK = 0.72


def blip(freq):
    n = int(RATE * PANJANG)
    rnd = random.Random(int(freq))
    x = []
    for i in range(n):
        t = i / RATE
        amp = math.exp(-t * LURUH)
        # Dasar plus dua harmonik yang lebih cepat hilang. Harmonik yang luruh
        # lebih cepat daripada dasarnya itu yang bikin bunyinya terdengar
        # dipetik, bukan disintesis.
        v = math.sin(2 * math.pi * freq * t)
        v += 0.34 * math.sin(2 * math.pi * freq * 2 * t) * math.exp(-t * LURUH * 2.2)
        v += 0.12 * math.sin(2 * math.pi * freq * 3 * t) * math.exp(-t * LURUH * 3.5)
        # Transien: derau yang mati dalam 6 ms, memberi tepi pada serangannya.
        v += DERAU * rnd.uniform(-1, 1) * math.exp(-t * 380.0) * 60.0
        x.append(v * amp)

    puncak = max(abs(v) for v in x)
    g = PUNCAK / puncak
    x = [v * g for v in x]

    # Fade keluar mikro. Buntut eksponensial tidak pernah benar-benar nol, dan
    # sampel terakhir yang tidak nol bunyinya "klik" tiap kali diputar.
    ekor = int(RATE * 0.006)
    for i in range(ekor):
        x[len(x) - 1 - i] *= i / float(ekor)
    return x


def main():
    keluar = os.path.normpath(KELUAR)
    os.makedirs(keluar, exist_ok=True)
    for nama, freq in NADA:
        x = blip(freq)
        path = os.path.join(keluar, nama + ".wav")
        with wave.open(path, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b"".join(
                struct.pack("<h", max(-32768, min(32767, int(v * 32767))))
                for v in x))
        print("%s  %.0f Hz  %.0f ms" % (path, freq, PANJANG * 1000))


if __name__ == "__main__":
    main()
