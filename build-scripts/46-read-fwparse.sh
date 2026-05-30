#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-46-fwparse.txt
K=/home/zrm/build/orangepi-build/kernel/orange-pi-6.1-sun50iw9
UWCN="$K/drivers/net/wireless/uwe5622/unisocwcn"
{
echo "=== bin2hex.c (确认 hex 格式) ==="
sudo cat "$UWCN/fw/bin2hex.c"
echo
echo "=== firmware_hex.h ==="
sudo cat "$UWCN/fw/firmware_hex.h"
echo
echo "=== version.txt ==="
sudo cat "$UWCN/fw/version.txt"
echo
echo "=== 搜索 'imginfo is NULL' 与 parse 函数所在文件 ==="
sudo grep -rn "imginfo is NULL" "$UWCN" 2>/dev/null
sudo grep -rln "marlin_firmware_parse_image" "$UWCN" 2>/dev/null
echo
echo "=== 搜索 WCNM 魔数处理 / firmware_hex 引用 ==="
sudo grep -rn "WCNM\|firmware_hex\|marlin_firmware_bin\|wcnmodem" "$UWCN" 2>/dev/null | grep -iE '\.c:|\.h:' | head -40
} > "$OUT" 2>&1
echo wrote "$OUT"
