#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-50-consts.txt
K=/home/zrm/build/orangepi-build/kernel/orange-pi-6.1-sun50iw9
F=$K/drivers/net/wireless/uwe5622/unisocwcn/platform/wcn_boot.c
UW=$K/drivers/net/wireless/uwe5622
{
echo "=== CHIPID 常量定义 (整个 uwe5622 树) ==="
sudo grep -rn "MARLIN3_AA_CHIPID\|MARLIN3L_AA_CHIPID\|MARLIN3E_AA_CHIPID\|MARLIN_AA_CHIPID\b\|CHIPID_REG\b\|CHIPID_REG_M3E\|CHIPID_REG_M3_M3L" "$UW" 2>/dev/null | grep -E "#define" | head -40
echo
echo "=== wcn_boot.c #else 分支完整 switch (828-892) ==="
sudo sed -n '828,892p' "$F"
echo
echo "=== uwe5622 各级 Kconfig 内容 ==="
for kc in "$UW/Kconfig" "$UW/unisocwcn/Kconfig" "$UW/unisocwifi/Kconfig"; do
  echo "----- $kc -----"
  sudo cat "$kc"
done
echo
echo "=== orangepi defconfig 里 UWE5622 / CHECK_DRIVER 相关 ==="
sudo grep -rn "UWE5622\|CHECK_DRIVER_BY_CHIPID\|SPRDWL\|UMW\|SDIO_BSP" "$K/arch/arm64/configs/" 2>/dev/null | head -40
echo "--- 列出 configs 目录 ---"
sudo ls "$K/arch/arm64/configs/" 2>/dev/null | head
} > "$OUT" 2>&1
echo wrote
