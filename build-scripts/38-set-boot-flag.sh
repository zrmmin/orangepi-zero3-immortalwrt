#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output

echo "=== 修改前分区表 ==="
sudo sfdisk -d "$IMG" 2>&1 | grep -E 'img[0-9]|bootable'

LD=$(sudo losetup -f -P --show "$IMG")
echo "loop=$LD"
echo "=== 给分区1打 bootable(0x80) 标志 ==="
sudo parted -s "$LD" set 1 boot on
sudo partprobe "$LD" 2>/dev/null || true
echo "=== 修改后 (parted) ==="
sudo parted -s "$LD" print
sudo losetup -d "$LD"

echo "=== 修改后 (fdisk, 看 Boot 列的 *) ==="
fdisk -l "$IMG" 2>&1 | grep -E 'Device|img[0-9]'

echo "=== 重新导出压缩镜像 ==="
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "SET-BOOTFLAG-DONE"
