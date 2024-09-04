#!/usr/bin/env packer build --force
#
#  Author: Hari Sekhon
#  Date: 2023-05-28 15:50:29 +0100 (Sun, 28 May 2023)
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

# Uses adjacent Ubuntu Autoinstaller from installers/
#
# 'packer' command must be run from the same directory as this file so the autoinstaller files provided are auto-served via HTTP:
#
# - Ubuntu AutoInstaller - autoinstall-user-data and meta-data files

# WARNING: XXX: Do not build on ARM M1/M2 Macs using VirtualBox 7.0 - as of 2023 VirtualBox 7.0 Beta is extremely buggy, slow,
#               results in "Aborted" VMs and so slow it even misses bootloader keystrokes - it is unworkable on ARM as of this date

# ============================================================================ #
#            P a c k e r   -   U b u n t u   -   V i r t u a l B o x
# ============================================================================ #

packer {
  required_version = ">= 1.7.0, < 2.0.0"
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/virtualbox"
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
  default = "ubuntu-22.04.3-live-server-amd64.iso"
}

variable "checksum" {
  type    = string
  default = "a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
}

locals {
  name    = "ubuntu"
  vm_name = "${local.name}-${var.version}"
  url     = "http://releases.ubuntu.com/${var.version}/${var.iso}"
}

# https://developer.hashicorp.com/packer/plugins/builders/virtualbox/iso
source "virtualbox-iso" "ubuntu" {
  vm_name              = local.vm_name
  guest_os_type        = "Ubuntu_64"
  iso_url              = local.url
  iso_checksum         = var.checksum
  cpus                 = 3
  memory               = 3072
  disk_size            = 40000
  disk_additional_size = []
  http_directory       = "installers"
  boot_wait            = "5s"
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall 'ds=nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/' <enter><wait>",
    "initrd /casper/initrd <enter><wait>",
    "boot <enter>"
  ]
  ssh_timeout      = "30m"
  ssh_username     = "packer"
  ssh_password     = "packer"
  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"
  rtc_time_base    = "UTC"
  bundle_iso       = false
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"],
  ]
  export_opts = [
    "--manifest",
    "--vsys", "0",
  ]
  format = "ova"
}

build {
  name = local.name
  sources = [
    # 22.04 gets split at the dot and results in this error:
    # Error: Unknown source virtualbox-iso.ubuntu-22
    #"source.virtualbox-iso.ubuntu-22.04",
    "source.virtualbox-iso.ubuntu",
  ]

  provisioner "file" {
    source      = "/var/log/installer/autoinstall-user-data"
    destination = "installers/autoinstall-user-data.new"
    direction   = "download"
  }

  # https://developer.hashicorp.com/packer/docs/provisioners/shell-local
  #
  provisioner "shell-local" {
    environment_vars = [
      "VM_NAME=${local.vm_name}"
    ]
    script = "./scripts/local_vboxsf.sh"
  }

  # https://developer.hashicorp.com/packer/docs/provisioners/shell
  #
  provisioner "shell" {
    environment_vars = [
      "VM_NAME=${local.vm_name}"
    ]
    scripts = [
      "./scripts/version.sh",
      "./scripts/mount_vboxsf.sh",
      "./scripts/collect_autoinstall_user_data.sh",
      "./scripts/final.sh",
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  #provisioner "shell" {
  #  inline = [
  #    "cp -fv /var/log/installer/autoinstall-user-data /mnt/vboxsf/",
  #  ]
  #  execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}'"
  #}

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.BuildName}}/{{.BuildName}}.{{.ChecksumType}}"
  }

}
