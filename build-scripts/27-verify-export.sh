#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
KVER=6.1.31-sun50iw9
IMG="$PACKIT_DIR/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
OUT_WIN="/mnt/d/zrm/orangepi/zero3/output"
mkdir -p "$OUT_WIN"

echo "=== verify image internals ==="
sudo bash -c '
set -e
IMG="'"$IMG"'"; KVER="'"$KVER"'"
losetup -D
LD=$(losetup -f -P --show "$IMG")
echo "loop: $LD"
B=$(mktemp -d); R=$(mktemp -d)
mount "${LD}p1" "$B"
mount "${LD}p2" "$R"
echo "----- BOOT partition -----"
ls -1 "$B"
echo "--- uEnv.txt ---"; cat "$B/uEnv.txt"
echo "--- dtb present? ---"; ls "$B/dtb/allwinner/" | grep zero3
echo "----- ROOT partition -----"
echo "--- /etc/modules.d wifi ---"; ls -1 "$R/etc/modules.d/" | grep -iE "uwe5622|sprdwl" ; cat "$R/etc/modules.d/50-uwe5622-bsp" "$R/etc/modules.d/51-sprdwl-ng"
echo "--- wifi .ko in rootfs modules ---"; ls "$R/lib/modules/$KVER/" | grep -iE "sprdwl_ng|uwe5622_bsp_sdio"
echo "--- tun/nft_tproxy ---"; ls "$R/lib/modules/$KVER/" | grep -iE "^tun.ko|nft_tproxy"
echo "--- OpenClash present? ---"; ls -d "$R/etc/init.d/openclash" 2>/dev/null; ls -d "$R/usr/share/openclash" 2>/dev/null | head; ls "$R/usr/lib/lua/luci/model/cbi/openclash" 2>/dev/null | head -1
echo "--- LuCI + zh-cn ---"; ls "$R/usr/lib/lua/luci" >/dev/null 2>&1 && echo "luci OK"; ls "$R/usr/lib/lua/luci/i18n/" 2>/dev/null | grep -i "zh-cn" | head
echo "--- dnsmasq-full ---"; ls "$R/usr/sbin/dnsmasq" 2>/dev/null && echo dnsmasq-present
umount "$B"; umount "$R"; losetup -d "$LD"
rmdir "$B" "$R"
echo "verify-unmounted"
'

echo "=== export compressed image + sha256 to $OUT_WIN ==="
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "VERIFY-EXPORT-DONE"
