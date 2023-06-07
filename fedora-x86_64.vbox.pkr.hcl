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

# Uses adjacent Redhat Kickstart from installers/
#
# 'packer' command must be run from the same directory as this file so the anaconda-ks.cfg provided is auto-served via HTTP

# ============================================================================ #
#            P a c k e r   -   F e d o r a   -   V i r t u a l B o x
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

# https://alt.fedoraproject.org/alt/
variable "version" {
  type    = string
  default = "38"
}

variable "iso" {
  type    = string
  default = "Fedora-Server-dvd-x86_64-38-1.6.iso"
}

locals {
  name     = "fedora-${var.version}"
  url      = "https://download.fedoraproject.org/pub/fedora/linux/releases/${var.version}/Server/x86_64/iso/${var.iso}"
  checksum = "09dee2cd626a269aefc67b69e63a30bd0baa52d4"
  vm_name  = "${local.name}-${var.version}"
}

# https://developer.hashicorp.com/packer/plugins/builders/virtualbox/iso
source "virtualbox-iso" "fedora" {
  vm_name              = "${local.vm_name}"
  guest_os_type        = "Fedora_64"
  iso_url              = local.url
  iso_checksum         = local.checksum
  cpus                 = 3
  memory               = 3072
  disk_size            = 40000
  disk_additional_size = []
  http_directory       = "installers"
  boot_wait            = "5s"
  boot_command = [
    "<up><wait>",
    "e",
    "<down><down><down><left>",
    # leave a space from last arg
    " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/anaconda-ks.cfg <f10>"
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
  name = "${local.name}"

  sources = ["source.virtualbox-iso.fedora"]

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
      "./scripts/collect_anaconda.sh",
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
