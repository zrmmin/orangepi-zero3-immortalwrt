#!/usr/bin/env bash
# 回滚: 删除导致启动前挂死的 gpio-hog, 重编干净 DTB 写回镜像 -> 保证可启动
# 同时让 rootfs 里 WiFi 改为"手动实验"模式(不自启), 放 /root/wifi-test.sh 供运行中调试
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
K=/home/zrm/build/orangepi-build/kernel/orange-pi-6.1-sun50iw9
SRCDIR=$K/arch/arm64/boot/dts/allwinner
DTS=$SRCDIR/sun50i-h618-orangepi-zero3.dts
INC=$K/scripts/dtc/include-prefixes

command -v dtc >/dev/null || { echo "dtc 缺失"; exit 1; }
[ -f "$IMG" ] || { echo "镜像不存在: $IMG"; exit 1; }
[ -f "$DTS" ] || { echo "源码 DTS 不存在: $DTS"; exit 1; }

echo "=== [0] 从源码 DTS 删除 gpio-hog 块 ==="
if grep -q '^&pio {' "$DTS"; then
  sudo sed -i '/^&pio {/,$d' "$DTS"
  echo "已删除 &pio hog 块"
else
  echo "源码 DTS 无 &pio hog, 跳过"
fi
echo "--- DTS 末尾 ---"; tail -6 "$DTS"
grep -q 'wifi-chip-en' "$DTS" && { echo "!! hog 仍残留, 终止"; exit 1; }

echo "=== [1] cpp 预处理 + dtc 编译干净 DTB ==="
cpp -nostdinc -I "$INC" -I "$SRCDIR" -undef -x assembler-with-cpp -D__DTS__ "$DTS" -o /tmp/zero3.clean.pre.dts || { echo "cpp 失败"; exit 1; }
dtc -@ -I dts -O dtb -o /tmp/zero3_clean.dtb /tmp/zero3.clean.pre.dts 2>/tmp/dtc71.err
[ -s /tmp/zero3_clean.dtb ] || { echo "!! dtc 失败"; head /tmp/dtc71.err; exit 1; }
SZ=$(stat -c%s /tmp/zero3_clean.dtb); echo "干净 DTB 大小: $SZ"
[ "$SZ" -gt 25000 ] || { echo "!! DTB 过小, 终止"; exit 1; }
dtc -I dtb -O dts /tmp/zero3_clean.dtb 2>/dev/null > /tmp/zero3_clean_back.dts
grep -q 'wifi-chip-en' /tmp/zero3_clean_back.dts && { echo "!! 干净DTB仍含hog, 终止"; exit 1; }
for n in 'pinctrl@300b000' 'mmc@4021000' 'ethernet@5020000' 'serial@5000000'; do
  grep -q "$n" /tmp/zero3_clean_back.dts && echo "OK  $n" || { echo "!! 缺 $n"; exit 1; }
done

echo "=== [2] 挂载镜像, 替换 p1 DTB + 调整 p2 rootfs ==="
sudo losetup -D 2>/dev/null || true
LD=$(sudo losetup -f -P --show "$IMG"); echo "loop=$LD"

# --- p1: 写回干净 DTB ---
B1=$(mktemp -d); sudo mount "${LD}p1" "$B1"
DTB=$(sudo find "$B1" -iname 'sun50i-h618-orangepi-zero3.dtb' 2>/dev/null | head -1)
[ -n "$DTB" ] || { echo "!! 镜像内无 DTB"; sudo umount "$B1"; sudo losetup -d "$LD"; exit 1; }
echo "p1 DTB: $DTB (旧 $(sudo stat -c%s "$DTB"))"
sudo cp -f /tmp/zero3_clean.dtb "$DTB"; sync
echo "替换后 $(sudo stat -c%s "$DTB")"
sudo umount "$B1"; rmdir "$B1"

# --- p2: 关闭 wifi 自启, 放手动测试脚本 ---
B2=$(mktemp -d); sudo mount "${LD}p2" "$B2"
echo "p2 已挂载: $B2"
# 关掉驱动自动加载(避免开机刷 marlin timeout, 拖慢启动)
sudo rm -f "$B2/etc/modules.d/50-uwe5622" 2>/dev/null || true
# 关掉 AP 自启
sudo rm -f "$B2/etc/rc.d/S99zero3-ap" 2>/dev/null || true
# 放手动测试脚本
sudo tee "$B2/root/wifi-test.sh" >/dev/null <<'WT'
#!/bin/sh
# UWE5622 板载WiFi 手动调试脚本(运行中实验, 不需重烧)
set -x
echo "==== [模块/固件检查] ===="
ls -l /lib/firmware/wcnmodem.bin 2>/dev/null
head -c4 /lib/firmware/wcnmodem.bin 2>/dev/null | xxd
ls /lib/modules/$(uname -r)/ 2>/dev/null | grep -iE 'sprd|uwe|wcn' || echo "(modules目录无匹配)"
modinfo sprdwl_ng 2>/dev/null | head -3

echo "==== [尝试拉高 PG17 (CHIP_EN) via sysfs] ===="
# 找主 pinctrl gpiochip 的 base, PG17 行偏移 = 6*32+17 = 209
for gc in /sys/class/gpio/gpiochip*; do
  lbl=$(cat "$gc/label" 2>/dev/null)
  base=$(cat "$gc/base" 2>/dev/null)
  ng=$(cat "$gc/ngpio" 2>/dev/null)
  echo "gpiochip: $gc label=$lbl base=$base ngpio=$ng"
done
# 主 pio (300b000) 通常 base=0 ngpio>=224; PG17=209
PG17=209
if [ -d /sys/class/gpio ]; then
  echo $PG17 > /sys/class/gpio/export 2>/dev/null
  if [ -d /sys/class/gpio/gpio$PG17 ]; then
    echo out > /sys/class/gpio/gpio$PG17/direction 2>/dev/null
    echo 1 > /sys/class/gpio/gpio$PG17/value 2>/dev/null
    echo "PG17(sysfs $PG17) 已尝试拉高, value=$(cat /sys/class/gpio/gpio$PG17/value 2>/dev/null)"
  else
    echo "sysfs gpio$PG17 不存在(可能内核没开 CONFIG_GPIO_SYSFS 或 base 非0)"
  fi
fi
# 备选: libgpiod
if command -v gpioset >/dev/null; then
  echo "gpioset 可用, 列出 gpiochip:"; gpiodetect 2>/dev/null
fi

echo "==== [加载驱动] ===="
modprobe sprdwl_ng 2>&1 | tail -20 || insmod /lib/modules/$(uname -r)/sprdwl_ng.ko 2>&1 | tail -5
sleep 3
echo "==== [dmesg 末尾 60 行] ===="
dmesg | tail -60
echo "==== [网卡] ===="
ip link
WT
sudo chmod +x "$B2/root/wifi-test.sh"
echo "已写 /root/wifi-test.sh"
sync
sudo umount "$B2"; rmdir "$B2"
sudo losetup -d "$LD"

echo "=== [3] 重新导出镜像 ==="
mkdir -p "$OUT_WIN"
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "REVERT-HOG-DONE"
