#
#  Author: Hari Sekhon
#  Date: 2023-06-03 01:54:07 +0100 (Sat, 03 Jun 2023)
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

# Uses adjacent Ubuntu Autoinstaller from installers/
#
# 'packer' command must be run from the same directory as this file so the autoinstaller files provided are auto-served via HTTP:
#
# - Ubuntu AutoInstaller - autoinstall-user-data and meta-data files

# ============================================================================ #
#                  P a c k e r   -   U b u n t u   -   T a r t
# ============================================================================ #

# https://github.com/cirruslabs/tart

packer {
  required_version = ">= 1.7.0, < 2.0.0"
  required_plugins {
    tart = {
      version = ">= 0.5.3"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

# https://developer.hashicorp.com/packer/plugins/builders/virtualbox/iso
source "tart-cli" "ubuntu" {
  vm_name = "ubuntu"
  # Browse to http://releases.ubuntu.com/ and pick the latest LTS release
  from_iso     = ["isos/cidata.iso", "isos/ubuntu-22.04.1-live-server-arm64.iso"]
  cpu_count    = 3
  memory_gb    = 3
  disk_size_gb = 40
  boot_wait    = "5s"
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall 'ds=nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/' <enter><wait>",
    "initrd /casper/initrd <enter><wait>",
    "boot <enter>"
  ]
  ssh_timeout  = "30m"
  ssh_username = "packer"
  ssh_password = "packer"
}

build {
  name = "ubuntu"
  sources = [
    "source.tart-cli.ubuntu",
  ]

  provisioner "file" {
    source      = "/var/log/installer/autoinstall-user-data"
    destination = "installers/autoinstall-user-data.new"
    direction   = "download"
  }

  provisioner "shell-local" {
    script = "./scripts/local.sh"
  }

  provisioner "shell" {
    scripts = [
      "./scripts/version.sh",
      "./scripts/vboxsf.sh",
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  provisioner "shell" {
    inline = [
      "cp -fv /var/log/installer/autoinstall-user-data /mnt/vboxsf/",
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}'"
  }

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output/{{.Name}}.{{.ChecksumType}}"
  }

}
