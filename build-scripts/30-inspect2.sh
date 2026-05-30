#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-30-inspect2.txt
sudo losetup -D
LD=$(sudo losetup -f -P --show "$IMG")
R=$(mktemp -d); B=$(mktemp -d)
sudo mount "${LD}p2" "$R"
sudo mount "${LD}p1" "$B"
{
  echo "loop=$LD"
  echo "===== /etc/config/fstab ====="; sudo cat "$R/etc/config/fstab" 2>/dev/null
  echo "===== /etc/fstab ====="; sudo cat "$R/etc/fstab" 2>/dev/null
  echo "===== rc.d (dropbear/uhttpd/wpad/wifi) ====="; sudo ls "$R/etc/rc.d/" 2>/dev/null | grep -iE 'dropbear|uhttpd|wpad|wireless|sysntpd|boot'
  echo "===== /etc/config/wireless exists? ====="; sudo ls -l "$R/etc/config/wireless" 2>/dev/null || echo "NO wireless config"
  echo "===== wpad/hostapd/wpa_supplicant ====="; sudo ls "$R/usr/sbin/" 2>/dev/null | grep -iE 'wpad|hostapd|wpa_supplicant'
  echo "===== cfg80211/mac80211/wifi kmod ====="; sudo ls "$R/lib/modules/$KVER/" 2>/dev/null | grep -iE 'cfg80211|mac80211|sprdwl|uwe5622|sprdbt'
  echo "===== /etc/modules.d list ====="; sudo ls "$R/etc/modules.d/" 2>/dev/null
  echo "===== /etc/rc.local ====="; sudo cat "$R/etc/rc.local" 2>/dev/null
  echo "===== BOOT: uEnv.txt ====="; sudo cat "$B/uEnv.txt" 2>/dev/null
  echo "===== BOOT: boot.cmd ====="; sudo cat "$B/boot.cmd" 2>/dev/null
  echo "===== BOOT files ====="; sudo ls -l "$B" 2>/dev/null
  echo "===== sprdwl_ng modinfo (firmware/depends) ====="; sudo modinfo "$R/lib/modules/$KVER/sprdwl_ng.ko" 2>/dev/null | grep -iE 'depends|firmware|alias|filename' | head
  echo "===== board_name hint (DTB model) ====="; sudo strings "$B/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb" 2>/dev/null | grep -iE 'orangepi|allwinner,|model' | head
} > "$OUT" 2>&1
sudo umount "$B"; sudo umount "$R"; sudo losetup -d "$LD"; rmdir "$R" "$B"
echo DONE
