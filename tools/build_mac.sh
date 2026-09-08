#!/usr/bin/env bash
# Bangun Amalgaform.app dan tanda tangani.
#
#   ./tools/build_mac.sh
#
# Tiga langkah, dan ketiganya wajib:
#
#   1. Ekspor. Butuh export template yang versinya SAMA PERSIS dengan editor
#      (Editor -> Manage Export Templates), dan ETC2 ASTC menyala di
#      Project Settings > Rendering > Textures > VRAM Compression.
#
#   2. Buang metadata macOS. Berkas aset yang pernah lewat Finder, AirDrop,
#      atau aplikasi gambar membawa extended attribute, dan codesign menolak
#      bundle yang mengandung "detritus" semacam itu. Ini gagalnya diam-diam:
#      pesannya cuma "resource fork, Finder information, or similar detritus
#      not allowed", tanpa menyebut berkas mana.
#
#   3. Tanda tangan ad-hoc. Godot menyisipkan .pck ke dalam bundle SETELAH
#      template-nya ditandatangani, jadi .app hasil ekspor selalu membawa
#      tanda tangan yang sudah rusak — bukan tanpa tanda tangan, tapi rusak,
#      dan itu lebih buruk. Menandatangani ulang memperbaikinya sekaligus
#      mengganti identitasnya dari milik Godot jadi milik proyek ini.

set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
# Dibangun DI LUAR folder proyek, dan itu bukan selera. Documents di mesin ini
# tersinkronisasi, dan penyedia berkasnya menempelkan com.apple.FinderInfo ke
# akar bundle segera setelah codesign menyentuhnya — lebih cepat daripada
# perintah verify berikutnya. Membersihkan xattr berkali-kali tidak menang
# melawan itu; membangun di luar folder tersinkronisasi menghilangkan sebabnya.
OUT="${OUT:-$HOME/Builds}"
APP="$OUT/Amalgaform.app"

echo "==> ekspor"
mkdir -p "$OUT"
"$GODOT" --headless --path challenge-6 --export-release "macOS" "$APP"

echo "==> bersihkan metadata"
xattr -cr "$APP"
find "$APP" -name "._*" -delete 2>/dev/null || true

echo "==> tanda tangan ad-hoc"
codesign --force --deep --sign - "$APP"

echo "==> periksa"
codesign --verify --deep --strict "$APP" && echo "    tanda tangan sah"
codesign -dvv "$APP" 2>&1 | grep -E "Identifier=|Signature="

echo
echo "Selesai: $APP"
echo "Di Mac lain, berkas ini tetap dihentikan Gatekeeper karena belum"
echo "dinotarisasi. Penerimanya cukup klik-kanan -> Open sekali, atau:"
echo "    xattr -dr com.apple.quarantine Amalgaform.app"
