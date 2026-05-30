#!/usr/bin/env bash
# Common settings sourced by all build scripts.
# Forces a clean Linux PATH so leaked Windows PATH entries (e.g. Xilinx dtc)
# never shadow the real cross/host tools, and pins HOME for WSL.
export HOME=/home/zrm
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

BUILD_ROOT=/home/zrm/build
TOOLCHAIN_TGZ=/mnt/d/zrm/orangepi/zero3/toolchains.tar.gz
TOOLCHAIN_DIR="$BUILD_ROOT/toolchains"
KERNEL_DIR="$BUILD_ROOT/linux-orangepi"
UBOOT_DIR="$BUILD_ROOT/u-boot-orangepi"
IMM_DIR="$BUILD_ROOT/immortalwrt"
PACKIT_DIR="$BUILD_ROOT/openwrt_packit"
OUT_DIR="$BUILD_ROOT/output"

mkdir -p "$BUILD_ROOT" "$OUT_DIR"
