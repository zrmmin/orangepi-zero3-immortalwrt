#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output

command -v mkimage >/dev/null || { echo "mkimage missing"; exit 1; }

sudo losetup -D
LD=$(sudo losetup -f -P --show "$IMG")
echo "loop=$LD"
B=$(mktemp -d)
sudo mount "${LD}p1" "$B"

echo "=== 当前 zImage 头部 (应为 1f8b gzip) ==="
sudo od -An -tx1 -N4 "$B/zImage"

echo "=== 解压 gzip 内核 -> 原始 arm64 Image ==="
TMPK=/home/zrm/build/zero3_raw_Image
# vfat 默认 world-readable, zrm 可直接读; 容错解压(尾部可能有垃圾)
zcat "$B/zImage" > "$TMPK" 2>/dev/null || gzip -dc "$B/zImage" > "$TMPK" 2>/dev/null || true
SZ=$(stat -c %s "$TMPK"); echo "decompressed size=$SZ"
echo "=== 解压后偏移56魔数 (应为 41 52 4d 64 = ARM64) ==="
MAGIC=$(od -An -tx1 -j56 -N4 "$TMPK" | tr -d ' ')
echo "magic@56=$MAGIC"
if [ "$MAGIC" != "41524d64" ]; then
  echo "!! 解压后不是 arm64 Image, 放弃"; rm -f "$TMPK"; sudo umount "$B"; sudo losetup -d "$LD"; rmdir "$B"; exit 2
fi

echo "=== 备份原压缩内核, 用原始 Image 覆盖 zImage / vmlinuz ==="
sudo cp -f "$B/zImage" "$B/zImage.gz.bak"
sudo cp -f "$TMPK" "$B/zImage"
sudo cp -f "$TMPK" "$B/vmlinuz-${KVER}"
rm -f "$TMPK"
sudo od -An -tx1 -j56 -N4 "$B/zImage"

echo "=== 重写健壮 boot.cmd (显式地址 + 解压缓冲 + fdt resize, 无 initrd) ==="
sudo tee "$B/boot.cmd" >/dev/null <<'BOOTEOF'
# Orange Pi Zero3 (H618) OpenWrt - booti raw arm64 Image, no initrd
echo "== Boot Orange Pi Zero3 OpenWrt =="
setenv kernel_addr_r "0x40080000"
setenv fdt_addr_r    "0x4FA00000"
setenv kernel_comp_addr_r "0x4c000000"
setenv kernel_comp_size   "0x04000000"
setenv loadaddr "0x45000000"

if load mmc 0 ${loadaddr} uEnv.txt; then
    env import -t ${loadaddr} ${filesize}
fi
setenv bootargs ${APPEND}

if load mmc 0 ${kernel_addr_r} ${LINUX}; then
    if load mmc 0 ${fdt_addr_r} ${FDT}; then
        fdt addr ${fdt_addr_r}
        fdt resize
        echo "Booting kernel ..."
        booti ${kernel_addr_r} - ${fdt_addr_r}
    fi
fi
echo "!! boot failed, dropping to u-boot prompt"
BOOTEOF
sudo mkimage -C none -A arm64 -T script -d "$B/boot.cmd" "$B/boot.scr"

echo "=== uEnv.txt (确认 LINUX=/zImage, FDT 路径) ==="
sudo cat "$B/uEnv.txt"

echo "=== 启动分区文件 ==="
sudo ls -l "$B"

sudo umount "$B"; sudo losetup -d "$LD"; rmdir "$B"

echo "=== 重新导出压缩镜像 ==="
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "FIX-KERNEL-DONE"
