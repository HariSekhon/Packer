#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-06-05 19:05:31 +0100 (Mon, 05 Jun 2023)
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
#srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# must be run as root to be able to detect files under /root to copy out

distro="$(awk -F= '/^ID=/{printf $2}' /etc/os-release | sed 's/"//g')"
version="$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | sed 's/"//g')"

echo "Distro was detemined to be '$distro-$version'"
echo

for x in anaconda-ks.cfg ks-pre.log ks-post.log; do
    if [ -f /root/$x ]; then
        cp -fv "/root/$x" "/mnt/host/$x-$distro-$version";
    fi
done
