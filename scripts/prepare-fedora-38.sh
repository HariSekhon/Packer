#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-06-03 02:04:01 +0100 (Sat, 03 Jun 2023)
#
#  https://github.com/HariSekhon/Packer-templates
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Downloads the Fedora ISO and generates an ISO with the preseed.cfg config on which to boot the tart

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

iso="Fedora-Server-dvd-aarch64-38-1.6.iso"
version="${iso##*-aarch64-}"
version="${version%-*}"

mkdir -p -v "$srcdir/../isos"

cd "$srcdir/../isos"

url="https://download.fedoraproject.org/pub/fedora/linux/releases/$version/Server/aarch64/iso/$iso"

# shellcheck disable=SC2064
#trap "rm -f '$iso'" EXIT
echo "Downloading Fedora ISO..."
wget -cO "$iso" "$url"
echo

cidata_base="fedora-38_cidata"
cidata="$cidata_base/cidata"  # last component must be called 'cidata' for auto-detect during boot
iso="$cidata_base.iso"

if [ -d "$cidata_base" ]; then
	rm -rf "$cidata_base"*
fi

echo "Creating staging dir '$cidata'"
mkdir -pv "$cidata"
echo

cp -v "$srcdir/../installers/anaconda-ks.cfg" "$cidata/"
echo

echo "Creating '$iso'"
hdiutil makehybrid -o "$iso" "$cidata" -joliet -iso
echo

echo "Fedora ISOs prepared"
