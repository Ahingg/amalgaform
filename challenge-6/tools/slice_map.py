#!/usr/bin/env python3
"""Potong assets/map.PNG jadi ubin lantai dan dinding.

    python3 tools/slice_map.py

map.PNG itu kanvas 1024x1024 yang dibagi 4x4. Xaviero menggambarnya begini:

    baris 0  (y 0-256)     puncak dinding, paling gelap
    baris 1  (y 256-512)   muka dinding, ada juntaian akar
    baris 2-3 (y 512-1024) lantai, 8 petak berbeda

Yang diambil untuk dinding cuma BARIS 1. Baris 0 nyaris hitam rata, dan begitu
dijejalkan ke pita setinggi 96 piksel di layar dia cuma jadi garis gelap tanpa
bentuk — yang justru bikin dindingnya terbaca sebagai dua pita tipis, bukan
sebagai satu dinding. Baris 2-3 jadi delapan ubin lantai 256x256.

Dipotong lewat skrip, bukan tangan, supaya kalau map.PNG digambar ulang tinggal
jalankan lagi — dan supaya pembagiannya tercatat di satu tempat, bukan jadi
pengetahuan yang cuma ada di kepala.
"""

import pathlib
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("butuh Pillow: python3 -m pip install Pillow")

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "map.PNG"
OUT = ROOT / "assets" / "map"

CELL = 256
WALL_FACE_ROW = 1   # baris yang dipakai jadi muka dinding
WALL_ROWS = 2       # baris 0-1 semuanya dinding
LAND_ROWS = 2       # baris 2-3


def main() -> None:
    if not SRC.exists():
        sys.exit("tidak ketemu: %s" % SRC)
    OUT.mkdir(parents=True, exist_ok=True)

    im = Image.open(SRC).convert("RGBA")
    w, h = im.size
    if (w, h) != (CELL * 4, CELL * 4):
        sys.exit("map.PNG harus 1024x1024, sekarang %dx%d" % (w, h))

    made = []
    for c in range(4):
        x = c * CELL
        tile = im.crop((x, WALL_FACE_ROW * CELL, x + CELL, (WALL_FACE_ROW + 1) * CELL))
        name = OUT / ("wall%d.png" % c)
        tile.save(name)
        made.append(name)

    n = 0
    for r in range(WALL_ROWS, WALL_ROWS + LAND_ROWS):
        for c in range(4):
            tile = im.crop((c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL))
            name = OUT / ("land%d.png" % n)
            tile.save(name)
            made.append(name)
            n += 1

    for p in made:
        print(p.relative_to(ROOT))
    print("%d berkas" % len(made))


if __name__ == "__main__":
    main()
