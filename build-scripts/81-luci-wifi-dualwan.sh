#!/usr/bin/env bash
# 总装: 让板载 AP 进 LuCI(netifd/wifi-scripts) + LAN=AP + 双WAN(eth0网线/usb0手机USB)自动切换 + NAT
# 不重打 rootfs, 直接改现有镜像 p2
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
IMM=/home/zrm/build/immortalwrt
ROOT=$IMM/staging_dir/target-aarch64_generic_musl/root-armsr
LIST=$(find "$IMM" -name 'wifi-scripts.list' 2>/dev/null | head -1)

[ -f "$IMG" ] || { echo "镜像不存在"; exit 1; }
[ -d "$ROOT" ] || { echo "staging root 不存在"; exit 1; }
[ -f "$LIST" ] || { echo "wifi-scripts.list 不存在"; exit 1; }
[ -f "$ROOT/usr/lib/ucode/digest.so" ] || { echo "digest.so 不存在"; exit 1; }

sudo losetup -D 2>/dev/null || true
LD=$(sudo losetup -f -P --show "$IMG"); echo "loop=$LD"
B=$(mktemp -d); sudo mount "${LD}p2" "$B"

echo "=== [1] 注入 wifi-scripts 文件(按清单, 跳过会覆盖C版iwinfo的两项) ==="
n=0
while read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    /usr/bin/iwinfo|/usr/share/ucode/iwinfo.uc) continue;;
  esac
  if [ -e "$ROOT$f" ]; then
    sudo mkdir -p "$B$(dirname "$f")"
    sudo cp -a "$ROOT$f" "$B$f"
    n=$((n+1))
  else
    echo "  !! staging 缺 $f"
  fi
done < "$LIST"
echo "  已复制 $n 个 wifi-scripts 文件"
sudo cp -a "$ROOT/usr/lib/ucode/digest.so" "$B/usr/lib/ucode/digest.so"
echo "  digest.so 已就位: $(sudo ls -l "$B/usr/lib/ucode/digest.so" | awk '{print $5}') 字节"

echo "=== [2] 写 /etc/config/network (LAN=br-lan(AP) + WAN=eth0 + WANUSB=usb0) ==="
sudo tee "$B/etc/config/network" >/dev/null <<'NETEOF'
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

config interface 'lan'
	option device 'br-lan'
	option proto 'static'
	option ipaddr '192.168.1.1'
	option netmask '255.255.255.0'
	option ip6assign '60'

config interface 'wan'
	option device 'eth0'
	option proto 'dhcp'
	option metric '10'

config interface 'wan6'
	option device 'eth0'
	option proto 'dhcpv6'

config interface 'wanusb'
	option device 'usb0'
	option proto 'dhcp'
	option metric '20'
NETEOF

echo "=== [3] 防火墙: wan 区加入 wanusb ==="
if ! sudo grep -q "'wanusb'" "$B/etc/config/firewall"; then
  sudo cp "$B/etc/config/firewall" /tmp/fw.in
  awk -v q="'" '
    { print }
    /option name[ \t]+wan$/ { z=1 }
    z && /list[ \t]+network[ \t]+.wan6./ {
      print "\tlist   network\t\t" q "wanusb" q
      z=0
    }
  ' /tmp/fw.in | sudo tee "$B/etc/config/firewall" >/dev/null
fi
echo "确认 wan 区 network:"; sudo grep -n "network" "$B/etc/config/firewall" | head -6

echo "=== [4] dhcp: wanusb 忽略 DHCP server ==="
if ! sudo grep -q "config dhcp 'wanusb'" "$B/etc/config/dhcp"; then
sudo tee -a "$B/etc/config/dhcp" >/dev/null <<'DHEOF'

config dhcp 'wanusb'
	option interface 'wanusb'
	option ignore '1'
DHEOF
fi

echo "=== [5] USB tether 模块开机自启 ==="
sudo tee "$B/etc/modules.d/60-usb-tether" >/dev/null <<'MODEOF'
usbnet
cdc_ether
rndis_host
cdc_ncm
ipheth
MODEOF

echo "=== [6] uci-defaults: 首启生成并配置 AP(netifd/LuCI 管理) ==="
sudo tee "$B/etc/uci-defaults/99-zero3-wifi" >/dev/null <<'UDEOF'
#!/bin/sh
# 首次启动: 探测板载 wifi phy, 生成 /etc/config/wireless 并配成 AP(桥接 LAN)
[ -e /sys/class/ieee80211/phy0 ] || modprobe sprdwl_ng 2>/dev/null
i=0
while [ ! -e /sys/class/ieee80211/phy0 ] && [ "$i" -lt 20 ]; do sleep 1; i=$((i+1)); done
[ -e /sys/class/ieee80211/phy0 ] || exit 1   # phy 没出现, 下次启动重试

/sbin/wifi config 2>/dev/null

if uci -q get wireless.radio0 >/dev/null; then
	uci set wireless.radio0.disabled='0'
	uci set wireless.radio0.country='CN'
	uci set wireless.radio0.channel='6'
	uci set wireless.radio0.band='2g'
	uci set wireless.radio0.htmode='HT20'
	if uci -q get wireless.default_radio0 >/dev/null; then
		uci set wireless.default_radio0.mode='ap'
		uci set wireless.default_radio0.ssid='OrangePi-Zero3'
		uci set wireless.default_radio0.encryption='psk2'
		uci set wireless.default_radio0.key='12345678'
		uci set wireless.default_radio0.network='lan'
		uci -q delete wireless.default_radio0.disabled
	fi
	uci commit wireless
	exit 0
fi
exit 1
UDEOF
sudo chmod +x "$B/etc/uci-defaults/99-zero3-wifi"

echo "=== [7] 停用独立 zero3-ap(保留文件作兜底, 仅去掉自启) ==="
sudo rm -f "$B/etc/rc.d/S99zero3-ap"
echo "  /etc/init.d/zero3-ap 文件保留(回滚用): $(sudo ls "$B/etc/init.d/zero3-ap" 2>/dev/null)"

echo "=== [8] 放回滚说明脚本 /root/wifi-rollback.sh ==="
sudo tee "$B/root/wifi-rollback.sh" >/dev/null <<'RBEOF'
#!/bin/sh
# 若 LuCI/netifd 管理的 AP 起不来, 用本脚本回退到独立 hostapd AP(已验证可用)
echo "禁用 netifd 无线, 启用独立 hostapd AP..."
uci -q set wireless.radio0.disabled='1' 2>/dev/null; uci -q commit wireless 2>/dev/null
/etc/init.d/zero3-ap enable
/etc/init.d/zero3-ap start
echo "完成。SSID=OrangePi-Zero3 密码=12345678。如仍异常请 reboot。"
RBEOF
sudo chmod +x "$B/root/wifi-rollback.sh"

sync
sudo umount "$B"; rmdir "$B"; sudo losetup -d "$LD"

echo "=== [9] 重新导出 ==="
mkdir -p "$OUT_WIN"
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"; cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "LUCI-WIFI-DUALWAN-DONE"
