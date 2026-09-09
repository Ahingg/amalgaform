#!/usr/bin/env bash
# Bangun, tandatangani, dan (opsional) notarisasi Amalgaform.app.
#
#   ./tools/build_mac.sh                 # bangun + tanda tangan
#   NOTARIZE=1 ./tools/build_mac.sh      # + kirim ke Apple, tunggu, tempel
#
# Empat langkah, dan tiap langkah ada di sini karena pernah gagal:
#
#   1. Ekspor. Butuh export template yang versinya SAMA PERSIS dengan editor,
#      dan ETC2 ASTC menyala di Project Settings.
#
#   2. Buang metadata macOS. Berkas yang pernah lewat Finder atau aplikasi
#      gambar membawa extended attribute, dan codesign menolak bundle yang
#      mengandungnya. Pesannya cuma "resource fork, Finder information, or
#      similar detritus not allowed" tanpa menyebut berkas mana.
#
#   3. Tanda tangan. Godot menyisipkan .pck ke bundle SETELAH template-nya
#      ditandatangani, jadi .app hasil ekspor selalu membawa tanda tangan yang
#      sudah rusak — bukan tanpa tanda tangan, tapi rusak, dan itu lebih buruk.
#
#   4. Notarisasi. Ini SATU-SATUNYA yang bikin .app kebuka mulus di Mac orang
#      lain. Tanpa ini, sebagus apa pun tanda tangannya, Gatekeeper tetap
#      menahan berkas yang diunduh atau di-AirDrop.
#
# Sebelum NOTARIZE=1 bisa dipakai, kredensialnya harus disimpan sekali:
#
#   xcrun notarytool store-credentials "notary" \
#       --apple-id xaviero.yamin28@gmail.com \
#       --team-id KH324MQR6L \
#       --password <app-specific-password>
#
# App-specific password dibuat di appleid.apple.com -> Sign-In and Security.
# Password Apple ID biasa TIDAK bisa dipakai.

set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"

# Dibangun DI LUAR folder proyek, dan itu bukan selera. Documents di mesin ini
# tersinkronisasi, dan penyedia berkasnya menempelkan com.apple.FinderInfo ke
# akar bundle segera setelah codesign menyentuhnya — lebih cepat daripada
# perintah verify berikutnya. Membangun di luar folder tersinkronisasi
# menghilangkan sebabnya, bukan gejalanya.
OUT="${OUT:-$HOME/Builds}"
APP="$OUT/Amalgaform.app"
PROFILE="${PROFILE:-notary}"

# Developer ID kalau ada, ad-hoc kalau tidak. Ad-hoc tetap menghasilkan .app
# yang jalan di mesin sendiri; yang tidak bisa cuma notarisasi.
ID="$(security find-identity -v -p codesigning 2>/dev/null \
      | grep "Developer ID Application" | head -1 \
      | sed -E 's/.*"(.*)".*/\1/')"

echo "==> ekspor"
mkdir -p "$OUT"
"$GODOT" --headless --path challenge-6 --export-release "macOS" "$APP"

echo "==> bersihkan metadata"
xattr -cr "$APP"
find "$APP" -name "._*" -delete 2>/dev/null || true

if [ -n "$ID" ]; then
	echo "==> tanda tangan: $ID"
	# --options runtime dan --timestamp dua-duanya WAJIB untuk notarisasi.
	# Tanpa salah satunya, Apple menolak kiriman tanpa menyebut yang mana.
	codesign --force --deep --options runtime --timestamp --sign "$ID" "$APP"
else
	echo "==> tanda tangan: ad-hoc (tidak ada Developer ID)"
	codesign --force --deep --sign - "$APP"
fi

echo "==> periksa"
codesign --verify --deep --strict "$APP" && echo "    tanda tangan sah"
codesign -dvv "$APP" 2>&1 | grep -E "Identifier=|Authority=Developer|TeamIdentifier|flags=" || true

if [ "${NOTARIZE:-0}" = "1" ]; then
	if [ -z "$ID" ]; then
		echo "!! notarisasi butuh Developer ID, bukan ad-hoc" >&2
		exit 1
	fi
	ZIP="$OUT/Amalgaform.zip"
	echo "==> kirim ke Apple (biasanya 1-5 menit)"
	# ditto, bukan `zip`: zip biasa merusak symlink di dalam bundle .app dan
	# kirimannya ditolak dengan alasan yang tidak menyebut symlink sama sekali.
	rm -f "$ZIP"
	ditto -c -k --keepParent "$APP" "$ZIP"
	xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
	rm -f "$ZIP"

	echo "==> tempel tiketnya"
	# Stapler menanam hasil notarisasi ke dalam bundle, jadi Mac penerima tidak
	# perlu online untuk memeriksanya.
	xcrun stapler staple "$APP"
fi

echo
echo "==> status Gatekeeper"
spctl -a -vvv "$APP" 2>&1 | head -2 || true
echo
echo "Selesai: $APP"
