# bandwidth-meter — weekly / monthly usage from Bandwidth+ daily history
#
#   make            build the menu bar app and CLI
#   make test       run the self-test suite
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
SWIFT       := swift

SHELL := /bin/bash

.PHONY: all app cli test install install-cli install-app uninstall clean help

all: app

## Build the menu bar app bundle and the CLI into dist/
app:
	$(SWIFT) build -c release
	@BIN_DIR="$$($(SWIFT) build -c release --show-bin-path)"; \
	rm -rf "$(APP_BUNDLE)"; \
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS" "$(APP_BUNDLE)/Contents/Resources" "$(DIST_DIR)"; \
	cp "$$BIN_DIR/$(APP_EXEC)" "$(APP_BUNDLE)/Contents/MacOS/$(APP_EXEC)"; \
	cp "$(INFO_PLIST)" "$(APP_BUNDLE)/Contents/Info.plist"; \
	printf 'APPL????' > "$(APP_BUNDLE)/Contents/PkgInfo"; \
	chmod +x "$(APP_BUNDLE)/Contents/MacOS/$(APP_EXEC)"; \
	codesign --force --sign - "$(APP_BUNDLE)" >/dev/null; \
	cp "$$BIN_DIR/$(CLI_NAME)" "$(DIST_DIR)/$(CLI_NAME)"; \
	chmod +x "$(DIST_DIR)/$(CLI_NAME)"
	@echo "built $(APP_BUNDLE)"
	@echo "built $(DIST_DIR)/$(CLI_NAME)"

cli: app

## Run the self-test suite
test:
	$(SWIFT) run MeterSelfTest

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
	@echo "  make install            install CLI (and the app, if built)"
	@echo "  make install-cli        CLI only, to ~/.local/bin"
	@echo "  make install-app        menu bar app only, to /Applications"
	@echo "  make uninstall          remove the CLI and the app"
	@echo "  make clean              delete build artefacts"
