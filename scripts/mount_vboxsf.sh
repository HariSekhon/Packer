#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-06-02 05:11:49 +0100 (Fri, 02 Jun 2023)
#
#  https://github.com/HariSekhon/Packer
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

sudo=""
if [ "$EUID" -ne 0 ]; then
    sudo=sudo
fi

dir="/mnt/host"

$sudo mkdir -pv "$dir"

echo "Mounting $dir"
$sudo mount -t vboxsf vboxsf "$dir"

if [ -f /var/log/vboxadd-setup.log ]; then
    cp -fv /var/log/vboxadd-setup.log "$dir/"
fi
