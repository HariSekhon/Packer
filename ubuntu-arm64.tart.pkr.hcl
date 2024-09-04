#!/usr/bin/env packer build --force
#
#  Author: Hari Sekhon
#  Date: 2023-06-03 01:54:07 +0100 (Sat, 03 Jun 2023)
#
#  vim:ts=2:sts=2:sw=2:et:filetype=conf
#
#  https://github.com/HariSekhon/Packer
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
# Must run 'scripts/prepare-ubuntu-22.04.sh' first to download the ISO and generate another ISO with the AutoInstaller config
#
# 'packer' command must be run from the same directory as this file so the ISO files are found under iso/

# ============================================================================ #
#                  P a c k e r   -   U b u n t u   -   T a r t
# ============================================================================ #

# https://github.com/cirruslabs/tart

packer {
  required_version = ">= 1.7.0, < 2.0.0"
  required_plugins {
    tart = {
      version = ">= 1.3.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

# http://releases.ubuntu.com/
variable "version" {
  type    = string
  default = "22.04"
}

variable "iso" {
  type    = string
  default = "isos/ubuntu-22.04.3-live-server-arm64.iso"
}

locals {
  name = "ubuntu"
  isos = [
    "isos/ubuntu-${var.version}_cidata.iso",
    "isos/${var.iso}"
  ]
  vm_name = "${local.name}-${var.version}"
}

# https://developer.hashicorp.com/packer/plugins/builders/tart
source "tart-cli" "ubuntu" {
  vm_name      = local.vm_name
  from_iso     = local.isos
  cpu_count    = 4
  memory_gb    = 4
  disk_size_gb = 40
  #boot_command = [
  #  # boot grub without waiting for 30 sec countdown on default option
  #  "<wait3s><enter>",
  #  # auto-detects the cidata iso and prompts:
  #  # Continue with autoinstall? (yes|no)
  #  "<wait30s>yes<enter>"
  #]
  boot_command = [
    "<wait3s>",
    "e<down><down><down><down><left>",
    " autoinstall<f10>",
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
  name = "ubuntu-${var.version}"
  sources = [
    # 22.04 gets separated at the dot and results in this error:
    # Error: Unknown source tart-cli.ubuntu-22
    #"source.tart-cli.ubuntu-22.04",
    "source.tart-cli.ubuntu",
  ]

  provisioner "file" {
    source      = "/var/log/installer/autoinstall-user-data"
    destination = "installers/autoinstall-user-data.new"
    direction   = "download"
  }

  provisioner "shell-local" {
    script = "./scripts/local_virtiofs.sh"
  }

  provisioner "shell" {
    scripts = [
      "./scripts/version.sh",
      "./scripts/mount_apple_virtiofs.sh",
      "./scripts/collect_autoinstall_user_data.sh",
      "./scripts/final.sh",
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  #provisioner "shell" {
  #  inline = [
  #    "cp -fv /var/log/installer/autoinstall-user-data /mnt/virtiofs/",
  #  ]
  #  execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}'"
  #}

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.BuildName}}/{{.BuildName}}.{{.ChecksumType}}"
  }

}
