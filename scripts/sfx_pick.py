#!/usr/bin/env python3
"""
Menyaring tumpukan berkas WAV jadi daftar pendek, lalu menggabungkannya jadi
SATU berkas pratinjau supaya bisa didengar sekali jalan.

Yang paling lama saat mencari suara bukan menyaringnya, tapi mengklik ratusan
berkas satu per satu. Berkas pratinjau itu yang menghemat waktu, bukan filternya.

Cuma memakai pustaka bawaan Python: WAV saja. OGG/MP3 tidak terbaca.

Pakai:
    python3 sfx_pick.py <folder> --kata hit,impact,punch --maks-detik 1.0
    python3 sfx_pick.py <folder> --kata cast,magic --maks-detik 1.5 --ambil 40
"""
import argparse, os, shutil, sys, wave


def info(path):
    try:
        with wave.open(path, "rb") as w:
            n, rate, ch, width = w.getnframes(), w.getframerate(), w.getnchannels(), w.getsampwidth()
            return {"detik": n / float(rate), "rate": rate, "ch": ch, "width": width, "path": path}
    except Exception:
        return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("folder")
    ap.add_argument("--kata", default="", help="kata kunci nama berkas, dipisah koma")
    ap.add_argument("--min-detik", type=float, default=0.03)
    ap.add_argument("--maks-detik", type=float, default=1.2)
    ap.add_argument("--ambil", type=int, default=30)
    ap.add_argument("--keluar", default="sfx_shortlist")
    a = ap.parse_args()

    kata = [k.strip().lower() for k in a.kata.split(",") if k.strip()]
    kandidat = []
    total = 0

    for root, _, files in os.walk(a.folder):
        for f in files:
            if not f.lower().endswith(".wav"):
                continue
            total += 1
            p = os.path.join(root, f)
            if kata and not any(k in f.lower() for k in kata):
                continue
            m = info(p)
            if m and a.min_detik <= m["detik"] <= a.maks_detik:
                kandidat.append(m)

    kandidat.sort(key=lambda m: m["detik"])
    kandidat = kandidat[: a.ambil]

    print(f"{total} berkas WAV dipindai, {len(kandidat)} lolos saringan\n")
    if not kandidat:
        return

    os.makedirs(a.keluar, exist_ok=True)
    for i, m in enumerate(kandidat):
        nama = f"{i:02d}_{os.path.basename(m['path'])}"
        shutil.copy2(m["path"], os.path.join(a.keluar, nama))
        print(f"  {i:02d}  {m['detik']:.2f}s  {m['rate']}Hz  {os.path.basename(m['path'])}")

    # Berkas pratinjau: hanya yang formatnya sama yang bisa digabung tanpa
    # dikonversi, jadi diambil format yang paling banyak muncul.
    from collections import Counter
    fmt = Counter((m["rate"], m["ch"], m["width"]) for m in kandidat).most_common(1)[0][0]
    sama = [m for m in kandidat if (m["rate"], m["ch"], m["width"]) == fmt]

    out = os.path.join(a.keluar, "_pratinjau.wav")
    with wave.open(out, "wb") as w:
        w.setnchannels(fmt[1]); w.setsampwidth(fmt[2]); w.setframerate(fmt[0])
        hening = b"\x00" * int(fmt[0] * 0.35) * fmt[1] * fmt[2]
        for m in sama:
            with wave.open(m["path"], "rb") as r:
                w.writeframes(r.readframes(r.getnframes()))
            w.writeframes(hening)

    print(f"\nPratinjau: {out}  ({len(sama)} suara, urut nomor di atas)")
    print("Dengarkan sekali, catat nomor yang bagus, ambil dari folder yang sama.")


if __name__ == "__main__":
    main()
