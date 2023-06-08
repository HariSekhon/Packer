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
  iso_url        = var.url
  iso_checksum   = var.checksum
  cpus           = 3
  memory         = 3072
  disk_discard   = "unmap"
  disk_image     = true
  disk_interface = "virtio-scsi"
  disk_size      = 40000
  boot_wait      = "5s"
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall 'ds=nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/' <enter><wait>",
    "initrd /casper/initrd <enter><wait>",
    "boot <enter>"
  ]
  ssh_password        = "packer"
  ssh_username        = "packer"
  shutdown_command    = "echo 'packer' | sudo -S shutdown -P now"
  use_default_display = true
  http_directory      = "installers"
  qemuargs = [
    ["-smbios", "type=1,serial=ds=nocloud-net;instance-id=packer;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/"],
  ]
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    inline = ["echo Your steps go here."]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "/usr/bin/apt-get clean",
      "rm -r /etc/apparmor.d/cache/* /etc/apparmor.d/cache/.features /etc/netplan/50-cloud-init.yaml /etc/ssh/ssh_host* /etc/sudoers.d/90-cloud-init-users",
      "/usr/bin/truncate --size 0 /etc/machine-id",
      "/usr/bin/gawk -i inplace '/PasswordAuthentication/ { gsub(/yes/, \"no\") }; { print }' /etc/ssh/sshd_config",
      "rm -r /root/.ssh",
      "rm /snap/README",
      "find /usr/share/netplan -name __pycache__ -exec rm -r {} +",
      "rm /var/cache/pollinate/seeded /var/cache/snapd/* /var/cache/motd-news",
      "rm -r /var/lib/cloud /var/lib/dbus/machine-id /var/lib/private /var/lib/systemd/timers /var/lib/systemd/timesync /var/lib/systemd/random-seed",
      "rm /var/lib/ubuntu-release-upgrader/release-upgrade-available",
      "rm /var/lib/update-notifier/fsck-at-reboot /var/lib/update-notifier/hwe-eol",
      "find /var/log -type f -exec rm {} +",
      "rm -r /tmp/* /tmp/.*-unix /var/tmp/*",
      "for i in group gshadow passwd shadow subuid subgid; do mv /etc/$i- /etc/$i; done",
      "rm -r /home/packer",
      "/bin/sync",
      "/sbin/fstrim -v /"
    ]
    remote_folder = "/tmp"
  }

}
