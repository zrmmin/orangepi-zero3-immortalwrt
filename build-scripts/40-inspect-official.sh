#!/usr/bin/env bash
set -uo pipefail
SRC=/mnt/d/zrm/orangepi/zero3/openwrt-sunxi-cortexa53-xunlong_orangepi-zero3-ext4-sdcard.img.gz
WORK=/home/zrm/build/official
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-40-official.txt
mkdir -p "$WORK"
IMG="$WORK/official.img"

{
echo "=== 解压官方镜像 ==="
[ -f "$IMG" ] || zcat "$SRC" > "$IMG"
ls -l "$IMG"

echo "=== 分区表 (boot标志/类型) ==="
fdisk -l "$IMG"

LD=$(sudo losetup -f -P --show "$IMG")
echo "loop=$LD"
echo "=== 各分区文件系统 ==="
sudo blkid "${LD}"* 2>&1

B=$(mktemp -d); R=$(mktemp -d)
# 官方镜像通常 p1=boot(ext4或fat) p2=rootfs(ext4); 也可能单分区
sudo mount "${LD}p1" "$B" 2>/dev/null && echo "p1 mounted" || echo "p1 mount fail"
echo "=== p1 内容 ==="; sudo ls -la "$B" 2>&1
echo "--- p1 boot.scr/boot.cmd/extlinux/uEnv ---"
sudo find "$B" -maxdepth 2 -iname 'boot.scr' -o -iname 'boot.cmd' -o -iname '*.conf' -o -iname 'uEnv*' -o -iname 'armbianEnv*' -o -iname 'orangepiEnv*' 2>/dev/null
echo "--- extlinux.conf (启动参数 root=) ---"; sudo cat "$B/extlinux/extlinux.conf" 2>/dev/null
echo "--- boot.cmd ---"; sudo cat "$B/boot.cmd" 2>/dev/null
echo "--- uEnv/armbianEnv ---"; sudo cat "$B"/*Env.txt 2>/dev/null; sudo cat "$B/uEnv.txt" 2>/dev/null
echo "--- 内核文件头(判断是否压缩) ---"
for k in "$B"/Image "$B"/zImage "$B"/vmlinuz* "$B"/uImage; do [ -f "$k" ] && { echo "$k:"; sudo od -An -tx1 -N4 "$k"; }; done
echo "--- dtb ---"; sudo find "$B" -iname '*zero3*.dtb' 2>/dev/null

# rootfs: 试 p2, 否则 p1 即 rootfs
ROOTM=""
if sudo mount "${LD}p2" "$R" 2>/dev/null; then ROOTM="$R"; echo "rootfs=p2"; else
  # 单分区? p1 可能就是rootfs
  if [ -d "$B/lib/modules" ]; then ROOTM="$B"; echo "rootfs=p1"; fi
fi
echo "=== rootfs = $ROOTM ==="
if [ -n "$ROOTM" ]; then
  echo "--- /etc/fstab ---"; sudo cat "$ROOTM/etc/fstab" 2>/dev/null
  echo "--- kernel modules dir ---"; sudo ls "$ROOTM/lib/modules/" 2>/dev/null
  KV=$(sudo ls "$ROOTM/lib/modules/" 2>/dev/null | head -1)
  echo "--- [关键] 无线驱动 uwe5622/sprdwl/cfg80211/mac80211 ---"
  sudo find "$ROOTM/lib/modules/" -iname '*uwe5622*' -o -iname '*sprdwl*' -o -iname '*sprdbt*' -o -iname '*xr82*' -o -iname '*cfg80211*' -o -iname '*mac80211*' 2>/dev/null
  echo "--- 全部 wifi/wireless 相关 ko ---"
  sudo find "$ROOTM/lib/modules/" -path '*wireless*' -name '*.ko' 2>/dev/null | head -40
  echo "--- /etc/config/network ---"; sudo cat "$ROOTM/etc/config/network" 2>/dev/null
  echo "--- /etc/openwrt_release ---"; sudo cat "$ROOTM/etc/openwrt_release" 2>/dev/null | head
fi

sudo umount "$B" 2>/dev/null; sudo umount "$R" 2>/dev/null; sudo losetup -d "$LD"; rmdir "$B" "$R" 2>/dev/null
echo "DONE-OFFICIAL"
} > "$OUT" 2>&1
echo wrote "$OUT"
