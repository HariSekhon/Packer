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

# Uses adjacent Debian Preseed from installers/
#
# 'packer' command must be run from the same directory as this file so the preseed.cfg provided is auto-served via HTTP

# ============================================================================ #
#            P a c k e r   -   D e b i a n   -   V i r t u a l B o x
# ============================================================================ #

packer {
  # Data sources only available in 1.7+
  required_version = ">= 1.7.0, < 2.0.0"
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

# https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/
variable "version" {
  type    = string
  default = "11"
}

variable "iso" {
  type    = string
  default = "debian-12.0.0-amd64-DVD-1.iso" # 4.7GB
}

variable "checksum" {
  type    = string
  default = "85042209e89908d5b59a968ff1be3c54415fa23015bf015562bad8d22452fa80"
}
locals {
  name    = "debian"
  url     = "https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/${var.iso}"
  vm_name = "${local.name}-${var.version}"
}

# https://developer.hashicorp.com/packer/plugins/builders/virtualbox/iso
source "virtualbox-iso" "debian" {
  vm_name              = local.vm_name
  guest_os_type        = "Debian_64"
  iso_url              = local.url
  iso_checksum         = var.checksum
  cpus                 = 2
  memory               = 2048
  disk_size            = 40000
  disk_additional_size = []
  http_directory       = "installers"
  # https://developer.hashicorp.com/packer/plugins/builders/virtualbox/iso#boot-configuration
  boot_wait = "5s"
  # Aliases useful with preseeding
  # https://www.debian.org/releases/stable/amd64/apbs02.en.html
  boot_command = [
    "<down><wait>",
    "<tab><wait>",
    # preseed-md5=... add later
    "fb=true auto=true url=http://{{.HTTPIP}}:{{.HTTPPort}}/preseed.cfg hostname={{.Name}} domain=local <enter>"
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

  sources = ["source.virtualbox-iso.debian"]

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
    scripts = [
      "./scripts/version.sh",
      "./scripts/mount_vboxsf.sh",
      "./scripts/collect_preseed.sh",
      "./scripts/final.sh",
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.BuildName}}/{{.BuildName}}-${var.version}.{{.ChecksumType}}"
  }
}
