# bandwidth-meter — weekly / monthly usage from Bandwidth+ daily history
#
#   make            build the menu bar app and CLI
#   make test       run the self-test suite
#   make shots      render the README screenshots into docs/screenshots
#   make dmg        build the release disk image (installer pkg + uninstaller)
#   make dist       same as make dmg; what the release workflow runs
#   make install    install the CLI to ~/.local/bin (and the app, if built)
#   make uninstall  remove the CLI and the app

APP_NAME    := Bandwidth Meter
APP_EXEC    := BandwidthMeter
CLI_NAME    := bandwidth-meter
DIST_DIR    := dist
APP_BUNDLE  := $(DIST_DIR)/$(APP_NAME).app
APP_DEST    := /Applications/$(APP_NAME).app
CLI_DEST    := $(HOME)/.local/bin/$(CLI_NAME)
INFO_PLIST  := Resources/Info.plist
SHOTS_DIR   := docs/screenshots
SWIFT       := swift
VERSION     := $(shell /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' $(INFO_PLIST))
DMG         := $(DIST_DIR)/Bandwidth-Meter-$(VERSION).dmg

SHELL := /bin/bash

.PHONY: all app cli test shots dmg dist dmg-background install install-cli install-app uninstall clean help

all: app

## Build the menu bar app bundle and the CLI into dist/
app:
	$(SWIFT) build -c release
	@BIN_DIR="$$($(SWIFT) build -c release --show-bin-path)"; \
	rm -rf "$(APP_BUNDLE)"; \
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS" "$(APP_BUNDLE)/Contents/Helpers" "$(APP_BUNDLE)/Contents/Resources" "$(DIST_DIR)"; \
	cp "$$BIN_DIR/$(APP_EXEC)" "$(APP_BUNDLE)/Contents/MacOS/$(APP_EXEC)"; \
	cp "$(INFO_PLIST)" "$(APP_BUNDLE)/Contents/Info.plist"; \
	printf 'APPL????' > "$(APP_BUNDLE)/Contents/PkgInfo"; \
	chmod +x "$(APP_BUNDLE)/Contents/MacOS/$(APP_EXEC)"; \
	cp "$$BIN_DIR/$(CLI_NAME)" "$(DIST_DIR)/$(CLI_NAME)"; \
	chmod +x "$(DIST_DIR)/$(CLI_NAME)"; \
	codesign --force --sign - "$(DIST_DIR)/$(CLI_NAME)" >/dev/null; \
	cp "$(DIST_DIR)/$(CLI_NAME)" "$(APP_BUNDLE)/Contents/Helpers/$(CLI_NAME)"; \
	codesign --force --sign - "$(APP_BUNDLE)" >/dev/null
	@echo "built $(APP_BUNDLE)"
	@echo "built $(DIST_DIR)/$(CLI_NAME)"

cli: app

## Build the release disk image: an installer pkg and an uninstaller
dmg: app
	@scripts/build-dmg.sh

## The release workflow and CI run this
dist: dmg

## Redraw packaging/dmg/background*.png after changing the layout
dmg-background:
	$(SWIFT) packaging/dmg/render-background.swift packaging/dmg

## Run the self-test suite
test:
	$(SWIFT) run MeterSelfTest

## Render the README screenshots from the real views and demo data
shots:
	@mkdir -p "$(SHOTS_DIR)"
	SHOTS_DIR="$(SHOTS_DIR)" $(SWIFT) run MeterShots -AppleLocale en_GB -AppleShowScrollBars WhenScrolling

## Install the CLI into ~/.local/bin
install-cli:
	@if [ ! -f "$(DIST_DIR)/$(CLI_NAME)" ]; then $(MAKE) app; fi
	@mkdir -p "$(HOME)/.local/bin"
	@cp "$(DIST_DIR)/$(CLI_NAME)" "$(CLI_DEST)"
	@chmod +x "$(CLI_DEST)"
	@echo "installed $(CLI_DEST)"

## Install the menu bar app into /Applications
install-app:
	@if [ ! -d "$(APP_BUNDLE)" ]; then $(MAKE) app; fi
	@pkill -x "$(APP_EXEC)" 2>/dev/null || true
	@rm -rf "$(APP_DEST)"
	@cp -R "$(APP_BUNDLE)" "$(APP_DEST)"
	@echo "installed $(APP_DEST)"
	@echo "open it with: open \"$(APP_DEST)\""

## Install the CLI, and the app if it has been built
install: install-cli
	@if [ -d "$(APP_BUNDLE)" ]; then \
	    $(MAKE) install-app; \
	else \
	    echo ""; \
	    echo "Menu bar app not built. Build and install it with:"; \
	    echo "    make app && make install-app"; \
	fi

## Remove the CLI and the app
uninstall:
	@rm -f "$(CLI_DEST)"
	@pkill -x "$(APP_EXEC)" 2>/dev/null || true
	@rm -rf "$(APP_DEST)"
	@echo "removed $(CLI_DEST)"
	@echo "removed $(APP_DEST)"

## Delete build artefacts
clean:
	@rm -rf .build "$(DIST_DIR)"
	@echo "cleaned"

## Show this help
help:
	@echo "bandwidth-meter — make targets"
	@echo ""
	@echo "  make                    build the menu bar app and CLI"
	@echo "  make test               run the self-test suite"
	@echo "  make shots              render README screenshots into docs/screenshots"
	@echo "  make dmg                release disk image: installer pkg + uninstaller"
	@echo "  make dist               same as make dmg (used by the release workflow)"
	@echo "  make dmg-background     redraw the disk image background"
	@echo "  make install            install CLI (and the app, if built)"
	@echo "  make install-cli        CLI only, to ~/.local/bin"
	@echo "  make install-app        menu bar app only, to /Applications"
	@echo "  make uninstall          remove the CLI and the app"
	@echo "  make clean              delete build artefacts"
