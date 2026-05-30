#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
sudo losetup -D 2>/dev/null
LD=$(sudo losetup -f -P --show "$IMG")
R=$(mktemp -d); sudo mount -o ro "${LD}p2" "$R"
echo "=== web/SSH 关键二进制 ==="
for f in sbin/rpcd usr/sbin/uhttpd usr/sbin/sshd usr/libexec/sftp-server bin/bash usr/bin/git usr/bin/htop usr/bin/nano usr/bin/curl; do
  [ -e "$R/$f" ] && echo "OK  /$f" || echo "MISS /$f"
done
echo "=== 开机自启服务(关键) ==="
ls "$R/etc/rc.d/" | grep -E 'uhttpd|rpcd|dropbear|sshd|firewall|network|odhcpd|dnsmasq|openclash' | sort
echo "=== rpcd init ==="
ls -l "$R/etc/init.d/rpcd" 2>/dev/null || echo 'no rpcd init'
echo "=== 确认板载wifi已不自动加载 ==="
ls "$R/etc/modules.d/" | grep -E 'uwe5622|sprdwl' && echo '!! 仍在自动加载' || echo 'OK 已禁用自动加载'
echo "=== /etc/config/network ==="
sudo sed -n '1,40p' "$R/etc/config/network"
sudo umount "$R"; sudo losetup -d "$LD"; rmdir "$R"
echo "VERIFY-DONE"
