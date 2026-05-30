#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-31-wifidt.txt
sudo losetup -D
LD=$(sudo losetup -f -P --show "$IMG")
R=$(mktemp -d); B=$(mktemp -d)
sudo mount "${LD}p2" "$R"
sudo mount "${LD}p1" "$B"
DTB="$B/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb"
{
  echo "===== DTB 是否含 unisoc-wifi / sprd / sdio / sunxi-wlan 节点 ====="
  sudo strings "$DTB" | grep -iE 'unisoc-wifi|sprd|sdio|wlan|wifi|uwe5622|bluetooth|sprd-marlin|allwinner-rfkill|sunxi-wlan|gpio.*wl' | sort -u
  echo "===== 用 dtc 反编译看 wifi 相关节点 (若有 dtc) ====="
  if command -v dtc >/dev/null; then
    sudo dtc -I dtb -O dts "$DTB" 2>/dev/null > /tmp/zero3.dts
    grep -niE 'unisoc-wifi|sprd|sdio|wlan|sunxi-wlan|sunxi-rfkill|sip_sdio|sdc1|mmc1|bluetooth' /tmp/zero3.dts | head -60
  else
    echo "(no dtc)"
  fi
  echo "===== sunxi_addr 模块是否存在 ====="
  sudo find "$R/lib/modules/$KVER/" -iname 'sunxi_addr*' -o -iname 'sunxi-addr*' 2>/dev/null
  echo "===== uwe5622_bsp_sdio modinfo ====="
  sudo modinfo "$R/lib/modules/$KVER/uwe5622_bsp_sdio.ko" 2>/dev/null | grep -iE 'depends|firmware|alias' | head
  echo "===== sprdwl_ng modinfo 完整 ====="
  sudo modinfo "$R/lib/modules/$KVER/sprdwl_ng.ko" 2>/dev/null | grep -iE 'depends|firmware|alias|parm' | head -20
  echo "===== modules.dep 里 sprdwl/uwe5622/sunxi_addr 关系 ====="
  sudo grep -iE 'sprdwl_ng|uwe5622_bsp_sdio|sunxi_addr' "$R/lib/modules/$KVER/modules.dep" 2>/dev/null
  echo "===== 是否有 sunxi-rfkill / 蓝牙相关 ko ====="
  sudo ls "$R/lib/modules/$KVER/" | grep -iE 'rfkill|sprdbt|sunxi' || echo none
} > "$OUT" 2>&1
sudo umount "$B"; sudo umount "$R"; sudo losetup -d "$LD"; rmdir "$R" "$B"
echo DONE
