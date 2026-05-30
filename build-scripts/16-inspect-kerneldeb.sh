#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
DEBS="$BUILD_ROOT/orangepi-build/output/debs"
EX="$BUILD_ROOT/kpkg_extract"
rm -rf "$EX"; mkdir -p "$EX/img" "$EX/dtb"

echo "=== extract linux-image deb ==="
dpkg-deb -x "$DEBS"/linux-image-next-sun50iw9_*.deb "$EX/img"
echo "=== extract linux-dtb deb ==="
dpkg-deb -x "$DEBS"/linux-dtb-next-sun50iw9_*.deb "$EX/dtb"

echo
echo "=== /boot contents ==="
ls -la "$EX/img/boot" 2>/dev/null

echo
echo "=== kernel version (modules dir) ==="
ls -1 "$EX/img/lib/modules" 2>/dev/null
KVER=$(ls -1 "$EX/img/lib/modules" 2>/dev/null | head -n1)
echo "KVER=$KVER"

echo
echo "=== wifi modules present in modules tree? ==="
find "$EX/img/lib/modules" -name 'sprdwl_ng.ko*' -o -name 'uwe5622_bsp_sdio.ko*' 2>/dev/null

echo
echo "=== dtb: orangepi zero3 ==="
find "$EX/dtb" -name '*orangepi-zero3*' 2>/dev/null
find "$EX/img" -name '*orangepi-zero3*' 2>/dev/null | head

echo
echo "=== kernel config key options ==="
CFG="$EX/img/boot/config-$KVER"
if [ -f "$CFG" ]; then
  grep -E '^CONFIG_(TUN|NF_TABLES|NFT_TPROXY|NETFILTER_XT_TARGET_TPROXY|EXT4_FS|BTRFS_FS|MMC|MMC_SUNXI|SQUASHFS|OVERLAY_FS|F2FS_FS|VFAT_FS|FAT_FS)\b' "$CFG" | sort
  echo "--- uwe5622/sprd ---"
  grep -iE 'UWE5622|SPRDWL|SPRDBT|SPRD_WLAN|AW_WIFI' "$CFG" | head
else
  echo "config file not found at $CFG"
fi
echo "INSPECT16-DONE"
