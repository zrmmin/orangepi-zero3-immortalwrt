#!/usr/bin/env bash
# Run as root (sudo -S). Temporarily grant passwordless sudo to user zrm
# so the long unattended orangepi-build / packit steps don't stall on prompts.
set -uo pipefail
echo "zrm ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/zrm-build
chmod 440 /etc/sudoers.d/zrm-build
echo "wrote /etc/sudoers.d/zrm-build:"
cat /etc/sudoers.d/zrm-build
echo "NOPASSWD-SETUP-DONE"
