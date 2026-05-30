#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output

sudo losetup -D
LD=$(sudo losetup -f -P --show "$IMG")
echo "loop=$LD"
R=$(mktemp -d)
sudo mount "${LD}p2" "$R"

echo "=== 写入 /etc/config/network (eth0 -> br-lan, 192.168.1.1, 单口LAN) ==="
sudo tee "$R/etc/config/network" >/dev/null <<'NETEOF'
config interface 'loopback'
	option device 'lo'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'

config globals 'globals'
	option ula_prefix 'fd00:ab:cd::/48'

config device
	option name 'br-lan'
	option type 'bridge'
	list ports 'eth0'

config interface 'lan'
	option device 'br-lan'
	option proto 'static'
	option ipaddr '192.168.1.1'
	option netmask '255.255.255.0'
	option ip6assign '60'
NETEOF

echo "=== 兜底: 首启动 uci-defaults 强制 lan 配置 (防 config_generate 覆盖) ==="
sudo tee "$R/etc/uci-defaults/99-zero3-lan" >/dev/null <<'UCIEOF'
#!/bin/sh
uci -q batch <<'EOF'
set network.lan=interface
set network.lan.proto='static'
set network.lan.ipaddr='192.168.1.1'
set network.lan.netmask='255.255.255.0'
set network.lan.device='br-lan'
delete network.brlan
set network.brlan=device
set network.brlan.name='br-lan'
set network.brlan.type='bridge'
add_list network.brlan.ports='eth0'
delete network.wan
delete network.wan6
commit network
EOF
exit 0
UCIEOF
sudo chmod +x "$R/etc/uci-defaults/99-zero3-lan"

echo "=== 安全起见: 自动加载以太网驱动 dwmac-sun8i ==="
echo 'dwmac-sun8i' | sudo tee "$R/etc/modules.d/30-dwmac-sun8i" >/dev/null

echo "=== 校验 ==="
echo "--- network ---"; sudo cat "$R/etc/config/network"
echo "--- uci-defaults ---"; sudo ls "$R/etc/uci-defaults/" | grep zero3
echo "--- modules.d ---"; sudo cat "$R/etc/modules.d/30-dwmac-sun8i"

sudo umount "$R"
sudo losetup -d "$LD"
rmdir "$R"

echo "=== 重新导出压缩镜像 ==="
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "FIX-NET-DONE"
