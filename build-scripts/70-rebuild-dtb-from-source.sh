#!/usr/bin/env bash
# 用厂商源码 cpp+dtc 直接编译 DTB(含 PG17 chip_en hog),替换镜像内被 roundtrip 损坏的 DTB
# 不走"反编译->重编"(那会破坏结构导致内核启动前挂死),走标准源码编译路径
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
K=/home/zrm/build/orangepi-build/kernel/orange-pi-6.1-sun50iw9
SRCDIR=$K/arch/arm64/boot/dts/allwinner
DTS=$SRCDIR/sun50i-h618-orangepi-zero3.dts
INC=$K/scripts/dtc/include-prefixes

command -v dtc >/dev/null || { echo "dtc 缺失"; exit 1; }
command -v cpp >/dev/null || { echo "cpp 缺失"; exit 1; }
[ -f "$IMG" ] || { echo "镜像不存在: $IMG"; exit 1; }
[ -f "$DTS" ] || { echo "源码 DTS 不存在: $DTS"; exit 1; }
grep -q 'wifi-chip-en' "$DTS" || { echo "!! 源码 DTS 未包含 chip_en hog, 终止"; exit 1; }

echo "=== [1] cpp 预处理源码 dts ==="
cpp -nostdinc -I "$INC" -I "$SRCDIR" -undef -x assembler-with-cpp -D__DTS__ "$DTS" -o /tmp/zero3.pre.dts || { echo "cpp 失败"; exit 1; }
echo "预处理行数: $(wc -l < /tmp/zero3.pre.dts)"

echo "=== [2] dtc 编译(带 -@ 符号表) ==="
dtc -@ -I dts -O dtb -o /tmp/zero3_src.dtb /tmp/zero3.pre.dts 2>/tmp/dtc70.err
[ -s /tmp/zero3_src.dtb ] || { echo "!! dtc 失败"; head /tmp/dtc70.err; exit 1; }
SZ=$(stat -c%s /tmp/zero3_src.dtb)
echo "源码编译 DTB 大小: $SZ"
[ "$SZ" -gt 25000 ] || { echo "!! DTB 过小($SZ),疑似不完整, 终止"; exit 1; }

echo "=== [3] 结构校验(关键节点 + hog) ==="
dtc -I dtb -O dts /tmp/zero3_src.dtb 2>/dev/null > /tmp/zero3_src_back.dts
FAIL=0
for n in 'pinctrl@300b000' 'mmc@4021000' 'ethernet@5020000' 'serial@5000000' 'wifi-chip-en-hog'; do
  if grep -q "$n" /tmp/zero3_src_back.dts; then echo "OK  $n"; else echo "!! 缺 $n"; FAIL=1; fi
done
[ "$FAIL" = 0 ] || { echo "!! 结构校验失败, 终止(不动镜像)"; exit 1; }
echo "hog:"; grep -A4 'wifi-chip-en-hog' /tmp/zero3_src_back.dts

echo "=== [4] 挂载镜像 p1 并替换 DTB ==="
sudo losetup -D 2>/dev/null || true
LD=$(sudo losetup -f -P --show "$IMG")
echo "loop=$LD"
B=$(mktemp -d)
sudo mount "${LD}p1" "$B"
DTB=$(sudo find "$B" -iname 'sun50i-h618-orangepi-zero3.dtb' 2>/dev/null | head -1)
[ -n "$DTB" ] || { echo "!! 镜像内未找到 DTB"; sudo umount "$B"; sudo losetup -d "$LD"; rmdir "$B"; exit 1; }
echo "镜像内DTB: $DTB (旧大小 $(stat -c%s "$DTB"))"
sudo cp -f /tmp/zero3_src.dtb "$DTB"
sync
echo "替换后大小: $(sudo stat -c%s "$DTB")"
sudo umount "$B"
sudo losetup -d "$LD"
rmdir "$B"

echo "=== [5] 重新导出镜像 ==="
mkdir -p "$OUT_WIN"
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "SRCDTB-DONE"
