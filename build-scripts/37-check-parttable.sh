#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
echo "=== fdisk -l (看 Boot 列的 * 在哪个分区) ==="
fdisk -l "$IMG" 2>&1
echo "=== sfdisk dump (看 bootable / attrs) ==="
sfdisk -d "$IMG" 2>&1
echo "=== parted print (看 boot/lba flags) ==="
LD=$(sudo losetup -f -P --show "$IMG")
sudo parted -s "$LD" print 2>&1
sudo losetup -d "$LD"
echo "DONE-PT"
