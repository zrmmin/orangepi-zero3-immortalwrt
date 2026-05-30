#!/usr/bin/env bash
# Rebuild kernel tarballs with root ownership (vfat boot partition cannot chown
# to uid 1000), clean up leftover loop/mounts, then re-run packit.
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
EX="$BUILD_ROOT/kpkg_extract"
KVER=6.1.31-sun50iw9
KPKG="$BUILD_ROOT/kernel_pkg"

echo "=== cleanup leftover mounts / loop devices ==="
sudo bash -c '
  for m in $(mount | grep -E "openwrt_packit/tmp" | awk "{print \$3}" | sort -r); do umount -lf "$m" 2>/dev/null; done
  losetup -D 2>/dev/null
  rm -rf /home/zrm/build/openwrt_packit/tmp/* 2>/dev/null
  echo "cleanup done"
'

echo "=== rebuild tarballs with --owner=0 --group=0 ==="
BT="$BUILD_ROOT/.boottmp2"; rm -rf "$BT"; mkdir -p "$BT"
cp "$EX/img/boot/vmlinuz-$KVER" "$BT/vmlinuz-$KVER"
cp "$EX/img/boot/config-$KVER" "$BT/config-$KVER"
cp "$EX/img/boot/System.map-$KVER" "$BT/System.map-$KVER"
: > "$BT/uInitrd-$KVER"
( cd "$BT" && tar --owner=0 --group=0 --numeric-owner -czf "$KPKG/boot-$KVER.tar.gz" . )

DTBSRC=$(dirname "$(find "$EX/dtb" -name 'sun50i-h618-orangepi-zero3.dtb' | head -n1)")
( cd "$DTBSRC" && tar --owner=0 --group=0 --numeric-owner -czf "$KPKG/dtb-allwinner-$KVER.tar.gz" . )

( cd "$EX/img/lib/modules" && tar --owner=0 --group=0 --numeric-owner -czf "$KPKG/modules-$KVER.tar.gz" "$KVER" )

echo "rebuilt:"; ls -lh "$KPKG"

echo "=== re-run packit ==="
cd "$PACKIT_DIR"
sudo env KERNEL_VERSION="$KVER" KERNEL_PKG_HOME="$KPKG" ZSTD_LEVEL=6 WHOAMI=zrm OPENWRT_VER=immortalwrt \
    bash ./mk_h618_zero3.sh
rc=$?
echo "=== rc=$rc ==="
ls -lh "$PACKIT_DIR/output/" 2>/dev/null
echo "PACKIT-RERUN-DONE rc=$rc"
