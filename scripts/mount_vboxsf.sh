#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-06-02 05:11:49 +0100 (Fri, 02 Jun 2023)
#
#  https://github.com/HariSekhon/Packer-templates
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
vbox="/mnt/vbox"

$sudo mkdir -pv "$dir" "$vbox"

mount -t iso9660 -o ro "$PWD/VBoxGuestAdditions.iso" "$vbox"

# needs kernel headers
if type -P yum &>/dev/null; then
    yum install -y kernel-headers
elif type -P apt-get &>/dev/null; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y kernel-headers
fi

echo "Install VirtualBox Guest Additions"
$sudo "$vbox/VBoxLinuxAdditions.run"

echo "Mounting $dir"
$sudo mount -t vboxsf vboxsf "$dir"

cp -fv /var/log/vboxadd-setup.log "$dir/"
