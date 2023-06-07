#
#  Author: Hari Sekhon
#  Date: [% DATE  # 2023-05-28 15:50:29 +0100 (Sun, 28 May 2023) %]
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

locals {
  # http://releases.ubuntu.com/
  name    = "ubuntu"
  version = "22.04"
  patch   = "2"
  iso     = "ubuntu-${local.version}.${local.patch}-live-server-amd64.iso"
  #iso     = "ubuntu-${local.version}.${local.patch}-live-server-arm64.iso"
  #url      = "http://releases.ubuntu.com/jammy/${local.iso}"
  #checksum = "5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
  # ARM
  url      = "https://cdimage.ubuntu.com/releases/${local.version}/release/${local.iso}"
  checksum = "12eed04214d8492d22686b72610711882ddf6222b4dc029c24515a85c4874e95"
  vm_name  = "${local.name}-${local.version}"
}

# https://developer.hashicorp.com/packer/plugins/builders/qemu
source "qemu" "ubuntu" {
  vm_name     = "${local.vm_name}"
  qemu_binary = "qemu-system-aarch64"
  #qemu_binary = "qemu-system-x86_64"
  use_default_display = true # might be needed on Mac to avoid errors about sdl not being available
  machine_type        = "virt"
  #accelerator          = "kvm"
  #accelerator          = "tcg"
  #accelerator          = "none"
  iso_url              = local.iso
  iso_checksum         = local.checksum
  cpus                 = 3
  memory               = 3072
  disk_size            = 40960
  disk_additional_size = []
  http_directory       = "installers"
  boot_wait            = "5s"
  boot_steps = [
    ["c<wait>"],
    # XXX: must single quotes the ds=... arg to prevent grub from interpreting the semicolon as a terminator
    # https://cloudinit.readthedocs.io/en/latest/reference/datasources/nocloud.html
    ["linux /casper/vmlinuz autoinstall 'ds=nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/' <enter><wait>"],
    ["initrd /casper/initrd <enter><wait>"],
    ["boot <enter>"]
  ]
  ssh_timeout      = "30m"
  ssh_username     = "packer"
  ssh_password     = "packer"
  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  format           = "qcow2"
  #disk_compression  = true # default: false
  #rtc_time_base    = "UTC"
  #bundle_iso = false # keep the ISO attached
  qemuargs = [
    #["-bios", "/opt/homebrew/Cellar/qemu/8.0.2/share/qemu/edk2-aarch64-code.fd"],
  ]
}

build {
  name = "${local.name}"

  # specify multiple sources defined above to build near identical images for different platforms
  sources = [
    "source.qemu.ubuntu",
  ]

  provisioner "file" {
    source      = "/var/log/installer/autoinstall-user-data"
    destination = "autoinstall-user-data.new"
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
    scripts = [
      "./scripts/version.sh",
      "./scripts/mount_vboxsf.sh",
      "./scripts/collect_autoinstall_user_data.sh",
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