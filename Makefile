#
#  Author: Hari Sekhon
#  Date: 2016-01-17 12:56:53 +0000 (Sun, 17 Jan 2016)
#
#  vim:ts=4:sts=4:sw=4:noet
#
#  https://github.com/HariSekhon/Packer
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

# ===================
# bootstrap commands:

# setup/bootstrap.sh

# ===================

ifneq ("$(wildcard bash-tools/Makefile.in)", "")
	include bash-tools/Makefile.in
endif

REPO := HariSekhon/Packer

CODE_FILES := $(shell git ls-files | grep -E -e '\.sh$$' -e '\.py$$' | sort)

ARCH := $(shell uname -m)
UBUNTU_ISO_ARCH := $(shell if [ "$(ARCH)" = x86_64 ]; then echo amd64; else echo "$(ARCH)"; fi)

#VIRTUALBOX := $(shell type -P VirtualBox)

USE_VBOX := $(shell if [ "$(ARCH)" = x86_64 ] && type -P VirtualBox >/dev/null 2>&1; then echo 1; else echo 0; fi)

.PHONY: build
build: init
	@echo ================
	@echo Packer Builds
	@echo ================
	@#$(MAKE) git-summary
	@echo
	$(MAKE) all

.PHONY: init
init:
	@echo "running init:"
	git submodule update --init --recursive
	@echo

.PHONY: install
install: packer
	@:

.PHONY: packer
packer:
	brew install packer

.PHONY: virtualbox
virtualbox:
	brew install virtualbox

.PHONY: vbox
vbox: virtualbox
	@:

.PHONY: qemu
qemu:
	brew install qemu

.PHONY: tart
tart:
	brew install cirruslabs/cli/tart

.PHONY: all
all:
	$(MAKE) debian
	@echo
	$(MAKE) ubuntu
	@echo
	$(MAKE) fedora
	@echo
	$(MAKE) rocky

.PHONY: debian
debian:
	@if [ "$(USE_VBOX)" = 1 ]; then \
		$(MAKE) debian-vbox; \
	else \
		$(MAKE) debian-qemu; \
	fi

.PHONY: debian-11
debian-11:
	@if [ "$(USE_VBOX)" = 1 ]; then \
		$(MAKE) debian-11-vbox; \
	else \
		$(MAKE) debian-11-qemu; \
	fi

.PHONY: fedora
fedora:
	@if [ "$(USE_VBOX)" = 1 ]; then \
		$(MAKE) fedora-vbox; \
	else \
		$(MAKE) fedora-qemu; \
	fi

.PHONY: fedora-38
fedora-38:
	@if [ "$(USE_VBOX)" = 1 ]; then \
		$(MAKE) fedora-38-vbox; \
	else \
		$(MAKE) fedora-38-qemu; \
	fi

.PHONY: fedora-37
fedora-37:
	@if [ "$(USE_VBOX)" = 1 ]; then \
		$(MAKE) fedora-37-vbox; \
	else \
		$(MAKE) fedora-37-qemu; \
	fi

.PHONY: rocky
rocky:
	@if [ "$(USE_VBOX)" = 1 ]; then \
		$(MAKE) rocky-vbox; \
	else \
		$(MAKE) rocky-qemu; \
	fi

.PHONY: rocky-9.2
rocky-9.2:
	@if [ "$(USE_VBOX)" = 1 ]; then \
		$(MAKE) rocky-9.2-vbox; \
	else \
		$(MAKE) rocky-9.2-qemu; \
	fi

.PHONY: ubuntu
ubuntu:
	@if [ "$(USE_VBOX)" = 1 ]; then \
		$(MAKE) ubuntu-vbox; \
	else \
		$(MAKE) ubuntu-qemu; \
	fi

.PHONY: ubuntu-22.04
ubuntu-22.04:
	@if [ "$(USE_VBOX)" = 1 ]; then \
		$(MAKE) ubuntu-22.04-vbox; \
	else \
		$(MAKE) ubuntu-22.04-qemu; \
	fi

.PHONY: all-vbox
all-vbox:
	$(MAKE) debian-vbox
	@echo
	$(MAKE) ubuntu-vbox
	@echo
	$(MAKE) fedora-vbox
	@echo
	$(MAKE) rocky-vbox

.PHONY: debian-vbox
debian-vbox:
	VBoxManage unregistervm debian-11 --delete 2>/dev/null || :
	packer build --force debian-x86_64.vbox.pkr.hcl

.PHONY: debian-11-vbox
debian-11-vbox:
	VBoxManage unregistervm debian-11 --delete 2>/dev/null || :
	packer build --force \
		-var version=11 \
		-var iso=debian-11.7.0-amd64-DVD-1.iso \
		-var checksum=cfbb1387d92c83f49420eca06e2d11a23e5a817a21a5d614339749634709a32f \
		debian-x86_64.vbox.pkr.hcl

.PHONY: debian-12-vbox
debian-12-vbox:
	VBoxManage unregistervm debian-11 --delete 2>/dev/null || :
	packer build --force \
		-var version=11 \
		-var iso=debian-12.0.0-amd64-DVD-1.iso \
		-var checksum=ca3df1d40c4488825b489d2bf32deb58c27e28020cc070699159cf010febf0bd \
		debian-x86_64.vbox.pkr.hcl

.PHONY: fedora-vbox
fedora-vbox:
	VBoxManage unregistervm fedora-38 --delete 2>/dev/null || :
	packer build --force fedora-x86_64.vbox.pkr.hcl

.PHONY: fedora-37-vbox
fedora-37-vbox:
	VBoxManage unregistervm fedora-37 --delete 2>/dev/null || :
	packer build --force \
		-var version=37 \
		-var iso=Fedora-Server-dvd-x86_64-37-1.7.iso \
		fedora-x86_64.vbox.pkr.hcl

.PHONY: fedora-38-vbox
fedora-38-vbox:
	VBoxManage unregistervm fedora-38 --delete 2>/dev/null || :
	packer build --force \
		-var version=38 \
		-var iso=Fedora-Server-dvd-x86_64-38-1.6.iso \
		fedora-x86_64.vbox.pkr.hcl

.PHONY: rocky-vbox
rocky-vbox:
	VBoxManage unregistervm rocky-9.2 --delete 2>/dev/null || :
	packer build --force rocky-x86_64.vbox.pkr.hcl

.PHONY: rocky-9-vbox
rocky-9-vbox: rocky-9.2-vbox
	@:

.PHONY: rocky-9.2-vbox
rocky-9.2-vbox:
	VBoxManage unregistervm rocky-9.2 --delete 2>/dev/null || :
	packer build --force \
		-var version="9.2" \
		-var iso="Rocky-9.2-x86_64-dvd.iso" \
		rocky-x86_64.vbox.pkr.hcl

.PHONY: ubuntu-vbox
ubuntu-vbox:
	VBoxManage unregistervm ubuntu-22.04 --delete 2>/dev/null || :
	packer build --force ubuntu-x86_64.vbox.pkr.hcl

.PHONY: ubuntu-22.04-vbox
ubuntu-22.04-vbox:
	VBoxManage unregistervm ubuntu-22.04 --delete 2>/dev/null || :
	packer build --force \
		-var version="22.04" \
		-var iso="ubuntu-22.04.2-live-server-arm64.iso" \
		ubuntu-x86_64.vbox.pkr.hcl

.PHONY: qemu-all
qemu-all:
	$(MAKE) debian-qemu
	@echo
	$(MAKE) ubuntu-qemu
	@echo
	$(MAKE) fedora-qemu
	@echo
	$(MAKE) rocky-qemu

.PHONY: debian-qemu
debian-qemu:
	packer build --force debian-$(ARCH).qemu.pkr.hcl

.PHONY: fedora-qemu
fedora-qemu:
	packer build --force fedora-$(ARCH).qemu.pkr.hcl

.PHONY: fedora-38-qemu
fedora-37-qemu:
	packer build --force \
		-var version=38 \
		-var iso=Fedora-Server-dvd-x86_64-37-1.6.iso \
		fedora-$(ARCH).qemu.pkr.hcl

.PHONY: fedora-38-qemu
fedora-38-qemu:
	packer build --force \
		-var version=38 \
		-var iso=Fedora-Server-dvd-x86_64-38-1.6.iso \
		fedora-$(ARCH).qemu.pkr.hcl

.PHONY: rocky-qemu
rocky-qemu:
	packer build --force rocky-$(ARCH).qemu.pkr.hcl

.PHONY: rocky-9.2-qemu
rocky-9.2-qemu:
	packer build --force \
		-var version="9.2" \
		-var iso="Rocky-9.2-aarch64-dvd.iso" \
		rocky-$(ARCH).qemu.pkr.hcl

.PHONY: ubuntu-qemu
ubuntu-qemu:
	packer build --force ubuntu-$(ARCH).qemu.pkr.hcl

.PHONY: ubuntu-22-qemu
ubuntu-22-qemu:
	packer build --force \
		-var version=22.04 \
		-var iso=ubuntu-22.04.2-live-server-$(UBUNTU_ISO_ARCH).iso \
		ubuntu-$(ARCH).qemu.pkr.hcl

.PHONY: ubuntu-23-qemu
ubuntu-23-qemu:
	packer build --force \
		-var version=23.04 \
		-var iso=ubuntu-23.04-live-server-$(UBUNTU_ISO_ARCH).iso \
		ubuntu-$(ARCH).qemu.pkr.hcl

.PHONY: all
tart-all:
	$(MAKE) debian-tart
	@echo
	$(MAKE) ubuntu-tart
	@echo
	$(MAKE) fedora-tart
	@echo
	$(MAKE) rocky-tart

.PHONY: debian-tart
debian-tart:
	scripts/prepare_debian-11.sh
	packer build --force debian-arm64.tart.pkr.hcl

.PHONY: fedora-tart
fedora-tart:
	scripts/prepare_fedora-38.sh
	packer build --force fedora-arm64.tart.pkr.hcl

.PHONY: fedora-38-tart
fedora-37-tart:
	scripts/prepare_fedora-37.sh
	packer build --force \
		-var version=38 \
		-var iso=Fedora-Server-dvd-x86_64-37-1.6.iso \
		fedora-arm64.tart.pkr.hcl

.PHONY: fedora-38-tart
fedora-38-tart:
	scripts/prepare_fedora-38.sh
	packer build --force \
		-var version=38 \
		-var iso=Fedora-Server-dvd-x86_64-38-1.6.iso \
		fedora-arm64.tart.pkr.hcl

.PHONY: rocky-tart
rocky-tart:
	scripts/prepare_rocky-9.2.sh
	packer build --force rocky-arm64.tart.pkr.hcl

.PHONY: rocky-9.2-tart
rocky-9.2-tart:
	scripts/prepare_rocky-9.2.sh
	packer build --force \
		-var version="9.2" \
		-var iso="Rocky-9.2-aarch64-dvd.iso" \
		rocky-arm64.tart.pkr.hcl

.PHONY: ubuntu-tart
ubuntu-tart:
	scripts/prepare_ubuntu-22.04.sh
	packer build --force ubuntu-arm64.tart.pkr.hcl

.PHONY: ubuntu-22-tart
ubuntu-22-tart:
	scripts/prepare_ubuntu-22.04.sh
	packer build --force \
		-var version=22.04 \
		-var iso=ubuntu-22.04.2-live-server-arm64.iso \
		ubuntu-arm64.tart.pkr.hcl

.PHONY: ubuntu-23-tart
ubuntu-23-tart:
	scripts/prepare_ubuntu-23.04.sh
	packer build --force \
		-var version=23.04 \
		-var iso=ubuntu-23.04-live-server-arm64.iso \
		ubuntu-arm64.tart.pkr.hcl

.PHONY: kill-webserver
kill-webserver:
	pkill -9 -if -- '.*python.* -m http.server -d installer[s]' || :

.PHONY: webserver
webserver:
	$(MAKE) kill-webserver
	python3 -m http.server -d installers &

.PHONY: debian-tart-http
debian-tart-http:
	scripts/prepare_debian-11.sh
	$(MAKE) webserver
	packer build --force debian-arm64.tart.http.pkr.hcl
	$(MAKE) kill-webserver

.PHONY: fedora-tart-http
fedora-tart-http:
	scripts/prepare_fedora-38.sh
	$(MAKE) webserver
	packer build --force fedora-arm64.tart.http.pkr.hcl
	$(MAKE) kill-webserver

.PHONY: rocky-tart-http
rocky-tart-http:
	scripts/prepare_rocky-9.2.sh
	$(MAKE) webserver
	packer build --force rocky-arm64.tart.http.pkr.hcl
	$(MAKE) kill-webserver

.PHONY: rocky-9.2-tart-http
rocky-9.2-tart-http:
	scripts/prepare_rocky-9.2.sh
	$(MAKE) webserver
	packer build --force \
		-var version="9.2" \
		-var iso="Rocky-9.2-aarch64-dvd.iso" \
		rocky-arm64.tart.http.pkr.hcl
	$(MAKE) kill-webserver

.PHONY: ubuntu-tart-http
ubuntu-tart-http:
	scripts/prepare_ubuntu-22.04.sh
	$(MAKE) webserver
	packer build --force ubuntu-arm64.tart.http.pkr.hcl
	$(MAKE) kill-webserver

.PHONY: ubuntu-22-tart-http
ubuntu-22-tart-http:
	scripts/prepare_ubuntu-22.04.sh
	$(MAKE) webserver
	packer build --force \
		-var version=22.04 \
		-var iso=isos/ubuntu-22.04.2-live-server-arm64.iso \
		ubuntu-arm64.tart.http.pkr.hcl
	$(MAKE) kill-webserver

.PHONY: ubuntu-23-tart-http
ubuntu-23-tart-http:
	scripts/prepare_ubuntu-22.04.sh
	$(MAKE) webserver
	packer build --force \
		-var version=23.04 \
		-var iso=isos/ubuntu-23.04-live-server-arm64.iso \
		ubuntu-arm64.tart.http.pkr.hcl
	$(MAKE) kill-webserver

.PHONY: lint
lint:
	for x in *.hcl; do \
		if [ "$(ARCH)" = x86_64 ]; then \
			if [[ "$$x" =~ arm64 ]]; then \
				continue; \
			fi; \
		elif [ "$(ARCH)" = arm64 ]; then \
			if [[ "$$x" =~ x86_64 ]]; then \
				continue; \
			fi; \
		fi; \
		echo "Lint: $$x"; \
		packer init "$$x" && \
		packer fmt -diff "$$x" || \
		exit 1; \
	done
		# complains if output dir already exists
		#packer validate "$$x" && \

# if you really want to check it locally before pushing - otherwise just let the CI/CD workflows run and check the README badge statuses
.PHONY: lint-installers
lint-installers:
	$(MAKE) autoinstall-lint
	@echo
	$(MAKE) kickstart-lint
	@echo
	$(MAKE) preseed-lint
	@echo
	@echo "Linting passed"

.PHONY: autoinstall-lint
autoinstall-lint:
	docker run -ti -v "$$PWD:/pwd" -w /pwd -e DEBIAN_FRONTEND=noninteractive ubuntu:latest bash -c 'apt-get update && apt-get install cloud-init -y && echo && cloud-init schema --config-file installers/autoinstall-user-data'

.PHONY: kickstart-lint
kickstart-lint:
	docker run -ti -v "$$PWD:/pwd" -w /pwd fedora:latest bash -c 'dnf install pykickstart -y && ksvalidator installers/anaconda-ks.cfg'

.PHONY: preseed-lint
preseed-lint:
	docker run -ti -v "$$PWD:/pwd" -w /pwd -e DEBIAN_FRONTEND=noninteractive debian:latest bash -c 'apt-get update && apt-get install debconf -y && echo && debconf-set-selections -c installers/preseed.cfg'

.PHONY: prepare
prepare:
	for script in scripts/prepare-*.sh; do $$script; done

.PHONY: test
test:
	bash-tools/checks/check_all.sh

.PHONY: clean
clean:
	@rm -frv -- output-* *.checksum

.PHONY: wc
wc:
	ls *.pkr.hcl installers/* scripts/* | grep -v README | xargs wc -l
