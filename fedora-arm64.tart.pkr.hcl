#!/usr/bin/env packer build --force
#
#  Author: Hari Sekhon
#  Date: 2023-05-28 15:50:29 +0100 (Sun, 28 May 2023)
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

# XXX: Use alternative http.pkr.hcl for now until this issue is resolved:
#
#   https://github.com/cirruslabs/packer-plugin-tart/issues/71

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
      version = ">= 1.3.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

# https://alt.fedoraproject.org/alt/
variable "version" {
  type    = string
  default = "38"
}

variable "iso" {
  type    = string
  default = "Fedora-Server-dvd-aarch64-38-1.6.iso"
}

locals {
  name = "fedora"
  isos = [
    "isos/fedora-${var.version}_cidata.iso",
    "isos/${var.iso}"
  ]
  vm_name = "${local.name}-${var.version}"
}

# https://developer.hashicorp.com/packer/plugins/builders/tart
source "tart-cli" "fedora" {
  vm_name      = local.vm_name
  from_iso     = local.isos
  cpu_count    = 4
  memory_gb    = 4
  disk_size_gb = 40
  # need to mount /cdrom but device not found
  boot_command = [
    "<wait3s><up><wait>",
    "e",
    "<down><down><down><left>",
    # leave a space from last arg
    " inst.ks=file:///cdrom/anaconda-ks.cfg <f10>",
    # go to terminal tty2 for CLI
    # XXX: this Alt-F2 keystroke is coming out unrecognized - https://github.com/cirruslabs/packer-plugin-tart/issues/71
    "<leftAltOn><f2><leftAltOff><wait2s>",
    # 'Press enter to activate this console' - drops into a Busybox shell
    "<enter><wait>",
    "mkdir /mnt/cdrom<enter>",
    "mkdir /mnt/cdrom2<enter>",
    "mount /dev/vdc1 /mnt/cdrom<enter>",
    # without '-t iso9660' gets unintuitive error 'mount: mounting /dev/vdb on /mnt/cdrom2 failed: Invalid argument''
    "mount -t iso9660 /dev/vdb /mnt/cdrom2<enter>",
    # go back to tty1
    # XXX: this Alt-F1 keystroke is coming out unrecognized
    "<leftAltOn><f1><leftAltOff>",
    # TODO: rest of keystrokes once F2 issue is resolved
  ]
  ssh_timeout  = "30m"
  ssh_username = "packer"
  ssh_password = "packer"
}

build {
  name = local.name

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
      "./scripts/final.sh",
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
