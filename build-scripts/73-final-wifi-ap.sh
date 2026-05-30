#!/usr/bin/env bash
# 最终版: 补上缺失的 WiFi 校准 INI(wifi_2355b001_1ant.ini), 恢复驱动自启 + AP 自启
# 至此: M3L 固件已就位 + CP sync 成功, 仅差 INI -> 补齐后 wlan0 应正常注册并起 AP
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
INI=/home/zrm/build/fw-candidates/ini/orangepi_wifi_2355b001_1ant.ini

[ -f "$IMG" ] || { echo "镜像不存在"; exit 1; }
[ -f "$INI" ] || { echo "INI 不存在: $INI"; exit 1; }
grep -q 'Board Config' "$INI" || { echo "!! INI 内容异常, 终止"; exit 1; }
echo "INI: $(stat -c%s "$INI") 字节"

sudo losetup -D 2>/dev/null || true
LD=$(sudo losetup -f -P --show "$IMG"); echo "loop=$LD"
B=$(mktemp -d); sudo mount "${LD}p2" "$B"

echo "=== [1] 放置 WiFi 校准 INI ==="
sudo cp -f "$INI" "$B/lib/firmware/wifi_2355b001_1ant.ini"
# 同时放 2ant 同名兜底(部分固件读 2ant), 用同一份
sudo cp -f "$INI" "$B/lib/firmware/wifi_2355b001_2ant.ini"
sudo chmod 644 "$B/lib/firmware/wifi_2355b001_"*.ini
echo "已放置:"; sudo ls -l "$B/lib/firmware/" | grep 2355

echo "=== [2] 恢复驱动开机自启 ==="
echo 'sprdwl_ng' | sudo tee "$B/etc/modules.d/50-uwe5622" >/dev/null
sudo cat "$B/etc/modules.d/50-uwe5622"

echo "=== [3] 恢复 AP 开机自启 (rc.d 软链) ==="
sudo ln -sf '../init.d/zero3-ap' "$B/etc/rc.d/S99zero3-ap"
sudo ls -l "$B/etc/rc.d/" | grep zero3

echo "=== [4] 更新 /root/wifi-test.sh (含 INI 检查) ==="
sudo tee "$B/root/wifi-test.sh" >/dev/null <<'WT'
#!/bin/sh
echo "==== 固件 + INI ===="
strings -n5 /lib/firmware/wcnmodem.bin 2>/dev/null | grep -m1 'CPV='
ls -l /lib/firmware/wifi_2355b001_1ant.ini
echo "==== 重新加载驱动 ===="
modprobe -r sprdwl_ng 2>/dev/null; modprobe -r uwe5622_bsp_sdio 2>/dev/null; sleep 1
dmesg -c >/dev/null 2>&1
modprobe sprdwl_ng
i=0; while [ $i -lt 20 ]; do ip link 2>/dev/null | grep -q wlan0 && break; sleep 1; i=$((i+1)); done
echo "==== dmesg 关键行 ===="
dmesg | grep -iE 'WCN|sprdwl|wlan|ini|sync|netdev|init_fw' | tail -30
echo "==== 网卡 ===="; ip link
echo "==== 判定 ===="
if ip link 2>/dev/null | grep -q wlan0; then echo ">>> PASS: wlan0 出现!"; else echo ">>> 看 dmesg"; fi
WT
sudo chmod +x "$B/root/wifi-test.sh"

sync
sudo umount "$B"; rmdir "$B"; sudo losetup -d "$LD"

echo "=== [5] 重新导出 ==="
mkdir -p "$OUT_WIN"
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"; cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "FINAL-WIFI-AP-DONE"
