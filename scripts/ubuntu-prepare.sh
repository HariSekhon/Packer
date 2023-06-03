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

# Downloads the Ubuntu ISO and generates an ISO with the Ubuntu AutoInstaller configs on which to boot the tart

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

iso="ubuntu-22.04.2-live-server-arm64.iso"

mkdir -p -v "$srcdir/../isos"

cd "$srcdir/../isos"

version="${iso#ubuntu-}"
version="${version%%.[[:digit:]]-*}"

url="https://cdimage.ubuntu.com/releases/$version/release/$iso"

# shellcheck disable=SC2064
#trap "rm -f '$iso'" EXIT
echo "Downloading Ubuntu ISO..."
wget -cO "$iso" "$url"
echo

if [ -d cidata ]; then
	rm -rf cidata*
fi

mkdir -v cidata
echo

cp -v "$srcdir/../installers/user-data" cidata/
cp -v "$srcdir/../installers/meta-data" cidata/
echo

trap "rm -f 'cidata.iso'" EXIT
hdiutil makehybrid -o cidata.iso cidata -joliet -iso

trap '' EXIT

echo
echo "Ubunto ISOs prepared"