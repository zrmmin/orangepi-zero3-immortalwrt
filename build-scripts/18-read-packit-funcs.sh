#!/usr/bin/env bash
set -uo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
P="$PACKIT_DIR"
PF="$P/public_funcs"

for fn in init_work_env get_openwrt_rootfs_archive check_depends create_image \
          create_partition make_filesystem mount_fs extract_rootfs_files \
          copy_uboot_to_fs write_uboot_to_disk adjust_kernel_env create_fstab_config; do
  echo "############ $fn ############"
  awk "/^function ${fn}\\(\\)|^${fn}\\(\\)/{f=1} f{print} f&&/^}/{exit}" "$PF" 2>/dev/null
  echo
done

echo "############ make.env ############"
cat "$P/make.env" 2>/dev/null

echo
echo "############ vplus update-u-boot.sh ############"
cat "$P/files/vplus/u-boot-v2022.04/update-u-boot.sh" 2>/dev/null

echo
echo "############ KERNEL_PKG_HOME / KERNEL_VERSION usage ############"
grep -nE "KERNEL_PKG_HOME|KERNEL_VERSION=|LOCK_KERNEL|KERNEL_PATH" "$PF" "$P/make.env" 2>/dev/null | head -n 30
echo "READ18-DONE"
