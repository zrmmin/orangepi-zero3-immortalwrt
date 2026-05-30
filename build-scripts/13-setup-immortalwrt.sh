#!/usr/bin/env bash
# Configure ImmortalWrt: add OpenClash feed, install feeds, seed .config for
# armsr/armv8 generic rootfs.tar.gz with OpenClash + wifi userspace + packit deps.
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
cd "$IMM_DIR" || { echo "no immortalwrt"; exit 1; }

echo "=== add OpenClash feed (if missing) ==="
if ! grep -q "openclash" feeds.conf.default; then
  echo "src-git openclash https://github.com/vernesong/OpenClash.git;master" >> feeds.conf.default
fi
cat feeds.conf.default

echo
echo "=== feeds update -a ==="
./scripts/feeds update -a

echo
echo "=== feeds install -a ==="
./scripts/feeds install -a

echo
echo "=== confirm luci-app-openclash available ==="
ls -d package/feeds/openclash/luci-app-openclash 2>/dev/null && echo "OPENCLASH_FEED=OK" || echo "OPENCLASH_FEED=MISSING"

echo
echo "=== write .config seed ==="
cat > .config <<'EOF'
# ---- Target: ARM SystemReady armv8 (aarch64 generic), produce rootfs.tar.gz ----
CONFIG_TARGET_armsr=y
CONFIG_TARGET_armsr_armv8=y
CONFIG_TARGET_armsr_armv8_DEVICE_generic=y
CONFIG_TARGET_ROOTFS_TARGZ=y
# avoid building unnecessary image formats for our packit flow
# CONFIG_TARGET_ROOTFS_EXT4FS is not set
# CONFIG_TARGET_ROOTFS_SQUASHFS is not set
# CONFIG_TARGET_IMAGES_GZIP is not set

# ---- OpenClash ----
CONFIG_PACKAGE_luci-app-openclash=y

# ---- LuCI base + zh-cn ----
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-opkg-zh-cn=y
CONFIG_PACKAGE_luci-i18n-openclash-zh-cn=y

# ---- DNS / firewall stack for OpenClash ----
CONFIG_PACKAGE_dnsmasq_full_dhcpv6=y
CONFIG_PACKAGE_dnsmasq-full=y
# CONFIG_PACKAGE_dnsmasq is not set
CONFIG_PACKAGE_iptables-nft=y
CONFIG_PACKAGE_iptables-mod-tproxy=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_coreutils=y
CONFIG_PACKAGE_coreutils-nohup=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_unzip=y

# ---- WiFi userspace (driver/cfg80211 comes from vendor 6.1 kernel) ----
CONFIG_PACKAGE_wpad-basic-mbedtls=y
CONFIG_PACKAGE_hostapd-common=y
CONFIG_PACKAGE_wpa-cli=y
CONFIG_PACKAGE_iw=y
CONFIG_PACKAGE_iwinfo=y

# ---- packit required base packages (EMMC write / online upgrade) ----
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_blkid=y
CONFIG_PACKAGE_fdisk=y
CONFIG_PACKAGE_lsblk=y
CONFIG_PACKAGE_parted=y
CONFIG_PACKAGE_losetup=y
CONFIG_PACKAGE_uuidgen=y
CONFIG_PACKAGE_getopt=y
CONFIG_PACKAGE_gawk=y
CONFIG_PACKAGE_tar=y
CONFIG_PACKAGE_attr=y
CONFIG_PACKAGE_btrfs-progs=y
CONFIG_BTRFS_PROGS_ZSTD=y
CONFIG_PACKAGE_e2fsprogs=y
CONFIG_PACKAGE_f2fs-tools=y
CONFIG_PACKAGE_dosfstools=y
CONFIG_PACKAGE_lsattr=y
CONFIG_PACKAGE_chattr=y
CONFIG_PACKAGE_pigz=y
CONFIG_PACKAGE_p7zip=y

# ---- perl base used by some flippy scripts ----
CONFIG_PACKAGE_perl=y
CONFIG_PACKAGE_perlbase-file=y
CONFIG_PACKAGE_perlbase-getopt=y
CONFIG_PACKAGE_perlbase-time=y
CONFIG_PACKAGE_perlbase-unicode=y
CONFIG_PACKAGE_perlbase-utf8=y
CONFIG_PACKAGE_perl-http-date=y

# ---- handy ----
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_kmod-fs-btrfs=y
EOF

echo "=== make defconfig ==="
make defconfig

echo
echo "=== verify key selections in resulting .config ==="
grep -E "CONFIG_TARGET_armsr_armv8_DEVICE_generic=y|CONFIG_TARGET_ROOTFS_TARGZ=y|luci-app-openclash=y|dnsmasq-full=y|wpad-basic-mbedtls=y" .config

echo "SETUP-IMM-DONE"
