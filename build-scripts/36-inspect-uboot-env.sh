#!/usr/bin/env bash
set -uo pipefail
UB=/home/zrm/build/openwrt_packit/files/zero3/u-boot-sunxi-with-spl.bin
echo "=== u-boot bin: $UB ==="
ls -l "$UB" 2>&1
echo "=== 是否支持 distro_bootcmd / 扫描 boot.scr ==="
strings -n 6 "$UB" | grep -iE 'distro_bootcmd|scan_dev_for_scripts|boot_scripts|boot.scr|bootcmd_mmc|scan_dev_for_boot' | sort -u | head -40
echo "=== 默认 bootcmd / preboot ==="
strings -n 6 "$UB" | grep -iE '^bootcmd=|^preboot=|^boot_targets=|^boot_prefixes=|^bootcmd_mmc0=' | head -40
echo "=== 关键字: mmc dev / load / booti 出现情况 ==="
strings -n 4 "$UB" | grep -iE 'orangepiEnv|uEnv|boot.scr|extlinux|sysboot' | sort -u | head -40
echo "=== board / version ==="
strings -n 6 "$UB" | grep -iE 'U-Boot 20|OrangePi|sun50i|h616|h618' | head -10
echo "DONE-UB"
