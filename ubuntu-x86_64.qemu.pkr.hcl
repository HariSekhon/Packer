#
#  Author: Hari Sekhon
#  Date: 2023-06-07 21:04:24 +0100 (Wed, 07 Jun 2023)
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

# Uses adjacent Ubuntu Autoinstaller from installers/
#
# 'packer' command must be run from the same directory as this file so the autoinstaller files provided are auto-served via HTTP:
#
# - Ubuntu AutoInstaller - autoinstall-user-data and meta-data files

# ============================================================================ #
#                  P a c k e r   -   U b u n t u   -   Q e m u
# ============================================================================ #

# http://releases.ubuntu.com/
variable "version" {
  type    = string
  default = "22.04"
}

variable "url" {
  type    = string
  default = "http://releases.ubuntu.com/jammy/ubuntu-22.04.2-live-server-amd64.iso"
}

variable "checksum" {
  type    = string
  default = "5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
}

locals {
  name    = "ubuntu"
  vm_name = "${local.name}-${var.version}"
}

source "qemu" "ubuntu" {
  vm_name = local.vm_name
  #iso_url             = "http://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img"
  #iso_checksum_url    = "http://cloud-images.ubuntu.com/releases/bionic/release/SHA256SUMS"
  #iso_checksum_type   = "sha256"
  iso_url              = var.url
  iso_checksum         = var.checksum
  cpus                 = 3
  memory               = 3072
  disk_discard         = "unmap"
  disk_image           = true
  disk_interface       = "virtio-scsi"
  disk_size            = 40960
  disk_additional_size = []
  http_directory       = "installers"
  boot_wait            = "5s"
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall 'ds=nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/' <enter><wait>",
    "initrd /casper/initrd <enter><wait>",
    "boot <enter>"
  ]
  ssh_timeout         = "30m"
  ssh_password        = "packer"
  ssh_username        = "packer"
  shutdown_command    = "echo 'packer' | sudo -S shutdown -P now"
  use_default_display = true
  qemuargs = [
    ["-smbios", "type=1,serial=ds=nocloud-net;instance-id=packer;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/"],
  ]
}

build {
  name = local.name

  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    inline = ["echo Your steps go here."]
  }

  provisioner "file" {
    source      = "/var/log/installer/autoinstall-user-data"
    destination = "autoinstall-user-data.new"
    direction   = "download"
  }

  # https://developer.hashicorp.com/packer/docs/provisioners/shell-local
  #
  #provisioner "shell-local" {
  #  environment_vars = [
  #    "VM_NAME=${local.vm_name}"
  #  ]
  #  script = "./scripts/local_vboxsf.sh"
  #}

  # https://developer.hashicorp.com/packer/docs/provisioners/shell
  #
  provisioner "shell" {
    scripts = [
      "./scripts/version.sh",
      #"./scripts/mount_vboxsf.sh",
      #"./scripts/collect_autoinstall_user_data.sh",
      "./scripts/final.sh"
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.BuildName}}/{{.BuildName}}.{{.ChecksumType}}"
  }

}
