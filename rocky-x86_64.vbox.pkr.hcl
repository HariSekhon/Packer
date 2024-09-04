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

# Uses adjacent Redhat Kickstart from installers/
#
# 'packer' command must be run from the same directory as this file so the anaconda-ks.cfg provided is auto-served via HTTP

# ============================================================================ #
#       P a c k e r   -   R o c k y   L i n u x   -   V i r t u a l B o x
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

# https://alt.rockyproject.org/alt/
variable "version" {
  type    = string
  default = "9.2"
}

variable "iso" {
  type    = string
  default = "Rocky-9.2-x86_64-dvd.iso"
}

variable "checksum" {
  type    = string
  default = "cd43bb2671472471b1fc0a7a30113dfc9a56831516c46f4dbd12fb43bb4286d2"
}

locals {
  name    = "rocky"
  url     = "https://download.rockylinux.org/pub/rocky/${split(".", var.version)[0]}/isos/x86_64/${var.iso}"
  vm_name = "${local.name}-${var.version}"
}

# https://developer.hashicorp.com/packer/plugins/builders/virtualbox/iso
source "virtualbox-iso" "rocky" {
  vm_name              = local.vm_name
  guest_os_type        = "Redhat_64"
  iso_url              = local.url
  iso_checksum         = var.checksum
  cpus                 = 3
  memory               = 3072
  disk_size            = 40000
  disk_additional_size = []
  http_directory       = "installers"
  boot_wait            = "5s"
  boot_command = [
    "<up><tab>",
    " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/anaconda-ks.cfg <enter>"
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

  sources = ["source.virtualbox-iso.rocky"]

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
      "./scripts/install_vbox_additions.sh",
      "./scripts/mount_vboxsf.sh",
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
  #    "for x in anaconda-ks.cfg ks-pre.log ks-post.log; do if [ -f /root/$x ]; then cp -fv /root/$x /mnt/vboxsf/; fi; done"
  #  ]
  #}

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.BuildName}}/{{.BuildName}}.{{.ChecksumType}}"
  }
}
