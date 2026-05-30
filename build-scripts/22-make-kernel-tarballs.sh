#!/usr/bin/env bash
# Convert orangepi-build kernel deb output into Flippy-style kernel tarballs:
#   boot-<KVER>.tar.gz, modules-<KVER>.tar.gz, dtb-allwinner-<KVER>.tar.gz
set -euo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
EX="$BUILD_ROOT/kpkg_extract"
KVER=$(ls -1 "$EX/img/lib/modules" | head -n1)
echo "KVER=$KVER"

KPKG="$BUILD_ROOT/kernel_pkg"
rm -rf "$KPKG"; mkdir -p "$KPKG"

# ---- boot tarball (vmlinuz + config + System.map + placeholder uInitrd) ----
echo "=== build boot-$KVER.tar.gz ==="
BT="$BUILD_ROOT/.boottmp"; rm -rf "$BT"; mkdir -p "$BT"
cp "$EX/img/boot/vmlinuz-$KVER"     "$BT/vmlinuz-$KVER"
cp "$EX/img/boot/config-$KVER"      "$BT/config-$KVER"
cp "$EX/img/boot/System.map-$KVER"  "$BT/System.map-$KVER"
# We boot WITHOUT initrd (ext4/btrfs/mmc_sunxi are =y). Placeholder keeps
# packit's extract_allwinner_boot_files happy (it copies uInitrd-<KVER>).
: > "$BT/uInitrd-$KVER"
( cd "$BT" && tar czf "$KPKG/boot-$KVER.tar.gz" . )

# ---- dtb-allwinner tarball (dtb files at root) ----
echo "=== build dtb-allwinner-$KVER.tar.gz ==="
DTBSRC=$(dirname "$(find "$EX/dtb" -name 'sun50i-h618-orangepi-zero3.dtb' | head -n1)")
echo "dtb src dir: $DTBSRC"
( cd "$DTBSRC" && tar czf "$KPKG/dtb-allwinner-$KVER.tar.gz" . )

# ---- modules tarball (top dir = <KVER>/) ----
echo "=== build modules-$KVER.tar.gz ==="
# drop build/source symlinks to avoid dangling refs
rm -f "$EX/img/lib/modules/$KVER/build" "$EX/img/lib/modules/$KVER/source"
( cd "$EX/img/lib/modules" && tar czf "$KPKG/modules-$KVER.tar.gz" "$KVER" )

echo
echo "=== results ==="
ls -lh "$KPKG"
echo "--- boot tarball contents ---"; tar tzf "$KPKG/boot-$KVER.tar.gz" | head
echo "--- dtb tarball (zero3) ---"; tar tzf "$KPKG/dtb-allwinner-$KVER.tar.gz" | grep zero3
echo "--- modules top entries ---"; tar tzf "$KPKG/modules-$KVER.tar.gz" | head -n 3
echo "--- wifi .ko in modules tarball ---"; tar tzf "$KPKG/modules-$KVER.tar.gz" | grep -E 'sprdwl_ng|uwe5622_bsp_sdio'
echo "TARBALLS-DONE KVER=$KVER"
