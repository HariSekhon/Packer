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

# Downloads the Ubuntu ISO and generates an ISO with the Ubuntu AutoInstaller configs on which to boot the tart

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -ne 1 ]; then
    echo "usage: ${0##*/} <iso_url>"
    exit 3
fi

iso="$1"

mkdir -p -v "$srcdir/../isos"

cd "$srcdir/../isos"

version="${iso#ubuntu-}"
version="${version%%-live-server-arm64.iso}"
version="${version%%.[[:digit:]]}"

url="https://cdimage.ubuntu.com/releases/$version/release/$iso"

echo "Downloading Ubuntu ISO..."
wget -cO "$iso" "$url"
echo

cidata_base="ubuntu-${version}_cidata"
cidata="$cidata_base/cidata"  # last component must be called 'cidata' for auto-detect during boot
iso="$cidata_base.iso"

if [ -d "$cidata_base" ]; then
    rm -rf "$cidata_base"*
fi

echo "Creating staging dir '$cidata'"
mkdir -pv "$cidata"
echo

cp -v "$srcdir/../installers/user-data" "$cidata/"
cp -v "$srcdir/../installers/meta-data" "$cidata/"
echo

echo "Creating '$iso'"
hdiutil makehybrid -o "$iso" "$cidata" -joliet -iso
echo

echo "Ubunto ISOs prepared"
