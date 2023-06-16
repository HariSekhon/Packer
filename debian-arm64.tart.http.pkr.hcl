#!/usr/bin/env packer build --force
#
#  Author: Hari Sekhon
#  Date: 2023-05-28 15:50:29 +0100 (Sun, 28 May 2023)
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
# Must run 'scripts/prepare_debian-11.sh' first to download the ISO and generate another ISO with the preseed.cfg
#
# Must run 'python3 -m http.server -d installers' from this same directory before running 'packer'
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
      version = ">= 1.3.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

# https://deb.debian.org/debian/dists/
variable "version" {
  type    = string
  default = "11"
}

variable "iso" {
  type    = string
  default = "debian-11.7.0-arm64-DVD-1.iso"
}

locals {
  name = "debian"
  isos = [
    #"isos/debian-${var.version}_cidata.iso",
    "isos/${var.iso}"
  ]
  vm_name = "${local.name}-${var.version}"
}

# https://developer.hashicorp.com/packer/plugins/builders/tart
source "tart-cli" "debian" {
  vm_name = local.vm_name
  # https://www.debian.org/CD/http-ftp/
  from_iso     = local.isos
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
  name = "debian"

  sources = ["source.tart-cli.debian"]

  # https://developer.hashicorp.com/packer/docs/provisioners/shell-local
  #
  provisioner "shell-local" {
    script = "./scripts/local_virtiofs.sh"
  }

  # https://developer.hashicorp.com/packer/docs/provisioners/shell
  #
  provisioner "shell" {
    scripts = [
      "./scripts/version.sh",
      "./scripts/mount_apple_virtiofs.sh",
      "./scripts/collect_preseed.sh",
      "./scripts/final.sh",
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.BuildName}}/{{.BuildName}}.{{.ChecksumType}}"
  }
}
