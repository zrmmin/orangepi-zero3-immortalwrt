#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-47-parse.txt
F=/home/zrm/build/orangepi-build/kernel/orange-pi-6.1-sun50iw9/drivers/net/wireless/uwe5622/unisocwcn/platform/wcn_boot.c
{
echo "=== struct/magic 区域 (280-360) ==="
sudo sed -n '280,360p' "$F"
echo
echo "=== parse_image 与 request_firmware (980-1260) ==="
sudo sed -n '980,1260p' "$F"
} > "$OUT" 2>&1
echo wrote
