#!/usr/bin/env bash
set -uo pipefail
OUT=/mnt/d/zrm/orangepi/zero3/build-scripts/out-56-feeds.txt
IMM=/home/zrm/build/immortalwrt
CFG="$IMM/.config"
cd "$IMM"
export HOME=/home/zrm
{
echo "=== 1) 下载 luci feed (含重试) ==="
ok=0
for i in 1 2 3 4 5; do
  echo "--- try $i ---"
  if ./scripts/feeds update luci 2>&1 | tail -5; then
    if [ -d feeds/luci ] && ./scripts/feeds list -r luci 2>/dev/null | grep -q "^luci-base"; then ok=1; break; fi
  fi
  sleep 5
done
echo "luci feed ok=$ok"

echo "=== 2) install luci feed 全部包 ==="
./scripts/feeds install -a -p luci 2>&1 | tail -8
echo "-- 显式 install 关键包 --"
./scripts/feeds install luci luci-base luci-compat luci-mod-admin-full luci-theme-argon luci-theme-bootstrap 2>&1 | tail -10

echo "=== 3) 修复 wpad 冲突: 关 basic-mbedtls, 开 wpad-openssl=y ==="
sed -i 's/^CONFIG_PACKAGE_wpad-basic-mbedtls=y/# CONFIG_PACKAGE_wpad-basic-mbedtls is not set/' "$CFG"
sed -i 's/^CONFIG_PACKAGE_wpad-openssl=m/CONFIG_PACKAGE_wpad-openssl=y/' "$CFG"
grep -q "^CONFIG_PACKAGE_wpad-openssl=y" "$CFG" || echo "CONFIG_PACKAGE_wpad-openssl=y" >> "$CFG"

echo "=== 4) make defconfig 再次解析 ==="
make defconfig 2>&1 | tail -8

echo
echo "=== 5) 关键包最终状态 ==="
for p in luci luci-base luci-mod-admin-full luci-compat luci-theme-argon luci-theme-bootstrap \
         luci-mod-network luci-mod-status luci-mod-system luci-app-firewall luci-app-opkg \
         luci-i18n-base-zh-cn luci-i18n-openclash-zh-cn \
         uhttpd uhttpd-mod-ubus rpcd rpcd-mod-iwinfo iwinfo wireless-regdb \
         wpad-openssl dnsmasq-full bash openssh-server openssh-sftp-server node git \
         coreutils nano htop btrfs-progs curl luci-app-openclash; do
  s=$(grep -m1 "^CONFIG_PACKAGE_${p}=" "$CFG")
  [ -n "$s" ] && echo "OK   $s" || echo "MISS $p"
done
} > "$OUT" 2>&1
echo wrote
