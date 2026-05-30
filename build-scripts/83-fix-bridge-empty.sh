#!/usr/bin/env bash
# 最终修复: 给 br-lan 网桥加 option bridge_empty '1'
# 让 netifd 在开机时创建"无端口空网桥"并配好 192.168.1.1, 之后 hostapd 再把 wlan0 加入。
# 解决"手机连上但拿不到IP"(空网桥没被 netifd 建/配 → dnsmasq 不发 DHCP)。
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output

[ -f "$IMG" ] || { echo "镜像不存在"; exit 1; }
sudo losetup -D 2>/dev/null || true
LD=$(sudo losetup -f -P --show "$IMG"); echo "loop=$LD"
B=$(mktemp -d); sudo mount "${LD}p2" "$B"

NET="$B/etc/config/network"
if sudo grep -q "bridge_empty" "$NET"; then
  echo "已存在 bridge_empty, 跳过"
else
  # 在 br-lan 桥的 option type 'bridge' 之后插入 bridge_empty
  sudo cp "$NET" /tmp/net.in
  awk "
    { print }
    /option name 'br-lan'/ { inbr=1 }
    inbr && /option type 'bridge'/ { print \"\toption bridge_empty '1'\"; inbr=0 }
  " /tmp/net.in | sudo tee "$NET" >/dev/null
fi
echo "=== 确认 br-lan 段 ==="
sudo awk "/config device/{p=1} p{print} /option bridge_empty/{p=0}" "$NET" | head -6

sync
sudo umount "$B"; rmdir "$B"; sudo losetup -d "$LD"

echo "=== 重新导出 ==="
mkdir -p "$OUT_WIN"
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"/*.img.gz; cat "$OUT_WIN"/*.img.gz.sha256
echo "FIX-BRIDGE-EMPTY-DONE"
