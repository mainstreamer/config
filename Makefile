## Simple Makefile for Linux and Mac builds
# Usage: make build linux|mac
#        make install linux|mac

# Define platform-specific commands
PACK_CMD_linux = \
	echo "Building linux bash config..." && \
	sed -i.bak '/^\#Built/s/.*/\#Built $(shell date)/' lx/bash/.bashrc && \
	cd lx/bash && \
	tar -cvzf ../../cfglx.tar.gz .bashrc .bashrc.d/ && \
	echo "Done! To install type: make install linux"

INSTALL_CMD_linux = \
	echo "Installing linux bash profile..." && \
	tar -xvzf `pwd`/cfglx.tar.gz -C ~/ && \
	echo "Loading new profile..." && \
	source ~/.bashrc

# NEEDS TO BE REWISED - NOT YET TESTED ON MAC
PACK_CMD_mac = \
	echo "Building mac zsh confg..." && \
	sed -i.bak '/^\#Built/s/.*/\#Built $(shell date)/' lx/bash/.bashrc && \
	cd ./mc/zsh && tar -cvzf ../../cfgmc.tar.gz .zshrc .zshrc.d/ && \
	cd ./../../ && \
	echo "Done! To install 'make i-mc' or type:" && \
	echo "tar -xvzf `pwd`/cfgmc.tar.gz"

INSTALL_CMD_mac = \
	echo "Installing mac bash profile..." && \
	tar -xvzf `pwd`/cfgmc.tar.gz -C ~/ && \
	echo "done"

FILENAME = $(shell date +%Y-%m-%d_%H-%M-%S)
# Default target shows help
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make pack linux    - Build for Linux"
	@echo "  make pack mac      - Build for Mac"
	@echo "  make install linux  - Install on Linux"
	@echo "  make install mac    - Install on Mac"

.PHONE: nvim
nvim:
	@mkdir -p ${HOME}/.config/nvim.bkp 
	@tar -cjvf ${HOME}/.config/nvim.bkp/arc_${FILENAME}.tar.bz2 -C ${HOME}/.config nvim
	@echo "backup saved ${HOME}/.config/nvim.bkp/arc_${FILENAME}.tar.bz2" 
	@rm -rf ${HOME}/.config/nvim
	@cp -r ./lx/nvim ${HOME}/.config
	@echo "nvim config updated"
	
# Handle "make build linux" or "make build mac"
.PHONY: pack
pack:
	@if [ "$(filter linux mac,$(word 2,$(MAKECMDGOALS)))" = "" ]; then \
		echo "Error: Platform not specified. Use 'make build linux' or 'make build mac'"; \
		exit 1; \
	fi

# Handle "make install linux" or "make install mac"
.PHONY: install
install:
	@if [ "$(filter linux mac,$(word 2,$(MAKECMDGOALS)))" = "" ]; then \
		echo "Error: Platform not specified. Use 'make install linux' or 'make install mac'"; \
		exit 1; \
	fi

# Empty targets for linux and mac to make the syntax work
.PHONY: linux mac
linux:
	@if [ "$(word 1,$(MAKECMDGOALS))" = "pack" ]; then \
		$(PACK_CMD_linux); \
	elif [ "$(word 1,$(MAKECMDGOALS))" = "install" ]; then \
		$(INSTALL_CMD_linux); \
	fi

mac:
	@if [ "$(word 1,$(MAKECMDGOALS))" = "pack" ]; then \
		$(PACK_CMD_mac); \
	elif [ "$(word 1,$(MAKECMDGOALS))" = "install" ]; then \
		$(INSTALL_CMD_mac); \
	fi

