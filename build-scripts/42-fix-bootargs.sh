#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
command -v mkimage >/dev/null || { echo "mkimage missing"; exit 1; }

LD=$(sudo losetup -f -P --show "$IMG")
echo "loop=$LD"
B=$(mktemp -d)
sudo mount "${LD}p1" "$B"

echo "=== 写入新 boot.cmd (直接设 bootargs, part uuid 动态取 PARTUUID, 仿官方) ==="
sudo tee "$B/boot.cmd" >/dev/null <<'BOOTEOF'
# Orange Pi Zero3 (H618) OpenWrt - direct bootargs (no uEnv import), raw Image, no initrd
echo "== Boot Orange Pi Zero3 OpenWrt (v2) =="
setenv kernel_addr_r 0x40080000
setenv fdt_addr_r 0x4fa00000
part uuid mmc 0:2 uuid
setenv bootargs root=PARTUUID=${uuid} rootwait rootfstype=btrfs rootflags=compress=zstd:6 rw console=ttyS0,115200n8 console=tty1 consoleblank=0 net.ifnames=0 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory
echo "bootargs=${bootargs}"
load mmc 0 ${kernel_addr_r} /zImage
load mmc 0 ${fdt_addr_r} /dtb/allwinner/sun50i-h618-orangepi-zero3.dtb
fdt addr ${fdt_addr_r}
fdt resize
echo "Booting kernel ..."
booti ${kernel_addr_r} - ${fdt_addr_r}
BOOTEOF
sudo mkimage -C none -A arm64 -T script -d "$B/boot.cmd" "$B/boot.scr"

echo "=== 同步更新 uEnv.txt 为直接 bootargs(防其它路径读取) ==="
sudo tee "$B/uEnv.txt" >/dev/null <<'EOF'
LINUX=/zImage
FDT=/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb
APPEND=root=PARTUUID=741e5233-02 rootwait rootfstype=btrfs rootflags=compress=zstd:6 rw console=ttyS0,115200n8 console=tty1 net.ifnames=0
EOF

echo "=== 验证 boot.cmd ==="; sudo cat "$B/boot.cmd"
echo "=== boot.scr 信息 ==="; sudo mkimage -l "$B/boot.scr" 2>&1 | head -8

sudo umount "$B"; sudo losetup -d "$LD"; rmdir "$B"

echo "=== 重新导出压缩镜像 ==="
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "FIX-BOOTARGS-DONE"
