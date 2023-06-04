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
	$(MAKE) packer

.PHONY: init
init:
	@echo "running init:"
	git submodule update --init --recursive
	@echo

.PHONY: packer
packer:
	$(MAKE) debian
	@echo
	$(MAKE) ubuntu
	@echo
	$(MAKE) fedora

.PHONY: debian
debian:
	VBoxManage unregistervm debian --delete 2>/dev/null || :
	packer build --force debian-11-x86_64.vbox.pkr.hcl

.PHONY: fedora
fedora:
	VBoxManage unregistervm fedora --delete 2>/dev/null || :
	packer build --force fedora-38-x86_64.vbox.pkr.hcl

.PHONY: ubuntu
ubuntu:
	VBoxManage unregistervm ubuntu --delete 2>/dev/null || :
	packer build --force ubuntu-22.04-x86_64.vbox.pkr.hcl

.PHONY: debian-tart
debian-tart:
	packer build --force debian-11-arm64.tart.pkr.hcl

.PHONY: fedora-tart
fedora-tart:
	packer build --force fedora-38-arm64.tart.pkr.hcl

.PHONY: ubuntu-tart
ubuntu-tart:
	packer build --force ubuntu-22.04-arm64.tart.pkr.hcl

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
