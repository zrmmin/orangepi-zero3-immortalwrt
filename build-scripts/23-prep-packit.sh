#!/usr/bin/env bash
# Prepare openwrt_packit for Orange Pi Zero3:
#  - install u-boot built earlier
#  - generate mk_h618_zero3.sh (no-initrd boot, onboard uwe5622 wifi autoload)
set -euo pipefail
source /mnt/d/zrm/orangepi/zero3/build-scripts/lib-common.sh
P="$PACKIT_DIR"

echo "=== place u-boot binary ==="
mkdir -p "$P/files/zero3"
cp "$BUILD_ROOT/uboot_extract/usr/lib/linux-u-boot-next-orangepizero3_1.0.6_arm64/u-boot-sunxi-with-spl.bin" \
   "$P/files/zero3/u-boot-sunxi-with-spl.bin"
ls -l "$P/files/zero3/"

echo "=== generate mk_h618_zero3.sh ==="
cat > "$P/mk_h618_zero3.sh" <<'MKEOF'
#!/bin/bash
echo "========================= begin $0 ================="
source make.env
source public_funcs
init_work_env

PLATFORM=allwinner
SOC=h618
BOARD=zero3
SUBVER=$1

# Kernel image sources
MODULES_TGZ=${KERNEL_PKG_HOME}/modules-${KERNEL_VERSION}.tar.gz
check_file ${MODULES_TGZ}
BOOT_TGZ=${KERNEL_PKG_HOME}/boot-${KERNEL_VERSION}.tar.gz
check_file ${BOOT_TGZ}
DTBS_TGZ=${KERNEL_PKG_HOME}/dtb-allwinner-${KERNEL_VERSION}.tar.gz
check_file ${DTBS_TGZ}

# Openwrt rootfs
OPWRT_ROOTFS_GZ=$(get_openwrt_rootfs_archive ${PWD})
check_file ${OPWRT_ROOTFS_GZ}
echo "Use $OPWRT_ROOTFS_GZ as openwrt rootfs!"

TGT_IMG="${WORK_DIR}/openwrt_${SOC}_${BOARD}_${OPENWRT_VER}_k${KERNEL_VERSION}${SUBVER}.img"

# shared scripts / patches (same set as the allwinner H6 template)
CPUSTAT_SCRIPT="${PWD}/files/cpustat"
CPUSTAT_SCRIPT_PY="${PWD}/files/cpustat.py"
INDEX_PATCH_HOME="${PWD}/files/index.html.patches"
GETCPU_SCRIPT="${PWD}/files/getcpu"
KMOD="${PWD}/files/kmod"
FIRSTRUN_SCRIPT="${PWD}/files/first_run.sh"
DAEMON_JSON="${PWD}/files/vplus/daemon.json"
TTYD="${PWD}/files/ttyd"
FLIPPY="${PWD}/files/scripts_deprecated/flippy_cn"
BANNER="${PWD}/files/banner"
FMW_HOME="${PWD}/files/firmware"
SMB4_PATCH="${PWD}/files/smb4.11_enable_smb1.patch"
SYSCTL_CUSTOM_CONF="${PWD}/files/99-custom.conf"
COREMARK="${PWD}/files/coremark.sh"
BAL_ETH_IRQ="${PWD}/files/balethirq.pl"
FIX_CPU_FREQ="${PWD}/files/fixcpufreq.pl"
SYSFIXTIME_PATCH="${PWD}/files/sysfixtime.patch"
SSL_CNF_PATCH="${PWD}/files/openssl_engine.patch"
SS_LIB="${PWD}/files/ss-glibc/lib-glibc.tar.xz"
SS_BIN="${PWD}/files/ss-glibc/armv8a_crypto/ss-bin-glibc.tar.xz"
JQ="${PWD}/files/jq"
DOCKERD_PATCH="${PWD}/files/dockerd.patch"
FIRMWARE_TXZ="${PWD}/files/firmware_armbian.tar.xz"
BOOTFILES_HOME="${PWD}/files/bootfiles/allwinner"
DOCKER_README="${PWD}/files/DockerReadme.pdf"
SYSINFO_SCRIPT="${PWD}/files/30-sysinfo.sh"
OPENWRT_KERNEL="${PWD}/files/openwrt-kernel"
OPENWRT_BACKUP="${PWD}/files/openwrt-backup"
OPENWRT_UPDATE="${PWD}/files/openwrt-update-allwinner"
P7ZIP="${PWD}/files/7z"
DDBR="${PWD}/files/openwrt-ddbr"
SSH_CIPHERS="aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr,chacha20-poly1305@openssh.com"
SSHD_CIPHERS="aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr"

# u-boot built by orangepi-build (BRANCH=next, v2024.01 + ATF sun50i_h616)
UBOOT_BIN="${PWD}/files/zero3/u-boot-sunxi-with-spl.bin"

check_depends
SKIP_MB=16
BOOT_MB=256
ROOTFS_MB=1024
SIZE=$((SKIP_MB + BOOT_MB + ROOTFS_MB))
create_image "$TGT_IMG" "$SIZE"
create_partition "$TGT_DEV" "msdos" "$SKIP_MB" "$BOOT_MB" "fat32" "0" "-1" "btrfs"
make_filesystem "$TGT_DEV" "B" "fat32" "EMMC_BOOT" "R" "btrfs" "EMMC_ROOTFS1"
mount_fs "${TGT_DEV}p1" "${TGT_BOOT}" "vfat"
mount_fs "${TGT_DEV}p2" "${TGT_ROOT}" "btrfs" "compress=zstd:${ZSTD_LEVEL}"
echo "创建 /etc 子卷 ..."
btrfs subvolume create $TGT_ROOT/etc
extract_rootfs_files
extract_allwinner_boot_files

echo "写入 Orange Pi Zero3 专用引导(无 initrd, 主线 u-boot distro_bootcmd) ... "
cd $TGT_BOOT
rm -f boot-emmc.cmd boot-emmc.scr uInitrd
cat > boot.cmd <<'BOOTEOF'
# Orange Pi Zero3 (H618) OpenWrt boot script - no initrd (ext4/btrfs/mmc built-in)
echo "Boot Orange Pi Zero3 OpenWrt ..."
setenv loadaddr "0x45000000"
setenv l_mmc "0"
for devtype in "mmc" ; do
    for devnum in ${l_mmc} ; do
        if test -e ${devtype} ${devnum} uEnv.txt; then
            load ${devtype} ${devnum} ${loadaddr} uEnv.txt
            env import -t ${loadaddr} ${filesize}
            setenv bootargs ${APPEND}
            if load ${devtype} ${devnum} ${kernel_addr_r} ${LINUX}; then
                if load ${devtype} ${devnum} ${fdt_addr_r} ${FDT}; then
                    fdt addr ${fdt_addr_r}
                    booti ${kernel_addr_r} - ${fdt_addr_r}
                fi
            fi
        fi
    done
done
BOOTEOF
mkimage -C none -A arm64 -T script -d boot.cmd boot.scr
echo "boot.scr 生成完成"

cat > uEnv.txt <<EOF
LINUX=/zImage
FDT=/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb

APPEND=root=UUID=${ROOTFS_UUID} rootfstype=btrfs rootflags=compress=zstd:${ZSTD_LEVEL} console=ttyS0,115200n8 console=tty1 no_console_suspend consoleblank=0 rw fsck.fix=yes fsck.repair=yes net.ifnames=0 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1
EOF
echo "uEnv.txt -->"
echo "======================================================================================"
cat uEnv.txt
echo "======================================================================================"
echo

echo "修改根文件系统相关配置 ... "
cd $TGT_ROOT
copy_supplement_files
extract_glibc_programs
adjust_docker_config
adjust_openssl_config
adjust_qbittorrent_config
adjust_getty_config
adjust_samba_config
adjust_nfs_config "mmcblk0p4"
adjust_openssh_config
adjust_openclash_config
use_xrayplug_replace_v2rayplug
create_fstab_config
adjust_turboacc_config
adjust_ntfs_config
adjust_mosdns_config
patch_admin_status_index_html
adjust_kernel_env
copy_uboot_to_fs
write_release_info
write_banner
config_first_run

echo "启用板载 Cdtech 20U5622 (uwe5622) 无线网卡模块自动加载 ... "
mkdir -p ./etc/modules.d
echo "uwe5622_bsp_sdio" > ./etc/modules.d/50-uwe5622-bsp
echo "sprdwl_ng" > ./etc/modules.d/51-sprdwl-ng
echo "完成"

create_snapshot "etc-000"
write_uboot_to_disk
clean_work_env
mv $TGT_IMG $OUTPUT_DIR && sync
echo "镜像已生成, 存放在 ${OUTPUT_DIR} 下面"
echo "========================== end $0 ================================"
echo
MKEOF
chmod +x "$P/mk_h618_zero3.sh"
sed -n '1,20p' "$P/mk_h618_zero3.sh"
echo "PREP-PACKIT-DONE"
