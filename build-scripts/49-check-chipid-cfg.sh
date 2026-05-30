#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-49-chipid.txt
K=/home/zrm/build/orangepi-build/kernel/orange-pi-6.1-sun50iw9
F=$K/drivers/net/wireless/uwe5622/unisocwcn/platform/wcn_boot.c
{
echo "=== 芯片检测逻辑 (380-560) ==="
sudo sed -n '380,560p' "$F"
echo
echo "=== marlin_imageinfo_get_from_data (740,765) ==="
sudo sed -n '740,766p' "$F"
echo
echo "=== 当前内核 .config 里相关项 ==="
for c in CONFIG_CHECK_DRIVER_BY_CHIPID CONFIG_UWE5622 CONFIG_SDIO_BSP_UWE5622 CONFIG_WCN_SDIO CONFIG_WCN_DOWNLOAD_FIRMWARE_FROM_HEX CONFIG_SPRD_WLAN CONFIG_SPRDWL_NG CONFIG_AW_BOARD CONFIG_WCN_PARSE_DTS; do
  echo "--- $c ---"
  sudo grep -rn "$c" "$K/.config" 2>/dev/null
done
echo
echo "=== Kconfig 里 CHECK_DRIVER_BY_CHIPID 定义/依赖 ==="
sudo grep -rn "CHECK_DRIVER_BY_CHIPID" "$K/drivers/net/wireless/uwe5622" 2>/dev/null | head
echo
echo "=== uwe5622 相关 Kconfig/Makefile 顶层 ==="
sudo find "$K/drivers/net/wireless/uwe5622" -maxdepth 2 -name 'Kconfig' -o -maxdepth 2 -name 'Makefile' 2>/dev/null | head
} > "$OUT" 2>&1
echo wrote
