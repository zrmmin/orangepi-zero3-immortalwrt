#!/usr/bin/env bash
# 编出 wifi-scripts(ucode版) + 其 ucode 依赖, 供注入镜像让 LuCI/netifd 接管板载 AP
set -uo pipefail
IMM=/home/zrm/build/immortalwrt
cd "$IMM" || exit 1

echo "=== 启用 wifi-scripts 及依赖 ==="
for c in \
  CONFIG_PACKAGE_wifi-scripts \
  CONFIG_PACKAGE_ucode-mod-nl80211 \
  CONFIG_PACKAGE_ucode-mod-rtnl \
  CONFIG_PACKAGE_ucode-mod-ubus \
  CONFIG_PACKAGE_ucode-mod-uci \
  CONFIG_PACKAGE_ucode-mod-digest ; do
  sed -i "/^# ${c} is not set/d" .config
  grep -q "^${c}=y" .config || echo "${c}=y" >> .config
done
echo 'CONFIG_WIFI_SCRIPTS_UCODE=y' >> .config
grep -q '^CONFIG_PACKAGE_wpad' .config && echo "wpad 已在 config"

make defconfig >/dev/null 2>&1
echo "=== defconfig 后确认 ==="
grep -iE 'CONFIG_PACKAGE_wifi-scripts=|WIFI_SCRIPTS_UCODE|ucode-mod-(nl80211|rtnl|ubus|uci|digest)=' .config

echo "=== 编译 wifi-scripts + ucode 依赖 ==="
make -j4 \
  package/network/config/wifi-scripts/compile \
  package/utils/ucode/compile \
  V=s 2>&1 | tail -25

echo "=== 收集 ipk ==="
mkdir -p /home/zrm/build/wifi-ipks
find "$IMM/bin" -name 'wifi-scripts*.ipk' -o -name 'ucode-mod-*.ipk' -o -name 'ucode_*.ipk' 2>/dev/null | while read -r f; do
  cp -f "$f" /home/zrm/build/wifi-ipks/
done
ls -l /home/zrm/build/wifi-ipks/
echo "BUILD-WIFISCRIPTS-DONE"
