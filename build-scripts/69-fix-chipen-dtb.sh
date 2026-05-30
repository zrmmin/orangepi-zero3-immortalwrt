#!/usr/bin/env bash
# 修复板载wifi CP无法启动: 给 PG17 (CHIP_EN) 加 gpio-hog 常驻拉高 (vendor AW路径不主动控制chip_en)
# 通过反编译镜像内DTB->追加hog->重编->写回, 不需重编内核
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
SRC_DTS=/home/zrm/build/orangepi-build/kernel/orange-pi-6.1-sun50iw9/arch/arm64/boot/dts/allwinner/sun50i-h618-orangepi-zero3.dts
command -v dtc >/dev/null || { echo "dtc 缺失"; exit 1; }
[ -f "$IMG" ] || { echo "镜像不存在: $IMG"; exit 1; }

sudo losetup -D 2>/dev/null || true
LD=$(sudo losetup -f -P --show "$IMG")
echo "loop=$LD"
B=$(mktemp -d)
sudo mount "${LD}p1" "$B"
DTB=$(sudo find "$B" -iname 'sun50i-h618-orangepi-zero3.dtb' 2>/dev/null | head -1)
echo "镜像内DTB: $DTB"
sudo cp "$DTB" /tmp/zero3_cur.dtb
sudo chmod 644 /tmp/zero3_cur.dtb

echo "=== [1] 反编译当前 DTB ==="
dtc -I dtb -O dts /tmp/zero3_cur.dtb -o /tmp/zero3_cur.dts 2>/dev/null
echo "原 dts 行数: $(wc -l < /tmp/zero3_cur.dts)"

if grep -q 'wifi-chip-en' /tmp/zero3_cur.dts; then
  echo "DTB 已含 chip_en hog, 跳过追加"
else
  echo "=== [2] 追加 PG17(CHIP_EN) gpio-hog 合并片段 ==="
  cat >> /tmp/zero3_cur.dts <<'DTSEOF'

/ {
	soc {
		pinctrl@300b000 {
			wifi-chip-en-hog {
				gpio-hog;
				gpios = <0x06 0x11 0x00>;
				output-high;
				line-name = "wifi-chip-en";
			};
		};
	};
};
DTSEOF
fi

echo "=== [3] 重新编译 DTB ==="
dtc -I dts -O dtb -o /tmp/zero3_new.dtb /tmp/zero3_cur.dts 2>&1 | grep -vi 'Warning' || true
[ -s /tmp/zero3_new.dtb ] || { echo "!! 新DTB编译失败"; sudo umount "$B"; sudo losetup -d "$LD"; rmdir "$B"; exit 1; }
echo "新 DTB 大小: $(stat -c%s /tmp/zero3_new.dtb)"

echo "=== [4] 校验新 DTB 含 chip_en hog ==="
dtc -I dtb -O dts /tmp/zero3_new.dtb 2>/dev/null | grep -A4 'wifi-chip-en-hog' || { echo "!! 校验失败:新DTB无hog"; sudo umount "$B"; sudo losetup -d "$LD"; rmdir "$B"; exit 1; }

echo "=== [5] 写回镜像 p1 ==="
sudo cp -f /tmp/zero3_new.dtb "$DTB"
sudo sync
sudo umount "$B"
sudo losetup -d "$LD"
rmdir "$B"

echo "=== [6] 同步改动到内核源码 DTS (幂等, 便于日后重编) ==="
if [ -f "$SRC_DTS" ] && ! sudo grep -q 'wifi-chip-en' "$SRC_DTS"; then
  sudo tee -a "$SRC_DTS" >/dev/null <<'SRCEOF'

&pio {
	wifi_chip_en_hog: wifi-chip-en-hog {
		gpio-hog;
		gpios = <6 17 GPIO_ACTIVE_HIGH>; /* PG17 = CHIP_EN, vendor sprdwl AW路径需外部拉高 */
		output-high;
		line-name = "wifi-chip-en";
	};
};
SRCEOF
  echo "已写入源码 DTS"
else
  echo "源码 DTS 已含或不存在, 跳过"
fi

echo "=== [7] 重新导出镜像 ==="
mkdir -p "$OUT_WIN"
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "CHIPEN-DTB-DONE"
