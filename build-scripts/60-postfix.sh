#!/usr/bin/env bash
# 一体化 packit 后处理: 解压内核/boot.scr/启动标志/网络/固件/禁用卡顿wifi自动加载, 导出镜像
set -uo pipefail
KVER=6.1.31-sun50iw9
K=/home/zrm/build/orangepi-build/kernel/orange-pi-6.1-sun50iw9
HEX="$K/drivers/net/wireless/uwe5622/unisocwcn/fw/wcnmodem.bin.hex"
FWBIN=/home/zrm/build/wcnmodem.bin
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
command -v mkimage >/dev/null || { echo "mkimage missing"; exit 1; }
[ -f "$IMG" ] || { echo "镜像不存在: $IMG"; exit 1; }

echo "=== 准备固件 wcnmodem.bin (hex->bin) ==="
python3 -c "
import re
b=bytes(int(x,16) for x in re.findall(r'0x([0-9A-Fa-f]{2})',open('$HEX').read()))
open('$FWBIN','wb').write(b); print('fw bytes=',len(b))
"

sudo losetup -D 2>/dev/null
LD=$(sudo losetup -f -P --show "$IMG")
echo "loop=$LD"
B=$(mktemp -d); R=$(mktemp -d)

############ 启动分区 p1 ############
sudo mount "${LD}p1" "$B"
echo "=== [1] 解压 gzip 内核 -> 原始 arm64 Image ==="
TMPK=/home/zrm/build/zero3_raw_Image
sudo sh -c "zcat '$B/zImage' > '$TMPK' 2>/dev/null || gzip -dc '$B/zImage' > '$TMPK' 2>/dev/null || true"
MAGIC=$(sudo od -An -tx1 -j56 -N4 "$TMPK" | tr -d ' ')
echo "magic@56=$MAGIC (期望 41524d64)"
if [ "$MAGIC" = "41524d64" ]; then
  sudo cp -f "$B/zImage" "$B/zImage.gz.bak"
  sudo cp -f "$TMPK" "$B/zImage"
  sudo cp -f "$TMPK" "$B/vmlinuz-${KVER}"
  echo "内核已替换为原始 Image"
else
  echo "zImage 可能已是原始 Image, 跳过解压"
fi
sudo rm -f "$TMPK"

echo "=== [2] 写入 boot.cmd (直接 bootargs + part uuid, 原始Image, 无initrd) ==="
sudo tee "$B/boot.cmd" >/dev/null <<'BOOTEOF'
# Orange Pi Zero3 (H618) OpenWrt - direct bootargs, raw arm64 Image, no initrd
echo "== Boot Orange Pi Zero3 OpenWrt (v3) =="
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
sudo mkimage -C none -A arm64 -T script -d "$B/boot.cmd" "$B/boot.scr" >/dev/null
sudo tee "$B/uEnv.txt" >/dev/null <<'EOF'
LINUX=/zImage
FDT=/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb
APPEND=root=PARTUUID=741e5233-02 rootwait rootfstype=btrfs rootflags=compress=zstd:6 rw console=ttyS0,115200n8 console=tty1 net.ifnames=0
EOF
echo "boot.scr 已生成"
sudo umount "$B"

############ 根文件系统 p2 ############
sudo mount "${LD}p2" "$R"
echo "=== [3] 网络配置 (eth0 -> br-lan 192.168.1.1) ==="
sudo tee "$R/etc/config/network" >/dev/null <<'NETEOF'
config interface 'loopback'
	option device 'lo'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'

config globals 'globals'
	option ula_prefix 'fd00:ab:cd::/48'

config device
	option name 'br-lan'
	option type 'bridge'
	list ports 'eth0'

config interface 'lan'
	option device 'br-lan'
	option proto 'static'
	option ipaddr '192.168.1.1'
	option netmask '255.255.255.0'
	option ip6assign '60'
NETEOF
sudo mkdir -p "$R/etc/uci-defaults"
sudo tee "$R/etc/uci-defaults/99-zero3-lan" >/dev/null <<'UCIEOF'
#!/bin/sh
uci -q batch <<'EOF'
set network.lan=interface
set network.lan.proto='static'
set network.lan.ipaddr='192.168.1.1'
set network.lan.netmask='255.255.255.0'
set network.lan.device='br-lan'
delete network.wan
delete network.wan6
commit network
EOF
exit 0
UCIEOF
sudo chmod +x "$R/etc/uci-defaults/99-zero3-lan"
sudo mkdir -p "$R/etc/modules.d"
echo 'dwmac-sun8i' | sudo tee "$R/etc/modules.d/30-dwmac-sun8i" >/dev/null

echo "=== [4] 注入板载wifi固件(留待二阶段), 并禁用其开机自动加载(避免30秒卡顿与报错) ==="
sudo mkdir -p "$R/lib/firmware/uwe5622"
sudo cp -f "$FWBIN" "$R/lib/firmware/wcnmodem.bin"
sudo cp -f "$FWBIN" "$R/lib/firmware/uwe5622/wcnmodem.bin"
sudo chmod 644 "$R/lib/firmware/wcnmodem.bin" "$R/lib/firmware/uwe5622/wcnmodem.bin"
# 禁用自动加载(模块仍在, 二阶段可手动 modprobe 或重编内核后再启用)
sudo rm -f "$R/etc/modules.d/50-uwe5622-bsp" "$R/etc/modules.d/51-sprdwl-ng"
echo "已移除 50-uwe5622-bsp / 51-sprdwl-ng 自动加载"

echo "=== [5] 修正 fstab 里硬编码 mmcblk0p1 的开机挂载报错 ==="
if sudo grep -q "mmcblk0p1" "$R/etc/config/fstab" 2>/dev/null; then
  echo "--- 原 fstab ---"; sudo cat "$R/etc/config/fstab"
  # 关闭 mmcblk0p1 自动挂载条目(设备实际为 mmcblk1p1)
  sudo sed -i "s#/dev/mmcblk0p1#/dev/mmcblk1p1#g" "$R/etc/config/fstab"
  echo "--- 修正后 ---"; sudo cat "$R/etc/config/fstab"
else
  echo "fstab 未硬编码 mmcblk0p1 (或不存在), 跳过"
fi

echo "=== [6] 校验关键 web 服务已就位 ==="
ls -l "$R/usr/sbin/uhttpd" 2>/dev/null && echo "uhttpd OK" || echo "!! uhttpd 缺失"
ls -l "$R/usr/sbin/rpcd" 2>/dev/null && echo "rpcd OK" || echo "!! rpcd 缺失"
ls -d "$R/usr/lib/lua/luci"/* 2>/dev/null | head -3
ls -l "$R/etc/rc.d/"*uhttpd* 2>/dev/null && echo "uhttpd 开机启用 OK" || echo "!! uhttpd 未开机启用"
ls "$R/usr/bin/node" "$R/usr/bin/bash" 2>/dev/null
ls -l "$R/usr/libexec/sftp-server" 2>/dev/null || ls -l "$R/usr/lib/openssh/sftp-server" 2>/dev/null || echo "(sftp-server 路径待确认)"

sudo umount "$R"

echo "=== [7] 设置启动分区可引导标志 ==="
sudo parted -s "$LD" set 1 boot on
sudo parted -s "$LD" print 2>/dev/null | head -15

sudo losetup -d "$LD"; rmdir "$B" "$R"

echo "=== [8] 导出镜像 (raw + gz + sha256) ==="
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "POSTFIX-DONE"
