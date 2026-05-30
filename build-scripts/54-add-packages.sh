#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-54-pkgs.txt
IMM=/home/zrm/build/immortalwrt
CFG="$IMM/.config"
{
echo "=== 备份 .config ==="
cp "$CFG" "$CFG.bak.$(date +%s)" && echo "backed up"

echo "=== 追加包选择 ==="
cat >> "$CFG" <<'EOF'

#### ===== zrm: LuCI 全套 + 常用 + Cursor 远程依赖 (54) =====
## LuCI 核心 Web 栈
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-ssl=y
CONFIG_PACKAGE_uhttpd=y
CONFIG_PACKAGE_uhttpd-mod-ubus=y
CONFIG_PACKAGE_rpcd=y
CONFIG_PACKAGE_rpcd-mod-rrdns=y
CONFIG_PACKAGE_rpcd-mod-iwinfo=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-app-opkg=y
## 中文
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-opkg-zh-cn=y
CONFIG_PACKAGE_luci-i18n-openclash-zh-cn=y
## 无线/USB网卡 AP 相关 (USB WiFi 可做热点) + 修复 regulatory.db
CONFIG_PACKAGE_wpad-openssl=y
CONFIG_PACKAGE_hostapd-utils=y
CONFIG_PACKAGE_iw=y
CONFIG_PACKAGE_iwinfo=y
CONFIG_PACKAGE_wireless-regdb=y
CONFIG_PACKAGE_iperf3=y
## OpenClash 增强 (dnsmasq-full 支持 nftset)
CONFIG_PACKAGE_dnsmasq_full_ipset=y
CONFIG_PACKAGE_dnsmasq_full_nftset=y
CONFIG_PACKAGE_dnsmasq-full=y
## 常用 CLI / 文件系统 / 磁盘工具
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_coreutils=y
CONFIG_PACKAGE_coreutils-base64=y
CONFIG_PACKAGE_coreutils-stat=y
CONFIG_PACKAGE_coreutils-nohup=y
CONFIG_PACKAGE_coreutils-install=y
CONFIG_PACKAGE_tar=y
CONFIG_PACKAGE_gzip=y
CONFIG_PACKAGE_unzip=y
CONFIG_PACKAGE_diffutils=y
CONFIG_PACKAGE_findutils=y
CONFIG_PACKAGE_findutils-find=y
CONFIG_PACKAGE_findutils-xargs=y
CONFIG_PACKAGE_lsblk=y
CONFIG_PACKAGE_blkid=y
CONFIG_PACKAGE_fdisk=y
CONFIG_PACKAGE_parted=y
CONFIG_PACKAGE_losetup=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_btrfs-progs=y
CONFIG_PACKAGE_e2fsprogs=y
CONFIG_PACKAGE_usbutils=y
CONFIG_PACKAGE_pciutils=y
CONFIG_PACKAGE_ethtool=y
CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_tcpdump=y
CONFIG_PACKAGE_lsof=y
CONFIG_PACKAGE_strace=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-ext4=y
## Cursor / VSCode Remote-SSH 远程连接依赖
CONFIG_PACKAGE_openssh-server=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_openssh-client=y
CONFIG_PACKAGE_git=y
CONFIG_PACKAGE_git-http=y
CONFIG_PACKAGE_node=y
CONFIG_PACKAGE_node-npm=y
CONFIG_PACKAGE_libstdcpp6=y
CONFIG_PACKAGE_libatomic1=y
#### ===== end zrm 54 =====
EOF
echo "appended"

echo "=== make defconfig (解析依赖, 丢弃无效项) ==="
cd "$IMM"
export HOME=/home/zrm
make defconfig 2>&1 | tail -20

echo
echo "=== 验证关键包是否最终被选中 ==="
for p in luci uhttpd rpcd luci-base luci-mod-admin-full luci-compat luci-theme-argon \
         wpad-openssl iwinfo wireless-regdb dnsmasq-full bash openssh-sftp-server \
         openssh-server coreutils node git nano htop btrfs-progs curl; do
  if grep -q "^CONFIG_PACKAGE_${p}=y" "$CFG"; then
    echo "OK   $p"
  else
    echo "MISS $p  -> $(grep -m1 "CONFIG_PACKAGE_${p}\b" "$CFG" || echo '(无此包)')"
  fi
done
echo
echo "=== dnsmasq 是否还在(会与 dnsmasq-full 冲突) ==="
grep -E "^CONFIG_PACKAGE_dnsmasq(=y| is not set)" "$CFG" || true
grep -E "^CONFIG_PACKAGE_dnsmasq-full=y" "$CFG" || true
} > "$OUT" 2>&1
echo wrote
