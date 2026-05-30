#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-43-findfw.txt
{
echo "=== 搜索 wcnmodem.bin / uwe5622 固件 (整个 build 树) ==="
sudo find /home/zrm/build -iname 'wcnmodem*.bin' 2>/dev/null
echo "--- 相关 marlin/sc23xx/uwe5622/sprd 固件 ---"
sudo find /home/zrm/build -iname '*wcnmodem*' -o -iname '*marlin*' -o -iname 'sc23*.bin' -o -iname '*uwe5622*.bin' 2>/dev/null | grep -iE '\.bin|firmware' | head -40
echo
echo "=== orangepi-build 缓存/外部目录里的固件 ==="
sudo find /home/zrm/build/orangepi-build -path '*firmware*' -iname '*.bin' 2>/dev/null | grep -iE 'wcn|marlin|uwe|sprd|wifi|bt' | head -40
echo
echo "=== 内核源码树 firmware 目录 ==="
sudo find /home/zrm/build/orangepi-build -type d -iname 'firmware' 2>/dev/null | head
echo
echo "=== 在 linux-orangepi 源码里找 wcnmodem 引用/文件 ==="
sudo find /home/zrm/build/orangepi-build -iname 'wcnmodem*' 2>/dev/null | head
echo
echo "=== 已生成rootfs里 /lib/firmware 现状(挂载镜像p2看) ==="
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
LD=$(sudo losetup -f -P --show "$IMG")
R=$(mktemp -d); sudo mount "${LD}p2" "$R"
echo "--- /lib/firmware 顶层 ---"; sudo ls "$R/lib/firmware/" 2>/dev/null | head -30
echo "--- 是否已有 wcnmodem ---"; sudo find "$R/lib/firmware" -iname '*wcn*' 2>/dev/null
sudo umount "$R"; sudo losetup -d "$LD"; rmdir "$R"
echo DONE-FW
} > "$OUT" 2>&1
echo wrote "$OUT"
