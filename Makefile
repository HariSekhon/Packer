#
#  Author: Hari Sekhon
#  Date: 2016-01-17 12:56:53 +0000 (Sun, 17 Jan 2016)
#
#  vim:ts=4:sts=4:sw=4:noet
#
#  https://github.com/HariSekhon/Packer-templates
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

REPO := HariSekhon/Packer-templates

CODE_FILES := $(shell git ls-files | grep -E -e '\.sh$$' -e '\.py$$' | sort)

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
virtualbox: virtualbox
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
	@if uname -m | grep -q arm64; then \
		$(MAKE) debian-tart-http; \
	else \
		$(MAKE) debian-vbox; \
	fi

.PHONY: fedora
fedora:
	@if uname -m | grep -q arm64; then \
		$(MAKE) fedora-tart-http; \
	else \
		$(MAKE) fedora-vbox; \
	fi

.PHONY: rocky
rocky:
	@if uname -m | grep -q arm64; then \
		$(MAKE) rocky-tart-http; \
	else \
		$(MAKE) rocky-vbox; \
	fi

.PHONY: ubuntu
ubuntu:
	@if uname -m | grep -q arm64; then \
		$(MAKE) ubuntu-tart-http; \
	else \
		$(MAKE) ubuntu-vbox; \
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
	VBoxManage unregistervm debian --delete 2>/dev/null || :
	packer build --force debian-11-x86_64.vbox.pkr.hcl

.PHONY: fedora-vbox
fedora-vbox:
	VBoxManage unregistervm fedora --delete 2>/dev/null || :
	packer build --force fedora-38-x86_64.vbox.pkr.hcl

.PHONY: rocky-vbox
rocky-vbox:
	VBoxManage unregistervm rocky --delete 2>/dev/null || :
	packer build --force rocky-9.2-x86_64.vbox.pkr.hcl

.PHONY: ubuntu-vbox
ubuntu-vbox:
	VBoxManage unregistervm ubuntu --delete 2>/dev/null || :
	packer build --force ubuntu-22.04-x86_64.vbox.pkr.hcl

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
	packer build --force debian-11-arm64.tart.pkr.hcl

.PHONY: fedora-tart
fedora-tart:
	scripts/prepare_fedora-38.sh
	packer build --force fedora-38-arm64.tart.pkr.hcl

.PHONY: rocky-tart
rocky-tart:
	scripts/prepare_rocky-9.2.sh
	packer build --force rocky-9.2-arm64.tart.pkr.hcl

.PHONY: ubuntu-tart
ubuntu-tart:
	scripts/prepare_ubuntu-22.04.sh
	packer build --force ubuntu-22.04-arm64.tart.pkr.hcl

.PHONY: ubuntu-tart
ubuntu-23-tart:
	scripts/prepare_ubuntu-23.04.sh
	packer build --force ubuntu-23.04-arm64.tart.pkr.hcl

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
	packer build --force debian-11-arm64.tart.http.pkr.hcl
	$(MAKE) kill-webserver

.PHONY: fedora-tart-http
fedora-tart-http:
	scripts/prepare_fedora-38.sh
	$(MAKE) webserver
	packer build --force fedora-38-arm64.tart.http.pkr.hcl
	$(MAKE) kill-webserver

.PHONY: rocky-tart-http
rocky-tart-http:
	scripts/prepare_rocky-9.2.sh
	$(MAKE) webserver
	packer build --force rocky-9.2-arm64.tart.http.pkr.hcl
	$(MAKE) kill-webserver

.PHONY: ubuntu-tart-http
ubuntu-tart-http:
	scripts/prepare_ubuntu-22.04.sh
	$(MAKE) webserver
	packer build --force ubuntu-22.04-arm64.tart.http.pkr.hcl
	$(MAKE) kill-webserver

.PHONY: validate
validate:
	for x in *.hcl; do \
		packer init "$$x" && \
		packer validate "$$x" && \
		packer fmt -diff "$$x" || \
		exit 1; \
	done

# if you really want to check it locally before pushing - otherwise just let the CI/CD workflows run and check the README badge statuses
.PHONY: lint
lint:
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
