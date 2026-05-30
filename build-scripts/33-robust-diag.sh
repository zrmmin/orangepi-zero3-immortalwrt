#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
AP_SSID="OrangePi-Zero3"
AP_KEY="zero3wifi"

sudo losetup -D
LD=$(sudo losetup -f -P --show "$IMG")
echo "loop=$LD"
R=$(mktemp -d)
sudo mount "${LD}p2" "$R"

echo "=== 替换为健壮版 zero3-firstboot.sh (早写+分段刷盘) ==="
sudo tee "$R/usr/bin/zero3-firstboot.sh" >/dev/null <<FBEOF
#!/bin/sh
# Early, incremental, flush-after-each-step diagnostics + ethernet fallback + WiFi AP
LOG=/boot/zero3-diag.log
mountpoint -q /boot 2>/dev/null || mount -t vfat LABEL=EMMC_BOOT /boot 2>/dev/null
mountpoint -q /boot 2>/dev/null || mount /dev/mmcblk0p1 /boot 2>/dev/null

# ---- 立即写启动标记并刷盘 (证明已进用户空间) ----
echo "==== ZERO3 BOOT MARKER \$(date) uptime=\$(cut -d. -f1 /proc/uptime)s ====" > "\$LOG"
sync
P(){ echo "" >>"\$LOG"; echo "## \$* (uptime=\$(cut -d. -f1 /proc/uptime)s)" >>"\$LOG"; }
R(){ "\$@" >>"\$LOG" 2>&1; sync; }

P uname;            R uname -a
P "ip link (early)"; R ip -br link
P "load wifi modules"
for m in sunxi_addr uwe5622_bsp_sdio sprdwl_ng sprdbt_tty; do
    if modprobe \$m >>"\$LOG" 2>&1; then echo "modprobe \$m OK" >>"\$LOG"; else echo "modprobe \$m FAIL" >>"\$LOG"; fi
    sync
done
sleep 5

P "ethernet fallback"
ETH=\$(ls /sys/class/net 2>/dev/null | grep -E '^(eth|end|enp)[0-9]' | head -1)
echo "detected eth iface: [\$ETH]" >>"\$LOG"; sync
if [ -n "\$ETH" ] && [ "\$ETH" != "eth0" ]; then
    uci -q delete network.@device[0].ports
    uci add_list network.@device[0].ports="\$ETH"
    uci commit network
    /etc/init.d/network restart
    sleep 5
fi

P "configure AP"
if [ ! -s /etc/config/wireless ] || ! uci -q get wireless.@wifi-iface[0] >/dev/null 2>&1; then
    wifi config >>"\$LOG" 2>&1
    RADIO=\$(uci show wireless 2>/dev/null | sed -n 's/^wireless\.\([^.]*\)=wifi-device/\1/p' | head -1)
    echo "detected radio: [\$RADIO]" >>"\$LOG"
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
        echo "AP configured on \$RADIO" >>"\$LOG"
    else
        echo "NO radio detected -> sprdwl_ng/phy NOT registered" >>"\$LOG"
    fi
fi
sync
R wifi up
sleep 6

P "ip link";   R ip -br link
P "ip addr";   R ip -br addr
P "/etc/config/network"; R cat /etc/config/network
P "/etc/config/wireless"; R cat /etc/config/wireless
P "lsmod wifi/eth"; R sh -c "lsmod | grep -iE 'sprdwl|uwe5622|sunxi_addr|cfg80211|mac80211|dwmac|stmmac|rfkill'"
P "iw dev";    R iw dev
P "iw phy(head)"; R sh -c "iw phy 2>&1 | head -30"
P "hostapd/wpa procs"; R sh -c "ps w | grep -iE 'hostapd|wpa' | grep -v grep"
P "dmesg wifi/mmc/eth"; R sh -c "dmesg | grep -iE 'sprd|uwe5622|wlan|mmc1|sdio|eth0|dwmac|stmmac|wifi|cfg80211|panic|Kernel' | tail -200"
P "logread net"; R sh -c "logread 2>/dev/null | grep -iE 'netifd|wlan|wifi|hostapd|sprd|country' | tail -80"
echo "" >>"\$LOG"; echo "==== END \$(date) ====" >>"\$LOG"
sync
FBEOF
sudo chmod +x "$R/usr/bin/zero3-firstboot.sh"

echo "=== init.d 提前到 START=10, 并保留 S99 兜底 ==="
sudo tee "$R/etc/init.d/zero3boot" >/dev/null <<'INITEOF'
#!/bin/sh /etc/rc.common
START=10
STOP=01
start() {
    ( /usr/bin/zero3-firstboot.sh ) &
}
INITEOF
sudo chmod +x "$R/etc/init.d/zero3boot"
sudo rm -f "$R/etc/rc.d/S99zero3boot"
sudo ln -sf ../init.d/zero3boot "$R/etc/rc.d/S10zero3boot"

echo "=== 同时让 rc.local 也兜底跑一次 (双保险) ==="
if ! sudo grep -q zero3-firstboot "$R/etc/rc.local"; then
  sudo sed -i 's#^exit 0#[ -f /boot/zero3-diag.log ] || ( /usr/bin/zero3-firstboot.sh \& )\nexit 0#' "$R/etc/rc.local"
fi

echo "=== 校验 ==="
sudo ls -l "$R/etc/rc.d/" | grep zero3
echo "--- rc.local tail ---"; sudo tail -6 "$R/etc/rc.local"
echo "--- firstboot head ---"; sudo sed -n '1,8p' "$R/usr/bin/zero3-firstboot.sh"

sudo umount "$R"; sudo losetup -d "$LD"; rmdir "$R"

echo "=== 重新导出压缩镜像 ==="
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "ROBUST-DIAG-DONE"
