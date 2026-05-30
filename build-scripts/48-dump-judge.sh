#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-48-judge.txt
F=/home/zrm/build/orangepi-build/kernel/orange-pi-6.1-sun50iw9/drivers/net/wireless/uwe5622/unisocwcn/platform/wcn_boot.c
{
echo "=== marlin_judge_images / bin_magic_is / marlin_get_wcn_chipid / marlin_fw_get_img_count 等函数 ==="
sudo grep -n "marlin_judge_images\|bin_magic_is\|marlin_get_wcn_chipid\|marlin_fw_get_img_count\|marlin_firmware_get_combin_info\|wcn_get_chip_type\|MARLIN3E\|g_match_tag\|tag_name\|CONFIG_UMW\|CONFIG_CHECK_DRIVER_BY_CHIPID\|functionmask" "$F" | head -80
echo
echo "=== 定义 marlin_judge_images 的完整函数 (按行号附近导出) ==="
LN=$(sudo grep -n "marlin_judge_images" "$F" | head -1 | cut -d: -f1)
echo "first ref line=$LN"
# 找函数定义行
DEF=$(sudo grep -n "marlin_judge_images(" "$F" | grep -iE "imageinfo|struct|static" | head -1 | cut -d: -f1)
echo "def line=$DEF"
if [ -n "$DEF" ]; then sudo sed -n "$((DEF-2)),$((DEF+70))p" "$F"; fi
} > "$OUT" 2>&1
echo wrote
