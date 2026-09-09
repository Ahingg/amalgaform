#!/usr/bin/env bash
# Terbitkan rilis baru ke GitHub.
#
#   ./tools/release.sh v1.1 "catatan singkat"
#
# Kenapa ini SKRIP DI MESIN SENDIRI dan bukan pekerjaan CI:
#
# Rilis harus dinotarisasi, dan notarisasi butuh kunci pribadi Developer ID.
# Kunci itu tidak ditaruh di GitHub. Jadi CI hanya bisa menghasilkan build
# ad-hoc — dan build ad-hoc yang dipasang sebagai rilis akan ditolak Gatekeeper
# di mesin siapa pun yang mengunduhnya. Itu sudah pernah terjadi sekali dan
# menghabiskan waktu untuk didiagnosis.
#
# Pembagian yang dipegang:
#   CI    memeriksa bahwa proyeknya masih bisa diekspor    (otomatis)
#   skrip ini menerbitkan yang benar-benar dibagikan       (manual, sengaja)

set -euo pipefail
cd "$(dirname "$0")/.."

TAG="${1:-}"
CATATAN="${2:-}"
if [ -z "$TAG" ]; then
	echo "pakai: ./tools/release.sh v1.1 \"catatan singkat\"" >&2
	exit 1
fi

REPO="${REPO:-Ahingg/amalgaform}"
OUT="${OUT:-$HOME/Builds}"
ZIP="$OUT/Amalgaform.zip"

echo "==> bangun + notarisasi"
NOTARIZE=1 ./tools/build_mac.sh

echo "==> bungkus"
rm -f "$ZIP"
ditto -c -k --keepParent "$OUT/Amalgaform.app" "$ZIP"

# Penjagaan terakhir sebelum sesuatu jadi publik. Kalau tiketnya tidak
# tertempel, yang akan diunduh orang adalah berkas yang ditolak macOS.
echo "==> periksa tiket sebelum menerbitkan"
xcrun stapler validate "$OUT/Amalgaform.app"
spctl -a -vvv "$OUT/Amalgaform.app" 2>&1 | grep -q "accepted" \
	|| { echo "!! Gatekeeper menolak build ini, rilis dibatalkan" >&2; exit 1; }

echo "==> terbitkan $TAG"
git tag -a "$TAG" -m "Amalgaform $TAG" 2>/dev/null || true
git push origin "$TAG"
gh release create "$TAG" "$ZIP" --repo "$REPO" \
	--title "Amalgaform $TAG" \
	--notes "${CATATAN:-Rilis $TAG.}"

echo
echo "Selesai: https://github.com/$REPO/releases/tag/$TAG"
