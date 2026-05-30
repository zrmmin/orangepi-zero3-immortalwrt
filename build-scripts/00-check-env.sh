#!/usr/bin/env bash
# Environment diagnostic for Orange Pi Zero3 ImmortalWrt build
set -u
export HOME=/home/zrm
cd "$HOME" || exit 1

echo "=== whoami / home ==="
whoami
echo "HOME=$HOME"
pwd

echo
echo "=== sudo ==="
if sudo -n true 2>/dev/null; then
  echo "SUDO_NOPASSWD=yes"
else
  echo "SUDO_NOPASSWD=no"
fi

echo
echo "=== resources ==="
nproc
free -h | head -n2
df -h "$HOME" | tail -n1

echo
echo "=== tools ==="
for t in git make gcc g++ gawk bison flex python3 rsync unzip wget file \
         libtool patch dtc ccache swig quilt; do
  if command -v "$t" >/dev/null 2>&1; then
    printf '%-10s OK  %s\n' "$t" "$(command -v "$t")"
  else
    printf '%-10s MISSING\n' "$t"
  fi
done

echo
echo "=== build dir ==="
mkdir -p "$HOME/build"
ls -ld "$HOME/build"

echo
echo "=== toolchains.tar.gz ==="
ls -l /mnt/d/zrm/orangepi/zero3/toolchains.tar.gz 2>/dev/null || echo "not found"

echo
echo "DONE"
