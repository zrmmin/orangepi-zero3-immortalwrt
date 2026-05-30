#!/usr/bin/env bash
# 板载WiFi修复: 换正确的 WCNE 固件 + 重新启用驱动自启 + 自包含 hostapd AP(开机自动开)
# 直接在已构建好的 packit 镜像上原地处理, 无需重编内核/rootfs
set -uo pipefail
KVER=6.1.31-sun50iw9
FW_WCNE=/home/zrm/build/wcnmodem_wcne.bin
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output

# ---- 前置校验 ----
[ -f "$IMG" ] || { echo "镜像不存在: $IMG"; exit 1; }
[ -f "$FW_WCNE" ] || { echo "WCNE固件不存在: $FW_WCNE"; exit 1; }
MAGIC=$(head -c 4 "$FW_WCNE" | od -An -tx1 | tr -d ' \n')
if [ "$MAGIC" != "57434e45" ]; then
  echo "!! 固件 magic 非 WCNE (得到 $MAGIC, 期望 57434e45), 终止"; exit 1
fi
echo "固件校验 OK: WCNE, 大小 $(stat -c%s "$FW_WCNE") 字节"

sudo losetup -D 2>/dev/null || true
LD=$(sudo losetup -f -P --show "$IMG")
echo "loop=$LD"
R=$(mktemp -d)
sudo mount "${LD}p2" "$R"

echo "=== [1] 写入正确的 WCNE 固件 (覆盖之前错误的WCNM) ==="
sudo mkdir -p "$R/lib/firmware/uwe5622"
sudo cp -f "$FW_WCNE" "$R/lib/firmware/wcnmodem.bin"
sudo cp -f "$FW_WCNE" "$R/lib/firmware/uwe5622/wcnmodem.bin"
sudo chmod 644 "$R/lib/firmware/wcnmodem.bin" "$R/lib/firmware/uwe5622/wcnmodem.bin"
sudo head -c 4 "$R/lib/firmware/wcnmodem.bin" | od -An -c

echo "=== [2] 重新启用驱动自动加载 (sprdwl_ng 依赖会自动带出 uwe5622_bsp_sdio/sunxi_addr/cfg80211/rfkill) ==="
sudo mkdir -p "$R/etc/modules.d"
printf 'sprdwl_ng\n' | sudo tee "$R/etc/modules.d/50-uwe5622" >/dev/null
# 清掉旧的(若存在)以免重复/命名不一致
sudo rm -f "$R/etc/modules.d/51-sprdwl-ng" "$R/etc/modules.d/50-uwe5622-bsp"
sudo cat "$R/etc/modules.d/50-uwe5622"

echo "=== [3] 稳定性兜底: 关闭 hung_task panic (规避 UWE5622 SDIO 偶发卡死) ==="
sudo mkdir -p "$R/etc/sysctl.d"
sudo tee "$R/etc/sysctl.d/99-wcn.conf" >/dev/null <<'SYSEOF'
kernel.hung_task_timeout_secs=0
SYSEOF

echo "=== [4] 写入 hostapd AP 配置 (2.4G, 桥接到 br-lan) ==="
sudo tee "$R/etc/hostapd-wlan0.conf" >/dev/null <<'HOSTEOF'
interface=wlan0
bridge=br-lan
driver=nl80211
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
hw_mode=g
channel=6
country_code=CN
ieee80211d=1
ieee80211n=1
wmm_enabled=1
ssid=OrangePi-Zero3
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=12345678
HOSTEOF

echo "=== [5] 写入开机 AP 服务 (procd, 加载驱动->修零MAC->起hostapd) ==="
sudo tee "$R/etc/init.d/zero3-ap" >/dev/null <<'INITEOF'
#!/bin/sh /etc/rc.common
# 板载 UWE5622 wifi: 开机自动起 AP, 不依赖 wifi-scripts/netifd
START=99
STOP=10
USE_PROCD=1

start_service() {
	# 1) 加载驱动(modules.d 通常已加载, 这里兜底, 最多等待 25s 出现 wlan0)
	i=0
	while [ ! -e /sys/class/net/wlan0 ] && [ "$i" -lt 25 ]; do
		modprobe sprdwl_ng 2>/dev/null
		sleep 1
		i=$((i+1))
	done
	[ -e /sys/class/net/wlan0 ] || {
		logger -t zero3-ap "wlan0 未出现, 跳过 AP 启动"
		return 0
	}

	# 2) 处理全 0 MAC: 基于 eth0 派生一个本地管理(locally-administered)地址
	mac=$(cat /sys/class/net/wlan0/address 2>/dev/null)
	if [ "$mac" = "00:00:00:00:00:00" ] || [ -z "$mac" ]; then
		base=$(cat /sys/class/net/eth0/address 2>/dev/null)
		if [ -n "$base" ]; then
			o1=$(echo "$base" | cut -d: -f1)
			rest=$(echo "$base" | cut -d: -f2-6)
			newo1=$(printf '%02x' $(( (0x$o1 | 2) & 0xfe )))
			newmac="$newo1:$rest"
		else
			newmac="02:e0:4c:00:11:22"
		fi
		ip link set wlan0 down 2>/dev/null
		ip link set wlan0 address "$newmac" 2>/dev/null
		logger -t zero3-ap "已设置 wlan0 MAC=$newmac"
	fi

	# 3) 启动 hostapd(由其负责 up wlan0 并加入 br-lan 网桥)
	procd_open_instance
	procd_set_param command /usr/sbin/hostapd /etc/hostapd-wlan0.conf
	procd_set_param respawn 3600 5 0
	procd_set_param stderr 1
	procd_close_instance
}

stop_service() {
	killall hostapd 2>/dev/null
	ip link set wlan0 down 2>/dev/null
}
INITEOF
sudo chmod +x "$R/etc/init.d/zero3-ap"
# 离线启用: 建立 rc.d 启动软链
sudo mkdir -p "$R/etc/rc.d"
sudo ln -sf ../init.d/zero3-ap "$R/etc/rc.d/S99zero3-ap"

echo "=== [6] 校验 ==="
echo "-- 固件 magic --"; sudo head -c 4 "$R/lib/firmware/wcnmodem.bin" | od -An -tx1
echo "-- modules.d/50-uwe5622 --"; sudo cat "$R/etc/modules.d/50-uwe5622"
echo "-- 模块.ko --"; sudo ls "$R/lib/modules/$KVER/sprdwl_ng.ko" "$R/lib/modules/$KVER/uwe5622_bsp_sdio.ko"
echo "-- init 软链 --"; sudo ls -l "$R/etc/rc.d/S99zero3-ap"
echo "-- hostapd --"; sudo ls -l "$R/usr/sbin/hostapd"

sudo sync
sudo umount "$R"
sudo losetup -d "$LD"
rmdir "$R"

echo "=== [7] 导出镜像 (raw + gz + sha256) ==="
mkdir -p "$OUT_WIN"
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "WIFI-FIX-DONE"
