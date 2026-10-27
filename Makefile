# Makefile - task runner for the uictl SwiftPM package.
# Modular targets live in tasks/Makefile.<namespace>.

-include tasks/Makefile.*

# Build configuration: release (default) or debug.
CONFIG ?= release
# Installation prefix; the binary is symlinked into $(PREFIX)/bin.
PREFIX ?= /usr/local
BINARY ?= uictl

.DEFAULT_GOAL := help

.PHONY: all deps build build/debug test install uninstall clean help

## Resolve dependencies and build
all: deps build

## Resolve Swift package dependencies
deps:
	@command -v swift >/dev/null || { echo "swift toolchain not found; install the Xcode command-line tools" >&2; exit 1; }
	swift package resolve

## Build the uictl binary (CONFIG=release|debug)
build: deps buildinfo
	swift build -c $(CONFIG)
	@echo "Built: $(CURDIR)/.build/$(CONFIG)/$(BINARY)"
	@echo "Run it:  $(CURDIR)/.build/$(CONFIG)/$(BINARY) --help"
	@echo "Or put it on your PATH:  make install"

## Build the faster debug binary
build/debug: CONFIG := debug
build/debug: build

## Run the unit tests (swift test)
test: deps buildinfo
	swift test

## Symlink the built binary into PREFIX/bin and stop any stale daemon
install: build daemon/stop
	ln -sf "$(CURDIR)/.build/$(CONFIG)/$(BINARY)" "$(PREFIX)/bin/$(BINARY)"
	@echo "Installed: $(PREFIX)/bin/$(BINARY) -> $(CURDIR)/.build/$(CONFIG)/$(BINARY)"
	@echo "Run it:  $(BINARY) --help"

## Remove the installed symlink
uninstall:
	rm -f "$(PREFIX)/bin/$(BINARY)"

## Remove build artifacts and the generated SBOM
clean:
	swift package clean
	rm -rf "$(SBOM_DIR)"

## This help screen
help:
	@printf "Available targets:\n\n"
	@awk '/^[a-zA-Z\-_0-9%:\\\/]+/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = $$1; \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			gsub("\\\\", "", helpCommand); \
			gsub(":+$$", "", helpCommand); \
			printf "  \x1b[32;01m%-35s\x1b[0m %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -u
	@printf "\n"
