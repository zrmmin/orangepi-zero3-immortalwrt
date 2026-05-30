#!/usr/bin/env bash
# 把板载 wifi 固件换成官方/armbian 同款 Marlin3L-AB (W21.05.3) 裸镜像 —— 与本机芯片 0x2355b001 匹配
# 裸镜像走单镜像路径下载到 CP_START_ADDR(0x40500000), 应能正确 sync
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
FW=/home/zrm/build/fw-candidates/opi_master_wcnmodem.bin

[ -f "$IMG" ] || { echo "镜像不存在: $IMG"; exit 1; }
[ -f "$FW" ] || { echo "M3L 固件不存在: $FW"; exit 1; }
grep -aq 'M3L-AB' "$FW" || { echo "!! 固件非 M3L-AB, 终止"; exit 1; }
echo "M3L 固件: $(stat -c%s "$FW") 字节, $(strings -n5 "$FW" | grep -m1 'Platform Version')"

sudo losetup -D 2>/dev/null || true
LD=$(sudo losetup -f -P --show "$IMG"); echo "loop=$LD"
B=$(mktemp -d); sudo mount "${LD}p2" "$B"

echo "=== 替换固件 ==="
# 备份当前(wcne)
sudo cp -f "$B/lib/firmware/wcnmodem.bin" "$B/lib/firmware/wcnmodem.bin.wcne.bak" 2>/dev/null || true
sudo cp -f "$FW" "$B/lib/firmware/wcnmodem.bin"
[ -d "$B/lib/firmware/uwe5622" ] && sudo cp -f "$FW" "$B/lib/firmware/uwe5622/wcnmodem.bin"
sync
echo "新固件 magic/版本:"; sudo head -c4 "$B/lib/firmware/wcnmodem.bin" | tr -d '\0' | cat -v; echo
sudo strings -n5 "$B/lib/firmware/wcnmodem.bin" | grep -m1 'CPV='

echo "=== 更新 /root/wifi-test.sh (清晰判定 PASS/FAIL) ==="
sudo tee "$B/root/wifi-test.sh" >/dev/null <<'WT'
#!/bin/sh
echo "==== 固件 ===="
ls -l /lib/firmware/wcnmodem.bin
strings -n5 /lib/firmware/wcnmodem.bin 2>/dev/null | grep -m1 'CPV='
echo "==== 卸载旧驱动 ===="
modprobe -r sprdwl_ng 2>/dev/null
modprobe -r uwe5622_bsp_sdio 2>/dev/null
sleep 1
dmesg -c >/dev/null 2>&1
echo "==== 加载驱动 ===="
modprobe sprdwl_ng
echo "(等待 20s 让 CP 完成 sync...)"
i=0
while [ $i -lt 20 ]; do
  if ip link 2>/dev/null | grep -q 'wlan0'; then break; fi
  sleep 1; i=$((i+1))
done
echo "==== dmesg 关键行 ===="
dmesg | grep -iE 'WCN|sprdwl|wlan|marlin|sync|cali|download' | tail -40
echo "==== 网卡 ===="
ip link
echo "==== 判定 ===="
if ip link 2>/dev/null | grep -q 'wlan0'; then
  echo ">>> PASS: wlan0 出现, 板载 WiFi 驱动起来了!"
elif dmesg | grep -q 'marlin download timeout'; then
  echo ">>> FAIL: 仍然 marlin download timeout (固件/握手未通过)"
else
  echo ">>> 未知状态, 看上面 dmesg"
fi
WT
sudo chmod +x "$B/root/wifi-test.sh"
sync
sudo umount "$B"; rmdir "$B"; sudo losetup -d "$LD"

echo "=== 重新导出 ==="
mkdir -p "$OUT_WIN"
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"; cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "SWAP-M3L-DONE"
