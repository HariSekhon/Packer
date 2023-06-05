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

# Requires macOS Ventura 13.4
#
# Must run 'scripts/prepare-debian-11.sh' first to download the ISO and generate another ISO with the preseed.cfg
#
# 'packer' command must be run from the same directory as this file so the ISO files are found under iso/

# ============================================================================ #
#                  P a c k e r   -   D e b i a n   -   T a r t
# ============================================================================ #

packer {
  # Data sources only available in 1.7+
  required_version = ">= 1.7.0, < 2.0.0"
  required_plugins {
    tart = {
      version = ">= 0.5.3"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

# https://developer.hashicorp.com/packer/plugins/builders/tart
source "tart-cli" "debian-11" {
  vm_name = "debian-11"
  # https://www.debian.org/CD/http-ftp/
  from_iso = [
    "isos/debian-11_cidata.iso",
    "isos/debian-11.7.0-arm64-DVD-1.iso"
  ]
  cpu_count    = 4
  memory_gb    = 4
  disk_size_gb = 40
  boot_command = [
    "<wait2s>",
    "e<down><down><down><down><left>",
    " auto=true file=/mnt/cdrom2/preseed.cfg hostname=debian domain=local<f10>",
    "<wait15s>",
    # go to terminal tty2 for CLI
    # XXX: this Alt-F2 keystroke is coming out unrecognized
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
    # 'Load drives from removable media?' -> No
    "<right><enter><wait>",
    # 'Manually select a module and device for instation media?' -> Yes
    "<enter><wait>",
    # none, cdrom - press down and enter to select second option
    "<down><enter>",
  ]
  ssh_timeout  = "30m"
  ssh_username = "packer"
  ssh_password = "packer"
}

build {
  name = "debian-11"

  sources = ["source.tart-cli.debian-11"]

  # https://developer.hashicorp.com/packer/docs/provisioners/shell-local
  #
  provisioner "shell-local" {
    script = "./scripts/local-virtiofs.sh"
  }

  # https://developer.hashicorp.com/packer/docs/provisioners/shell
  #
  provisioner "shell" {
    scripts          = [
      "./scripts/version.sh",
      "./scripts/mount-apple-virtiofs.sh",
      "./scripts/collect_preseed.sh",
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.BuildName}}/{{.BuildName}}.{{.ChecksumType}}"
  }
}
