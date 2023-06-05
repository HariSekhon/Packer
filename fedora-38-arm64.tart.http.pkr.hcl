#
#  Author: Hari Sekhon
#  Date: [% DATE  # 2023-05-28 15:50:29 +0100 (Sun, 28 May 2023) %]
#
#  vim:ts=2:sts=2:sw=2:et:filetype=conf
#
#  https://github.com/HariSekhon/Packer-templates
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Requires macOS Ventura 13.4
#
# Must run 'scripts/prepare_fedora-38.sh' first to download the ISO and generate another ISO with the anaconda-ks.cfg
#
# 'packer' command must be run from the same directory as this file so the ISO files are found under iso/

# ============================================================================ #
#                  P a c k e r   -   F e d o r a   -   T a r t
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

locals {
  version = "38"
  patch   = "1.6"
  isos = [
    #"isos/fedora-38_cidata.iso",
    "isos/Fedora-Server-dvd-aarch64-${local.version}-${local.patch}.iso"
  ]
}

# https://developer.hashicorp.com/packer/plugins/builders/tart
source "tart-cli" "fedora" {
  vm_name = "fedora-${local.version}"
  # https://alt.fedoraproject.org/alt/
  from_iso     = local.isos
  cpu_count    = 4
  memory_gb    = 4
  disk_size_gb = 40
  boot_command = [
    "<wait3s><up><wait>",
    "e",
    "<down><down><down><left>",
    # leave a space from last arg
    " inst.ks=http://192.168.64.1:8000/anaconda-ks.cfg <f10>"
  ]
  ssh_timeout  = "30m"
  ssh_username = "packer"
  ssh_password = "packer"
}

build {
  name = "fedora"

  sources = ["source.tart-cli.fedora"]

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
      "./scripts/collect_anaconda.sh",
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  # https://developer.hashicorp.com/packer/docs/provisioners/shell
  #
  #provisioner "shell" {
  #  execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}'"
  #  inline = [
  #    "for x in anaconda-ks.cfg ks-pre.log ks-post.log; do if [ -f /root/$x ]; then cp -fv /root/$x /mnt/virtiofs/; fi; done"
  #  ]
  #}

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.BuildName}}/{{.BuildName}}.{{.ChecksumType}}"
  }
}
