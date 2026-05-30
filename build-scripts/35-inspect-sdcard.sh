#!/usr/bin/env bash
set -uo pipefail
M=$(ls -d /mnt/wsl/PHYSICALDRIVE3p2 2>/dev/null || true)
echo "wsl mountpoint=[$M]"
ls -la /mnt/wsl/ 2>/dev/null || true

if [ -z "$M" ]; then
  echo "=== not under /mnt/wsl, try manual mount of attached disk ==="
  # find the attached block device (btrfs)
  lsblk -f 2>/dev/null | grep -iE 'sd|btrfs' || true
  DEV=$(lsblk -rno NAME,FSTYPE 2>/dev/null | awk '$2=="btrfs"{print "/dev/"$1; exit}')
  echo "btrfs dev=[$DEV]"
  if [ -n "$DEV" ]; then
    MP=/tmp/sdroot; sudo mkdir -p "$MP"; sudo mount "$DEV" "$MP" && M="$MP"
  fi
fi

if [ -z "$M" ]; then echo "STILL NOT MOUNTED"; exit 1; fi

echo "============================================="
echo "ROOT = $M"
echo "=== [关键] /etc/uci-defaults (若我的98/99还在=首启动没跑) ==="
sudo ls -la "$M/etc/uci-defaults/" 2>&1
echo "=== /etc/config/network ==="; sudo cat "$M/etc/config/network" 2>&1
echo "=== /etc/config/wireless 是否生成 ==="; sudo cat "$M/etc/config/wireless" 2>&1 || echo "(无)"
echo "=== 是否有 btrfs 底下隐藏的 /boot/zero3-diag.log ==="; sudo ls -la "$M/boot/" 2>&1 | head
echo "=== /root/first_run.log (首启动应用环境日志) ==="; sudo cat "$M/root/first_run.log" 2>&1 | tail -30
echo "=== 任何启动痕迹: /etc/board.json, /tmp 不在卡上; 看 /etc/openwrt_release ==="; sudo cat "$M/etc/openwrt_release" 2>&1 | head -5
echo "=== overlay/快照 .snapshots ==="; sudo ls -la "$M/.snapshots/" 2>&1 | head
echo "DONE-INSPECT"
