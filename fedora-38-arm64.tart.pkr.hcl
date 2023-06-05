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

# Requires macOS Ventura 13.4
#
# Must run 'scripts/prepare-fedora-38.sh' first to download the ISO and generate another ISO with the anaconda-ks.cfg
#
# 'packer' command must be run from the same directory as this file so the ISO files are found under iso/

# ============================================================================ #
#                  P a c k e r   -   F e d o r a   -   T a r t
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
source "tart-cli" "fedora-38" {
  vm_name = "fedora-38"
  # https://alt.fedoraproject.org/alt/
  from_iso = [
    "isos/fedora-38_cidata.iso",
    "isos/Fedora-Server-dvd-aarch64-38-1.6.iso"
  ]
  cpu_count    = 4
  memory_gb    = 4
  disk_size_gb = 40
  # need to mount /cdrom but device not found
  boot_command = [
    "<wait3s><up><wait>",
    "e",
    "<down><down><down><left>",
    # leave a space from last arg
    " inst.ks=file:///cdrom/anaconda-ks.cfg <f10>"
  ]
  ssh_timeout  = "30m"
  ssh_username = "packer"
  ssh_password = "packer"
}

build {
  name = "fedora-38"

  sources = ["source.tart-cli.fedora-38"]

  # https://developer.hashicorp.com/packer/docs/provisioners/shell-local
  #
  provisioner "shell-local" {
    script = "./scripts/local-virtiofs.sh"
  }

  # https://developer.hashicorp.com/packer/docs/provisioners/shell
  #
  provisioner "shell" {
    scripts = [
      "./scripts/version.sh",
      "./scripts/mount-apple-virtiofs.sh",
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  # https://developer.hashicorp.com/packer/docs/provisioners/shell
  #
  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}'"
    inline = [
      "for x in anaconda-ks.cfg ks-pre.log ks-post.log; do if [ -f /root/$x ]; then cp -fv /root/$x /mnt/virtiofs/; fi; done"
    ]
  }

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.BuildName}}/{{.BuildName}}.{{.ChecksumType}}"
  }
}
