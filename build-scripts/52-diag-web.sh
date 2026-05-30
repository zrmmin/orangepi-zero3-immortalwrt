#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-52-web.txt
OD=/home/zrm/build/openwrt_packit/output
{
echo "=== 找最新镜像 ==="
IMG=$(ls -t "$OD"/*.img 2>/dev/null | head -1)
echo "IMG=$IMG"
[ -z "$IMG" ] && { echo "no img"; exit 0; }

LD=$(sudo losetup -fP --show "$IMG")
echo "loop=$LD"
sleep 1
MP=/tmp/r52
sudo mkdir -p "$MP"
# rootfs 是 p2 (btrfs)
sudo mount -o ro "${LD}p2" "$MP" 2>/dev/null || sudo mount -o ro "${LD}p2" "$MP"
echo "--- 挂载结果 ---"; mount | grep r52 || true

echo; echo "=== uhttpd 二进制/服务 ==="
ls -l "$MP/usr/sbin/uhttpd" 2>/dev/null || echo "NO /usr/sbin/uhttpd"
ls -l "$MP/etc/init.d/uhttpd" 2>/dev/null || echo "NO init.d/uhttpd"
ls -l "$MP/etc/rc.d/"*uhttpd* 2>/dev/null || echo "NO rc.d uhttpd (未开机启用)"
echo "--- /etc/config/uhttpd ---"; sudo cat "$MP/etc/config/uhttpd" 2>/dev/null | head -40 || echo "no uhttpd config"

echo; echo "=== luci / rpcd / ubus ==="
ls -ld "$MP/www" "$MP/www/luci-static" 2>/dev/null
ls -l "$MP/usr/sbin/rpcd" 2>/dev/null || echo "NO rpcd"
ls -l "$MP/etc/rc.d/"*rpcd* 2>/dev/null || echo "NO rc.d rpcd"
ls -l "$MP/usr/lib/lua/luci" 2>/dev/null | head -5 || echo "NO luci lua"
echo "--- luci-mod-admin / luci-base 痕迹 ---"
ls "$MP/usr/lib/lua/luci/" 2>/dev/null | head
sudo cat "$MP/usr/lib/opkg/status" 2>/dev/null | grep -A1 -iE "Package: (luci-base|luci-mod-admin|uhttpd|luci-ssl|rpcd|dnsmasq|odhcpd)" | head -40

echo; echo "=== 开机启用的服务 (rc.d) ==="
ls "$MP/etc/rc.d/" 2>/dev/null

echo; echo "=== 防火墙 input 策略 ==="
sudo sed -n '1,40p' "$MP/etc/config/firewall" 2>/dev/null | head -50

echo; echo "=== network/dhcp 实际内容 ==="
sudo cat "$MP/etc/config/network" 2>/dev/null
echo "--- dhcp ---"
sudo sed -n '1,40p' "$MP/etc/config/dhcp" 2>/dev/null

sudo umount "$MP" 2>/dev/null
sudo losetup -d "$LD" 2>/dev/null
} > "$OUT" 2>&1
echo wrote
