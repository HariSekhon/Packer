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

dir="/mnt/vbox"

uname -a

$sudo mkdir -pv "$dir"

mount -t iso9660 -o ro "$PWD/VBoxGuestAdditions.iso" "$dir"

# needs kernel headers
if type -P yum &>/dev/null; then
    yum install -y kernel-headers \
                   kernel-devel
    # don't really need to fix this
    # /opt/VBoxGuestAdditions-7.0.8/bin/VBoxClient: error while loading shared libraries: libX11.so.6: cannot open shared object file: No such file or directory
                   #libX11 \
                   #libXt \
                   #libXext \
                   #libXmu
    # might be overkill
    #yum groupinstall "Development Tools"
elif type -P apt-get &>/dev/null; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    # might be overkill
    apt-get install -y build-essential
fi

echo "Install VirtualBox Guest Additions"
$sudo "$dir/VBoxLinuxAdditions.run"
