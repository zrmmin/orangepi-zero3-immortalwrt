#!/usr/bin/env bash
# 撤掉会卡死 sprdwl 的 wifi-scripts 自动探测, 恢复独立 hostapd AP,
# 并加 luci-app-zero3ap: 在 LuCI 里改 SSID/密码/信道/隐藏/开关 (保存即生效)
# 保留双WAN/USB共享等网络改动。不重打 rootfs, 直接改现有镜像 p2。
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
IMM=/home/zrm/build/immortalwrt
LIST=$(find "$IMM" -name 'wifi-scripts.list' 2>/dev/null | head -1)

[ -f "$IMG" ] || { echo "镜像不存在"; exit 1; }

sudo losetup -D 2>/dev/null || true
LD=$(sudo losetup -f -P --show "$IMG"); echo "loop=$LD"
B=$(mktemp -d); sudo mount "${LD}p2" "$B"

echo "=== [1] 删除 wifi-scripts 文件(含 hotplug 自动探测=卡死真凶) ==="
if [ -f "$LIST" ]; then
  while read -r f; do
    [ -z "$f" ] && continue
    case "$f" in
      /usr/bin/iwinfo|/usr/share/ucode/iwinfo.uc) continue;;   # 保留原C版iwinfo
    esac
    sudo rm -f "$B$f"
  done < "$LIST"
fi
# 兜底显式删 hotplug 探测与空目录
sudo rm -f "$B/etc/hotplug.d/ieee80211/10-wifi-detect" "$B/etc/hotplug.d/ieee80211/11-ath12k-trigger"
sudo rm -f "$B/sbin/wifi"
sudo rm -rf "$B/usr/share/ucode/wifi" "$B/usr/share/hostap" "$B/lib/wifi/mac80211.uc" \
            "$B/lib/netifd/wireless" "$B/lib/netifd/wireless.uc" "$B/lib/netifd/wireless-device.uc" \
            "$B/lib/netifd/netifd-wireless.sh" "$B/lib/netifd/hostapd.sh"
echo "确认 hotplug 已清:"; sudo ls "$B/etc/hotplug.d/ieee80211/" 2>/dev/null || echo "  (目录已空/不存在 → OK)"
echo "确认 /sbin/wifi 已删:"; [ -e "$B/sbin/wifi" ] && echo "  仍在!" || echo "  OK"

echo "=== [2] 删自动配 wifi 的 uci-defaults(若残留) ==="
sudo rm -f "$B/etc/uci-defaults/99-zero3-wifi"

echo "=== [3] 写 UCI 配置 /etc/config/zero3ap ==="
sudo tee "$B/etc/config/zero3ap" >/dev/null <<'UCEOF'
config zero3ap 'config'
	option enabled '1'
	option ssid 'OrangePi-Zero3'
	option encryption 'psk2'
	option key '12345678'
	option channel '6'
	option hidden '0'
	option country 'CN'
UCEOF

echo "=== [4] 重写 /etc/init.d/zero3-ap: 由 UCI 生成 hostapd 配置 + reload 触发 ==="
sudo tee "$B/etc/init.d/zero3-ap" >/dev/null <<'INITEOF'
#!/bin/sh /etc/rc.common
# 板载 UWE5622 AP: 独立 hostapd, 配置来自 UCI(/etc/config/zero3ap), 由 luci-app-zero3ap 管理
START=99
STOP=10
USE_PROCD=1
CONF=/etc/hostapd-wlan0.conf

gen_conf() {
	config_load zero3ap
	local ssid key channel hidden encryption country
	config_get ssid       config ssid       'OrangePi-Zero3'
	config_get key        config key         '12345678'
	config_get channel    config channel     '6'
	config_get hidden     config hidden      '0'
	config_get encryption config encryption  'psk2'
	config_get country    config country     'CN'
	{
		echo "interface=wlan0"
		echo "bridge=br-lan"
		echo "driver=nl80211"
		echo "ctrl_interface=/var/run/hostapd"
		echo "ctrl_interface_group=0"
		echo "hw_mode=g"
		echo "channel=$channel"
		echo "country_code=$country"
		echo "ieee80211d=1"
		echo "ieee80211n=1"
		echo "wmm_enabled=1"
		echo "ssid=$ssid"
		[ "$hidden" = "1" ] && echo "ignore_broadcast_ssid=1"
		echo "auth_algs=1"
		if [ "$encryption" = "psk2" ]; then
			echo "wpa=2"
			echo "wpa_key_mgmt=WPA-PSK"
			echo "rsn_pairwise=CCMP"
			echo "wpa_passphrase=$key"
		fi
	} > "$CONF"
}

start_service() {
	config_load zero3ap
	local enabled; config_get enabled config enabled '1'
	[ "$enabled" = "1" ] || { logger -t zero3-ap "AP 已在配置中禁用, 不启动"; return 0; }

	local i=0
	while [ ! -e /sys/class/net/wlan0 ] && [ "$i" -lt 25 ]; do
		modprobe sprdwl_ng 2>/dev/null; sleep 1; i=$((i+1))
	done
	[ -e /sys/class/net/wlan0 ] || { logger -t zero3-ap "wlan0 未出现, 跳过"; return 0; }

	local mac; mac=$(cat /sys/class/net/wlan0/address 2>/dev/null)
	if [ "$mac" = "00:00:00:00:00:00" ] || [ -z "$mac" ]; then
		local base o1 rest newo1 newmac
		base=$(cat /sys/class/net/eth0/address 2>/dev/null)
		if [ -n "$base" ]; then
			o1=$(echo "$base" | cut -d: -f1); rest=$(echo "$base" | cut -d: -f2-6)
			newo1=$(printf '%02x' $(( (0x$o1 | 2) & 0xfe ))); newmac="$newo1:$rest"
		else
			newmac="02:e0:4c:00:11:22"
		fi
		ip link set wlan0 down 2>/dev/null
		ip link set wlan0 address "$newmac" 2>/dev/null
		logger -t zero3-ap "已设置 wlan0 MAC=$newmac"
	fi

	gen_conf

	procd_open_instance
	procd_set_param command /usr/sbin/hostapd "$CONF"
	procd_set_param respawn 3600 5 0
	procd_set_param stderr 1
	procd_close_instance
}

stop_service() {
	killall hostapd 2>/dev/null
	ip link set wlan0 down 2>/dev/null
}

service_triggers() {
	procd_add_reload_trigger "zero3ap"
}

reload_service() {
	stop_service
	sleep 1
	start_service
}
INITEOF
sudo chmod 755 "$B/etc/init.d/zero3-ap"

echo "=== [5] 恢复 zero3-ap 开机自启 (S99) ==="
sudo ln -sf ../init.d/zero3-ap "$B/etc/rc.d/S99zero3-ap"
sudo ls -l "$B/etc/rc.d/S99zero3-ap"

echo "=== [6] luci-app-zero3ap: 菜单 ==="
sudo mkdir -p "$B/usr/share/luci/menu.d"
sudo tee "$B/usr/share/luci/menu.d/luci-app-zero3ap.json" >/dev/null <<'MENUEOF'
{
	"admin/network/zero3ap": {
		"title": "板载 AP (WiFi)",
		"order": 15,
		"action": { "type": "view", "path": "zero3ap/settings" },
		"depends": { "acl": [ "luci-app-zero3ap" ] }
	}
}
MENUEOF

echo "=== [7] luci-app-zero3ap: ACL ==="
sudo mkdir -p "$B/usr/share/rpcd/acl.d"
sudo tee "$B/usr/share/rpcd/acl.d/luci-app-zero3ap.json" >/dev/null <<'ACLEOF'
{
	"luci-app-zero3ap": {
		"description": "管理板载 AP (zero3ap)",
		"read":  { "uci": [ "zero3ap" ] },
		"write": { "uci": [ "zero3ap" ] }
	}
}
ACLEOF

echo "=== [8] luci-app-zero3ap: 视图 JS ==="
sudo mkdir -p "$B/www/luci-static/resources/view/zero3ap"
sudo tee "$B/www/luci-static/resources/view/zero3ap/settings.js" >/dev/null <<'JSEOF'
'use strict';
'require view';
'require form';
'require uci';

return view.extend({
	load: function() {
		return uci.load('zero3ap');
	},
	render: function() {
		var m, s, o;
		m = new form.Map('zero3ap', _('板载 AP (WiFi)'),
			_('管理板载 UWE5622 无线热点(独立 hostapd,绕开 netifd,稳定可靠)。保存并应用后会自动重启 AP。'));

		s = m.section(form.NamedSection, 'config', 'zero3ap', _('热点设置'));
		s.anonymous = true;

		o = s.option(form.Flag, 'enabled', _('启用 AP'));
		o.default = '1';
		o.rmempty = false;

		o = s.option(form.Value, 'ssid', _('网络名称 (SSID)'));
		o.datatype = 'maxlength(32)';
		o.rmempty = false;

		o = s.option(form.ListValue, 'encryption', _('加密方式'));
		o.value('psk2', 'WPA2-PSK');
		o.value('none', _('无加密(开放网络)'));
		o.default = 'psk2';

		o = s.option(form.Value, 'key', _('Wi-Fi 密码'));
		o.password = true;
		o.datatype = 'wpakey';
		o.depends('encryption', 'psk2');

		o = s.option(form.ListValue, 'channel', _('信道 (2.4GHz)'));
		for (var i = 1; i <= 13; i++) o.value(String(i), String(i));
		o.default = '6';

		o = s.option(form.Flag, 'hidden', _('隐藏 SSID'));
		o.default = '0';

		o = s.option(form.Value, 'country', _('国家代码'));
		o.datatype = 'maxlength(2)';
		o.default = 'CN';

		return m.render();
	}
});
JSEOF

sync
sudo umount "$B"; rmdir "$B"; sudo losetup -d "$LD"

echo "=== [9] 重新导出 ==="
mkdir -p "$OUT_WIN"
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"/*.img.gz; cat "$OUT_WIN"/*.img.gz.sha256
echo "LUCI-APP-AP-DONE"
