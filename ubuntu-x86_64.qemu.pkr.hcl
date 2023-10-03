#!/usr/bin/env packer build --force
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

packer {
  # Data sources only available in 1.7+
  required_version = ">= 1.7.0, < 2.0.0"
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
  url     = "http://releases.ubuntu.com/${var.version}/${var.iso}"
  vm_name = "${local.name}-${var.version}"
  arch    = "x86_64"
}

# https://developer.hashicorp.com/packer/plugins/builders/qemu
source "qemu" "ubuntu" {
  vm_name              = local.vm_name
  qemu_binary          = "qemu-system-x86_64"
  machine_type         = "pc"
  iso_url              = local.url
  iso_checksum         = var.checksum
  cpus                 = 3
  memory               = 3072
  net_device           = "virtio-net"
  disk_interface       = "virtio-scsi" # or virtio?
  format               = "qcow2"
  disk_discard         = "unmap"
  disk_image           = true
  disk_size            = 40960
  disk_additional_size = []
  output_directory     = "output-${local.vm_name}-${local.arch}"
  headless             = false
  use_default_display  = true # might be needed on Mac to avoid errors about sdl not being available
  http_directory       = "installers"
  ssh_timeout          = "30m"
  ssh_password         = "packer"
  ssh_username         = "packer"
  shutdown_command     = "echo 'packer' | sudo -S shutdown -P now"
  boot_wait            = "5s"
  boot_steps = [
    ["c<wait>"],
    # XXX: must single quotes the ds=... arg to prevent grub from interpreting the semicolon as a terminator
    # https://cloudinit.readthedocs.io/en/latest/reference/datasources/nocloud.html
    ["linux /casper/vmlinuz autoinstall 'ds=nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/' <enter><wait>"],
    ["initrd /casper/initrd <enter><wait>"],
    ["boot <enter>"]
  ]
  qemuargs = [
    #["-smbios", "type=1,serial=ds=nocloud-net;instance-id=packer;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/"],
    # spice-app isn't respected despite doc https://www.qemu.org/docs/master/system/invocation.html#hxtool-3
    # packer-builder-qemu plugin: Qemu stderr: qemu-system-x86_64: -display spice-app: Parameter 'type' does not accept value 'spice-app'
    #["-display", "spice-app"],
    #["-display", "cocoa"],  # Mac only
    #["-display", "vnc:0"],  # starts VNC by default, but doesn't launch user's vncviewer - ubuntu-x86_64.qemu.pkr.hcl
  ]
  # Only on ARM Macs
  #machine_type = "virt"  # packer-builder-qemu plugin: Qemu stderr: qemu-system-x86_64: unsupported machine type
}

build {
  name = local.name

  sources = ["source.qemu.ubuntu"]

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
    output              = "output-{{.BuildName}}-${local.arch}/{{.BuildName}}.{{.ChecksumType}}"
  }

}
