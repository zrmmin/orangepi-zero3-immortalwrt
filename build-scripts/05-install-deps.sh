#!/usr/bin/env bash
# Must be run as root (via sudo). Installs ImmortalWrt + general build deps.
# orangepi-build will additionally self-install its own Armbian deps at runtime.
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo "=== apt update ==="
apt-get update -y

echo "=== installing build dependencies ==="
apt-get install -y \
  ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
  bzip2 ccache cmake cpio curl device-tree-compiler fakeroot fastjar flex gawk \
  gettext gcc-multilib g++-multilib git gperf haveged help2man intltool \
  libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev \
  libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
  libssl-dev libtool llvm lrzsz genisoimage msmtp nano ninja-build p7zip \
  p7zip-full patch pkgconf python3 python3-pyelftools python3-setuptools \
  qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs \
  upx-ucl unzip vim wget xmlto xxd zlib1g-dev zstd quilt aria2 jq

echo "DEPS-DONE rc=$?"
