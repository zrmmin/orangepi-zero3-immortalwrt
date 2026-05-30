#!/usr/bin/env bash
# Assemble the bootable Orange Pi Zero3 image from ImmortalWrt rootfs +
# vendor 6.1 kernel + u-boot, using openwrt_packit. Needs root.
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
P="$PACKIT_DIR"
KVER=6.1.31-sun50iw9
KPKG="$BUILD_ROOT/kernel_pkg"
ROOTFS_SRC="$IMM_DIR/bin/targets/armsr/armv8/immortalwrt-armsr-armv8-generic-rootfs.tar.gz"

echo "=== sanity: kernel tarballs ==="
ls -lh "$KPKG"/{boot,modules,dtb-allwinner}-$KVER.tar.gz

echo "=== place rootfs into packit dir (as openwrt-armsr-armv8-generic-rootfs.tar.gz) ==="
cp -f "$ROOTFS_SRC" "$P/openwrt-armsr-armv8-generic-rootfs.tar.gz"
ls -lh "$P/openwrt-armsr-armv8-generic-rootfs.tar.gz"

echo "=== kernel modules support in WSL kernel (loop/btrfs) ==="
grep -qE 'btrfs' /proc/filesystems && echo "btrfs: builtin" || (modprobe btrfs 2>/dev/null && echo "btrfs: module loaded" || echo "btrfs: NOT available")

cd "$P"
echo "=== run mk_h618_zero3.sh (root) start: $(date) ==="
sudo env KERNEL_VERSION="$KVER" KERNEL_PKG_HOME="$KPKG" ZSTD_LEVEL=6 WHOAMI=zrm OPENWRT_VER=immortalwrt \
    bash ./mk_h618_zero3.sh
rc=$?
echo "=== end: $(date) rc=$rc ==="
echo "=== output images ==="
ls -lh "$P/output/" 2>/dev/null
echo "PACKIT-RUN-DONE rc=$rc"
