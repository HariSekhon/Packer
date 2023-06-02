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

Packer-templates := HariSekhon/Packer-templates

CODE_FILES := $(shell git ls-files | grep -E -e '\.sh$$' -e '\.py$$' | sort)

.PHONY: build
build: init
	@echo ================
	@echo Packer Builds
	@echo ================
	@$(MAKE) git-summary
	@echo

.PHONY: init
init:
	@echo "running init:"
	git submodule update --init --recursive
	@echo

.PHONY: install
install: build
	@:

.PHONY: test
test:
	bash-tools/checks/check_all.sh

.PHONY: clean
clean:
	@rm -fv -- outputs-*
