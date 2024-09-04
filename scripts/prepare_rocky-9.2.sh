#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-06-03 02:04:01 +0100 (Sat, 03 Jun 2023)
#
#  https://github.com/HariSekhon/Packer
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Downloads the Rocky ISO and generates an ISO with the preseed.cfg config on which to boot the tart

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

iso="Rocky-9.2-aarch64-dvd.iso"
version="${iso##*Rocky-}"
version="${version%%.*}"

mkdir -p -v "$srcdir/../isos"

cd "$srcdir/../isos"

url="https://download.rockylinux.org/pub/rocky/$version/isos/aarch64/$iso"

echo "Downloading Rocky ISO..."
wget -cO "$iso" "$url"
echo

cidata="rocky-9.2_cidata"
iso="$cidata.iso"

if [ -d "$cidata" ]; then
    rm -rf "$cidata"*
fi

echo "Creating staging dir '$cidata'"
mkdir -pv "$cidata"
echo

cp -v "$srcdir/../installers/anaconda-ks.cfg" "$cidata/"
echo

echo "Creating '$iso'"
hdiutil makehybrid -o "$iso" "$cidata" -joliet -iso
echo

echo "Rocky ISOs prepared"
