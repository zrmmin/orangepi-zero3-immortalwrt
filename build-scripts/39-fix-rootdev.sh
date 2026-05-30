#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output

echo "=== 取 MBR 磁盘签名 (label-id) ==="
DISKID=$(sfdisk -d "$IMG" 2>/dev/null | sed -n 's/^label-id: 0x//p' | tr 'A-Z' 'a-z')
echo "disk-id=$DISKID"
if [ -z "$DISKID" ]; then echo "no diskid"; exit 1; fi
PARTUUID="${DISKID}-02"
echo "root PARTUUID=$PARTUUID"

LD=$(sudo losetup -f -P --show "$IMG")
B=$(mktemp -d)
sudo mount "${LD}p1" "$B"

echo "=== 旧 uEnv.txt ==="; sudo cat "$B/uEnv.txt"

echo "=== 写入新 uEnv.txt (root=PARTUUID + rootwait, 无 initrd) ==="
sudo tee "$B/uEnv.txt" >/dev/null <<EOF
LINUX=/zImage
FDT=/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb

APPEND=root=PARTUUID=${PARTUUID} rootfstype=btrfs rootflags=compress=zstd:6 rootwait console=ttyS0,115200n8 console=tty1 no_console_suspend consoleblank=0 rw fsck.fix=yes fsck.repair=yes net.ifnames=0 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1
EOF

echo "=== 新 uEnv.txt ==="; sudo cat "$B/uEnv.txt"

echo "=== 同步: 把根分区 /etc/fstab 的 / 也改成 PARTUUID (避免再次卡UUID) ==="
sudo mount "${LD}p2" "$B-r" 2>/dev/null || { mkdir -p "$B-r"; sudo mount "${LD}p2" "$B-r"; }
echo "--- 旧 /etc/fstab ---"; sudo cat "$B-r/etc/fstab"
sudo sed -i "s#^UUID=[0-9a-fA-F-]* / btrfs#PARTUUID=${PARTUUID} / btrfs#" "$B-r/etc/fstab"
# /etc/config/fstab 用的是 uuid, 改成不按 uuid 卡: 保留(由 block 在已起的系统里处理, 此时根已挂)
echo "--- 新 /etc/fstab ---"; sudo cat "$B-r/etc/fstab"
sudo umount "$B-r"; rmdir "$B-r"

sudo umount "$B"; sudo losetup -d "$LD"; rmdir "$B"

echo "=== 重新导出压缩镜像 ==="
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "FIX-ROOTDEV-DONE"
