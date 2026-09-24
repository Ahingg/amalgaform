#!/usr/bin/env python3
"""
Membuat versi PUTIH PENUH dari sprite yang gelap, untuk dipakai sebagai garis
tepi di belakangnya.

Kenapa ini perlu ada sama sekali: `modulate` di Godot itu PERKALIAN. Seni musuh
di proyek ini 97% hitam pekat, jadi menggambarnya dengan warna putih tetap
menghasilkan hitam. Tidak ada nilai modulate yang bisa mencerahkan piksel
hitam. Satu-satunya cara membuat tepi terang tanpa shader adalah menyediakan
gambar yang memang sudah terang.

Yang dihasilkan: bentuk yang sama persis, alpha yang sama persis, tapi seluruh
pikselnya putih. Digambar sedikit lebih besar di belakang sprite aslinya, dan
yang menyembul di pinggirnya jadi garis tepi.

Butuh Pillow.

    python3 tools/make_silhouette.py assets/enemies/humanoid_walk1.png
    python3 tools/make_silhouette.py assets/enemies/          # semua di folder
"""
import os
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("butuh Pillow: python3 -m pip install Pillow")

AKHIRAN = "_silhouette"


def olah(path: str) -> str | None:
    if AKHIRAN in path:
        return None
    im = Image.open(path).convert("RGBA")
    # Alpha dipertahankan apa adanya; cuma warnanya yang diganti. Kalau alpha
    # ikut dipaksa penuh, tepi sprite yang halus jadi bergerigi.
    putih = Image.new("RGBA", im.size, (255, 255, 255, 0))
    putih.putalpha(im.getchannel("A"))
    akar, ext = os.path.splitext(path)
    keluar = akar + AKHIRAN + ext.lower()
    putih.save(keluar)
    return keluar


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    target = sys.argv[1]
    berkas = []
    if os.path.isdir(target):
        for n in sorted(os.listdir(target)):
            if n.lower().endswith(".png"):
                berkas.append(os.path.join(target, n))
    else:
        berkas = [target]

    for p in berkas:
        hasil = olah(p)
        if hasil:
            print(hasil)


if __name__ == "__main__":
    main()
