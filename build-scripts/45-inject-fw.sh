#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
K=/home/zrm/build/orangepi-build/kernel/orange-pi-6.1-sun50iw9
HEX="$K/drivers/net/wireless/uwe5622/unisocwcn/fw/wcnmodem.bin.hex"
FWBIN=/home/zrm/build/wcnmodem.bin
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output

echo "=== hex(C数组) -> 二进制 wcnmodem.bin ==="
python3 -c "
import re
data=open('$HEX').read()
b=bytes(int(x,16) for x in re.findall(r'0x([0-9A-Fa-f]{2})',data))
open('$FWBIN','wb').write(b)
print('bytes=',len(b))
"
echo "=== 校验头部魔数 (应为 57 43 4e 4d = WCNM) ==="
od -An -tx1 -N4 "$FWBIN"
ls -l "$FWBIN"

echo "=== 注入到 rootfs /lib/firmware/ ==="
LD=$(sudo losetup -f -P --show "$IMG")
R=$(mktemp -d); sudo mount "${LD}p2" "$R"
sudo cp -f "$FWBIN" "$R/lib/firmware/wcnmodem.bin"
sudo chmod 644 "$R/lib/firmware/wcnmodem.bin"
sudo chown 0:0 "$R/lib/firmware/wcnmodem.bin"
echo "--- 确认 ---"; sudo ls -l "$R/lib/firmware/wcnmodem.bin"
# 某些版本会找 /lib/firmware/wcnmodem.bin 之外的路径, 顺手放一份到 /lib/firmware/uwe5622/
sudo mkdir -p "$R/lib/firmware/uwe5622"
sudo cp -f "$FWBIN" "$R/lib/firmware/uwe5622/wcnmodem.bin"
sudo umount "$R"; sudo losetup -d "$LD"; rmdir "$R"

echo "=== 重新导出 (gz + raw img) ==="
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "INJECT-FW-DONE"
