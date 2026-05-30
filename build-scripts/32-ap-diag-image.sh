#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
AP_SSID="OrangePi-Zero3"
AP_KEY="zero3wifi"
ROOT_PW="password"

sudo losetup -D
LD=$(sudo losetup -f -P --show "$IMG")
echo "loop=$LD"
R=$(mktemp -d)
sudo mount "${LD}p2" "$R"

echo "=== [1/6] 重申有线 LAN 配置 (eth0 -> br-lan -> 192.168.1.1) ==="
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

echo "=== [2/6] WiFi 模块自动加载顺序 (sunxi_addr -> bsp -> sprdwl) ==="
echo 'sunxi_addr'        | sudo tee "$R/etc/modules.d/48-sunxi-addr" >/dev/null
echo 'uwe5622_bsp_sdio'  | sudo tee "$R/etc/modules.d/50-uwe5622-bsp" >/dev/null
echo 'sprdwl_ng'         | sudo tee "$R/etc/modules.d/51-sprdwl-ng" >/dev/null

echo "=== [3/6] 开机首跑脚本: 兜底网口 + 起AP + 写诊断日志到FAT ==="
sudo tee "$R/usr/bin/zero3-firstboot.sh" >/dev/null <<FBEOF
#!/bin/sh
# Orange Pi Zero3 boot helper: ethernet fallback + WiFi AP + diagnostics to FAT /boot
LOG=/boot/zero3-diag.log
sleep 20

{
echo "==== zero3 boot \$(date) ===="
echo "## uname"; uname -a
echo "## board"; cat /tmp/sysinfo/board_name 2>/dev/null; cat /tmp/sysinfo/model 2>/dev/null

echo "## --- ethernet fallback ---"
ETH=\$(ls /sys/class/net 2>/dev/null | grep -E '^(eth|end|enp)[0-9]' | head -1)
echo "detected eth iface: \$ETH"
if [ -n "\$ETH" ] && [ "\$ETH" != "eth0" ]; then
    echo "eth0 not found, rebinding br-lan to \$ETH"
    uci -q delete network.@device[0].ports
    uci add_list network.@device[0].ports="\$ETH"
    uci commit network
    /etc/init.d/network restart
    sleep 5
fi

echo "## --- load wifi modules ---"
for m in sunxi_addr uwe5622_bsp_sdio sprdwl_ng sprdbt_tty; do
    modprobe \$m 2>&1 && echo "modprobe \$m OK" || echo "modprobe \$m FAIL"
done
sleep 6

echo "## --- configure AP if missing ---"
if [ ! -s /etc/config/wireless ] || ! uci -q get wireless.@wifi-iface[0] >/dev/null 2>&1; then
    wifi config 2>&1
    RADIO=\$(uci show wireless 2>/dev/null | sed -n 's/^wireless\.\([^.]*\)=wifi-device/\1/p' | head -1)
    echo "detected radio: \$RADIO"
    if [ -n "\$RADIO" ]; then
        uci set wireless.\$RADIO.disabled='0'
        uci set wireless.\$RADIO.channel='6'
        uci set wireless.\$RADIO.band='2g' 2>/dev/null
        uci -q delete wireless.zero3ap
        uci set wireless.zero3ap=wifi-iface
        uci set wireless.zero3ap.device="\$RADIO"
        uci set wireless.zero3ap.mode='ap'
        uci set wireless.zero3ap.network='lan'
        uci set wireless.zero3ap.ssid='${AP_SSID}'
        uci set wireless.zero3ap.encryption='psk2'
        uci set wireless.zero3ap.key='${AP_KEY}'
        uci commit wireless
        echo "AP configured on \$RADIO"
    else
        echo "NO radio detected -> sprdwl_ng/phy not registered"
    fi
fi
wifi up 2>&1
sleep 6

echo "## ip link";  ip -br link 2>&1
echo "## ip addr";  ip -br addr 2>&1
echo "## /etc/config/network"; cat /etc/config/network 2>&1
echo "## /etc/config/wireless"; cat /etc/config/wireless 2>&1
echo "## lsmod wifi/eth"; lsmod | grep -iE 'sprdwl|uwe5622|sunxi_addr|cfg80211|mac80211|dwmac|stmmac|rfkill'
echo "## iw dev"; iw dev 2>&1
echo "## iw phy(head)"; iw phy 2>&1 | head -30
echo "## hostapd running?"; ps w | grep -iE 'hostapd|wpa' | grep -v grep
echo "## dmesg wifi/mmc/eth"; dmesg 2>&1 | grep -iE 'sprd|uwe5622|wlan|mmc1|sdio|eth0|dwmac|stmmac|wifi|cfg80211' | tail -150
echo "## logread net"; logread 2>/dev/null | grep -iE 'netifd|wlan|wifi|hostapd|sprd|country' | tail -80
echo "==== end \$(date) ===="
} > "\$LOG" 2>&1
sync
FBEOF
sudo chmod +x "$R/usr/bin/zero3-firstboot.sh"

echo "=== [4/6] init.d 服务 + 开机自启 (S99) ==="
sudo tee "$R/etc/init.d/zero3boot" >/dev/null <<'INITEOF'
#!/bin/sh /etc/rc.common
START=99
STOP=01
start() {
    ( /usr/bin/zero3-firstboot.sh ) &
}
INITEOF
sudo chmod +x "$R/etc/init.d/zero3boot"
sudo ln -sf ../init.d/zero3boot "$R/etc/rc.d/S99zero3boot"

echo "=== [5/6] 设置 root 密码 (用于 SSH/AP 登录) ==="
sudo tee "$R/etc/uci-defaults/98-zero3-rootpw" >/dev/null <<PWEOF
#!/bin/sh
(echo '${ROOT_PW}'; echo '${ROOT_PW}') | passwd root >/dev/null 2>&1
exit 0
PWEOF
sudo chmod +x "$R/etc/uci-defaults/98-zero3-rootpw"

echo "=== [6/6] 校验 ==="
echo "--- modules.d wifi ---"; sudo ls "$R/etc/modules.d/" | grep -iE 'sunxi-addr|uwe5622|sprdwl'
echo "--- rc.d S99 ---"; sudo ls -l "$R/etc/rc.d/S99zero3boot"
echo "--- firstboot head ---"; sudo sed -n '1,5p' "$R/usr/bin/zero3-firstboot.sh"
echo "--- uci-defaults ---"; sudo ls "$R/etc/uci-defaults/" | grep -iE 'zero3'

sudo umount "$R"
sudo losetup -d "$LD"
rmdir "$R"

echo "=== 重新导出压缩镜像 ==="
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "AP-DIAG-DONE"
