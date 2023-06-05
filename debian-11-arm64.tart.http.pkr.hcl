#
#  Author: Hari Sekhon
#  Date: [% DATE  # 2023-05-28 15:50:29 +0100 (Sun, 28 May 2023) %]
#
#  vim:ts=2:sts=2:sw=2:et:filetype=conf
#
#  https://github.com/HariSekhon/Templates
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Requires macOS Ventura 13.4
#
# Must run 'scripts/prepare-debian-11.sh' first to download the ISO and generate another ISO with the preseed.cfg
#
# 'packer' command must be run from the same directory as this file so the ISO files are found under iso/

# ============================================================================ #
#                  P a c k e r   -   D e b i a n   -   T a r t
# ============================================================================ #

packer {
  # Data sources only available in 1.7+
  required_version = ">= 1.7.0, < 2.0.0"
  required_plugins {
    tart = {
      version = ">= 0.5.3"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

# https://developer.hashicorp.com/packer/plugins/builders/tart
source "tart-cli" "debian-11" {
  vm_name = "debian-11"
  # https://www.debian.org/CD/http-ftp/
  from_iso = [
    #"isos/debian-11_cidata.iso",
    "isos/debian-11.7.0-arm64-DVD-1.iso"
  ]
  cpu_count    = 4
  memory_gb    = 4
  disk_size_gb = 40
  # completely different installer to the x86_64, requiring different boot_command
  boot_command = [
    "<wait3s>",
    "e<wait>",
    "<down><down><down><down><left>",
    # preseed-md5=... add later                          {{.Name}} not available in this plugin to use for hostname, gets 'hostname=<no value>'
    " auto=true url=http://192.168.64.1:8000/preseed.cfg hostname=debian domain=local <f10>"
  ]
  ssh_timeout  = "30m"
  ssh_username = "packer"
  ssh_password = "packer"
}

build {
  name = "debian-11"

  sources = ["source.tart-cli.debian-11"]

  # https://developer.hashicorp.com/packer/docs/provisioners/shell-local
  #
  provisioner "shell-local" {
    script = "./scripts/local.sh"
  }

  # https://developer.hashicorp.com/packer/docs/provisioners/shell
  #
  provisioner "shell" {
    script          = "./scripts/version.sh"
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.BuildName}}/{{.BuildName}}.{{.ChecksumType}}"
  }
}
