#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
OPI="$BUILD_ROOT/orangepi-build"
EX="$BUILD_ROOT/kpkg_extract"

echo "=== firmware references inside wifi .ko (strings) ==="
for ko in $(find "$EX/img/lib/modules" -name 'sprdwl_ng.ko' -o -name 'uwe5622_bsp_sdio.ko'); do
  echo "## $ko"
  strings "$ko" 2>/dev/null | grep -iE '\.bin|firmware|wcn|gnss|/lib/firmware|/vendor' | sort -u | head -n 30
done

echo
echo "=== candidate firmware files in orangepi-build tree ==="
find "$OPI" -type f \( -iname '*wcnmodem*' -o -iname '*gnssmodem*' -o -iname '*uwe5622*' -o -iname '*sc2355*' -o -iname '*wifi*.bin' -o -iname '*bt*.bin' \) 2>/dev/null | grep -viE '\.git' | head -n 40

echo
echo "=== firmware dir in kernel source tree ==="
find "$OPI/kernel" -maxdepth 3 -type d -iname 'firmware' 2>/dev/null | head
find "$OPI/kernel" -type f -iname '*wcnmodem*' -o -iname '*uwe5622*' 2>/dev/null | head

echo
echo "=== bsp overlays / firmware in external ==="
find "$OPI/external" -type d -iname '*firmware*' 2>/dev/null | head
find "$OPI/external" -type f -iname '*.bin' 2>/dev/null | grep -iE 'wcn|wifi|uwe|sprd|gnss|bt' | head -n 30

echo
echo "=== extract u-boot deb to find u-boot-sunxi-with-spl.bin ==="
UB=$(ls "$OPI/output/debs/u-boot/"linux-u-boot-next-orangepizero3_*.deb 2>/dev/null | head -n1)
echo "uboot deb: $UB"
rm -rf "$BUILD_ROOT/uboot_extract"; mkdir -p "$BUILD_ROOT/uboot_extract"
dpkg-deb -x "$UB" "$BUILD_ROOT/uboot_extract"
find "$BUILD_ROOT/uboot_extract" -type f | head -n 40
echo
echo "=== find u-boot-sunxi-with-spl.bin ==="
find "$BUILD_ROOT/uboot_extract" -name 'u-boot-sunxi-with-spl.bin' -o -name '*.bin' 2>/dev/null | head
echo "LOCATE-DONE"
