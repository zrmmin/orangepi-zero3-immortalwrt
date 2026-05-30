#!/usr/bin/env bash
set -uo pipefail
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k6.1.31-sun50iw9.img
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-28-net.txt
sudo losetup -D
LD=$(sudo losetup -f -P --show "$IMG")
R=$(mktemp -d)
sudo mount "${LD}p2" "$R"
{
  echo "loop=$LD"
  echo "===== /etc/config/network ====="
  sudo cat "$R/etc/config/network" 2>/dev/null
  echo "===== /etc/config/dhcp (1..60) ====="
  sudo sed -n '1,60p' "$R/etc/config/dhcp" 2>/dev/null
  echo "===== board.d/02_network ====="
  sudo sed -n '1,80p' "$R/etc/board.d/02_network" 2>/dev/null
  echo "===== uci-defaults ====="
  sudo ls "$R/etc/uci-defaults/" 2>/dev/null
  echo "===== rc.d (net related) ====="
  sudo ls "$R/etc/rc.d/" 2>/dev/null | grep -iE 'odhcpd|dnsmasq|network|firewall|uhttpd'
  echo "===== eth kmod ====="
  sudo ls "$R/lib/modules/6.1.31-sun50iw9/" 2>/dev/null | grep -iE 'dwmac|sun8i|stmmac|realtek' || echo "(none as module -> builtin)"
} > "$OUT" 2>&1
sudo umount "$R"
sudo losetup -d "$LD"
rmdir "$R"
echo DONE
