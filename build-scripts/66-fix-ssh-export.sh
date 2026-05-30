#!/usr/bin/env bash
set -uo pipefail
KVER=6.1.31-sun50iw9
IMG=/home/zrm/build/openwrt_packit/output/openwrt_h618_zero3_immortalwrt_k${KVER}.img
OUT_WIN=/mnt/d/zrm/orangepi/zero3/output
sudo losetup -D 2>/dev/null
LD=$(sudo losetup -f -P --show "$IMG")
R=$(mktemp -d); sudo mount "${LD}p2" "$R"

echo "=== 关闭 openssh sshd 开机自启(保留 dropbear 占 22), 避免端口冲突 ==="
sudo rm -f "$R/etc/rc.d/"*sshd 2>/dev/null
echo "剩余 ssh 相关自启: $(ls "$R/etc/rc.d/" | grep -E 'sshd|dropbear' | tr '\n' ' ')"

echo "=== 确保 dropbear 支持 sftp(Cursor 需要), 指向已装的 sftp-server ==="
ls -l "$R/usr/libexec/sftp-server" 2>/dev/null || echo '(无 sftp-server!)'

sudo umount "$R"; sudo losetup -d "$LD"; rmdir "$R"

echo "=== 重新导出 (raw + gz + sha256) ==="
cp -f "$IMG" "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img"
gzip -c "$IMG" > "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz"
( cd "$OUT_WIN" && sha256sum "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz" > "openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256" )
ls -lh "$OUT_WIN"/*.img.gz
cat "$OUT_WIN/openwrt_h618_zero3_immortalwrt_k${KVER}.img.gz.sha256"
echo "SSH-FIX-EXPORT-DONE"
