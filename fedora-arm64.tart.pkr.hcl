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
# Must run 'scripts/fedora-prepare.sh' first to download the ISO and generate another ISO with the anaconda-ks.cfg
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
source "tart-cli" "fedora" {
  vm_name = "fedora"
  # https://alt.fedoraproject.org/alt/
  from_iso     = ["isos/cidata.iso", "iso/Fedora-Server-dvd-x86_64-38-1.6.iso"]
  cpu_count    = 3
  memory_gb    = 3
  disk_size_gb = 40
  boot_wait    = "5s"
  boot_command = [
    # grub
    "<wait5s><enter>",
    # autoinstall prompt
    "<wait30s>yes<enter>"
  ]
  ssh_timeout  = "30m"
  ssh_username = "packer"
  ssh_password = "packer"
}


build {
  name = "fedora"

  sources = ["source.tart-cli.fedora"]

  # https://developer.hashicorp.com/packer/docs/provisioners/shell-local
  #
  provisioner "shell-local" {
    script = "./scripts/local.sh"
  }

  # https://developer.hashicorp.com/packer/docs/provisioners/shell
  #
  provisioner "shell" {
    scripts = [
      "./scripts/version.sh",
      "./scripts/vboxsf.sh",
    ]
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}' '${packer.version}'"
  }

  # https://developer.hashicorp.com/packer/docs/provisioners/shell
  #
  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}'"
    inline = [
      "for x in anaconda-ks.cfg ks-pre.log ks-post.log; do if [ -f /root/$x ]; then cp -fv /root/$x /mnt/vboxsf/; fi; done"
    ]
  }

  post-processor "checksum" {
    checksum_types      = ["md5", "sha512"]
    keep_input_artifact = true
    output              = "output-{{.Name}}/{{.Name}}.{{.ChecksumType}}"
  }
}
