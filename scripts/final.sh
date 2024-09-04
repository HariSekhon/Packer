#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-06-08 02:28:00 +0100 (Thu, 08 Jun 2023)
#
#  https://github.com/HariSekhon/Packer
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#               P a c k e r   F i n a l   S h e l l   S c r i p t
# ============================================================================ #

# Use to clean up caches, lock out SSH password auth and other cleanup actions

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
#srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Cleaning Caches"
curl -sSf https://raw.githubusercontent.com/HariSekhon/DevOps-Bash-tools/master/bin/clean_caches.sh | sh
echo

# remove this along with packer user after handover to new user accounts / centralized auth system
#echo "Removing /etc/sudoers.d/packer if present"
#rm -fv /etc/sudoers.d/packer
#echo

echo "Disabling SSH password authentication"
# SSH password auth is needed for Packer, but after build disable this
sed -i 's/PasswordAuthentication[[:space:]]*yes/PasswordAuthentication no/' /etc/ssh/sshd_config
