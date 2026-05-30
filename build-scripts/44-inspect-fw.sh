#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-44-fwfmt.txt
K=/home/zrm/build/orangepi-build/kernel/orange-pi-6.1-sun50iw9
HEX="$K/drivers/net/wireless/uwe5622/unisocwcn/fw/wcnmodem.bin.hex"
H="$K/drivers/net/wireless/uwe5622/unisocwcn/boot/marlin_firmware_bin.h"
{
echo "=== bsp 固件目录内容 ==="
sudo ls -la /home/zrm/build/orangepi-build/external/packages/bsp/ky/usr/lib/firmware/ 2>/dev/null
sudo find /home/zrm/build/orangepi-build/external -iname '*wcnmodem*' -o -iname '*.bin' 2>/dev/null | grep -iE 'wcn|marlin|uwe' | head

echo
echo "=== wcnmodem.bin.hex : 大小 + 前几行 (判断格式) ==="
sudo ls -l "$HEX"
sudo head -c 300 "$HEX" | sed -n '1,8p'
echo
echo "...(hexdump前32字节)..."
sudo head -c 64 "$HEX" | od -An -c | head

echo
echo "=== marlin_firmware_bin.h : 大小 + 前几行 ==="
sudo ls -l "$H"
sudo head -n 12 "$H"

echo
echo "=== 在 fw 目录看有无 Makefile/转换脚本 ==="
sudo ls -la "$K/drivers/net/wireless/uwe5622/unisocwcn/fw/" 2>/dev/null

echo
echo "=== 全盘再找一次真正的 wcnmodem.bin (含 / 下其它位置) ==="
sudo find / -xdev -iname 'wcnmodem.bin' 2>/dev/null | head
echo DONE-FMT
} > "$OUT" 2>&1
echo wrote "$OUT"
