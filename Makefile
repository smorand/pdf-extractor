.PHONY: build build-all install install-launcher uninstall clean clean-all rebuild rebuild-all test test-unit test-functional test-all fmt vet lint check run info help list-commands init-mod init-deps docker docker-build docker-push

# Detect current platform
GOOS=$(shell go env GOOS)
GOARCH=$(shell go env GOARCH)
CURRENT_PLATFORM=$(GOOS)-$(GOARCH)

# Docker configuration
PROJECT_NAME := $(shell basename $(CURDIR))
MAKE_DOCKER_PREFIX ?=
DOCKER_TAG ?= latest

# Detect optional directories for Docker build
HAS_INTERNAL := $(shell test -d internal && echo "yes" || echo "no")
HAS_DATA := $(shell test -d data && echo "yes" || echo "no")

# Detect install directory based on user privileges (root vs non-root)
IS_ROOT=$(shell [ $$(id -u) -eq 0 ] && echo "yes" || echo "no")
ifeq ($(IS_ROOT),yes)
	DEFAULT_INSTALL_DIR=/usr/local/bin
	DEFAULT_LIB_DIR=/usr/local/lib
	SUDO_CMD=
else
	DEFAULT_INSTALL_DIR=$(HOME)/.local/bin
	DEFAULT_LIB_DIR=$(HOME)/.local/lib
	SUDO_CMD=
endif

# Detect all commands in cmd/ directory
COMMANDS=$(shell find cmd -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

# Default binary name (first command in cmd/ directory)
FIRST_CMD=$(shell ls cmd 2>/dev/null | head -1)
DEFAULT_BINARY_NAME=$(if $(FIRST_CMD),$(FIRST_CMD),$(shell basename $$(pwd)))

# Module name - override this if your module path differs from binary name
# Example: MODULE_NAME=github.com/myorg/myproject
MODULE_NAME ?= $(DEFAULT_BINARY_NAME)

# Find all Go source files for rebuild detection
GO_SOURCES=$(shell find . -name '*.go' -type f 2>/dev/null | grep -v '_test.go')

# Detect if functional tests exist
HAS_FUNCTIONAL_TESTS=$(shell [ -f tests/run_tests.sh ] && echo "yes" || echo "no")

# Build configuration
BUILD_DIR=bin
GO_MOD_PATH=go.mod
GO_SUM_PATH=go.sum

# Build for current platform only
build:
	@echo "Building all commands for current platform ($(CURRENT_PLATFORM))..."
	@$(foreach cmd,$(COMMANDS),$(MAKE) build-cmd-current CMD=$(cmd);)

# Build for all platforms and create launcher scripts
build-all:
	@echo "Building all commands for all platforms..."
	@$(foreach cmd,$(COMMANDS),$(MAKE) build-cmd-all CMD=$(cmd);)

rebuild: clean-all build

rebuild-all: clean-all build-all

# Helper target: Build single command for current platform (multi-command layout)
build-cmd-current: $(GO_SUM_PATH) $(GO_SOURCES)
	@echo "Building $(CMD) for $(CURRENT_PLATFORM)..."
	@mkdir -p $(BUILD_DIR)
	@GOOS=$(GOOS) GOARCH=$(GOARCH) go build -o $(BUILD_DIR)/$(CMD)-$(CURRENT_PLATFORM) ./cmd/$(CMD)
ifeq ($(GOOS),darwin)
	@echo "Signing binary for macOS..."
	@codesign -f -s - $(BUILD_DIR)/$(CMD)-$(CURRENT_PLATFORM)
endif
	@echo "✓ Built: $(BUILD_DIR)/$(CMD)-$(CURRENT_PLATFORM)"

# Helper target: Build single command for all platforms (multi-command layout)
build-cmd-all: $(GO_SUM_PATH) $(GO_SOURCES)
	@echo "Building $(CMD) for all platforms..."
	@mkdir -p $(BUILD_DIR)
	@GOOS=linux GOARCH=amd64 go build -o $(BUILD_DIR)/$(CMD)-linux-amd64 ./cmd/$(CMD)
	@echo "✓ Built: $(BUILD_DIR)/$(CMD)-linux-amd64"
	@GOOS=darwin GOARCH=amd64 go build -o $(BUILD_DIR)/$(CMD)-darwin-amd64 ./cmd/$(CMD)
ifeq ($(GOOS),darwin)
	@codesign -f -s - $(BUILD_DIR)/$(CMD)-darwin-amd64
endif
	@echo "✓ Built: $(BUILD_DIR)/$(CMD)-darwin-amd64"
	@GOOS=darwin GOARCH=arm64 go build -o $(BUILD_DIR)/$(CMD)-darwin-arm64 ./cmd/$(CMD)
ifeq ($(GOOS),darwin)
	@codesign -f -s - $(BUILD_DIR)/$(CMD)-darwin-arm64
endif
	@echo "✓ Built: $(BUILD_DIR)/$(CMD)-darwin-arm64"
	@GOOS=windows GOARCH=amd64 go build -o $(BUILD_DIR)/$(CMD)-windows-amd64.exe ./cmd/$(CMD)
	@echo "✓ Built: $(BUILD_DIR)/$(CMD)-windows-amd64.exe"
	@$(MAKE) create-launcher BINARY_NAME=$(CMD)

# Create launcher script for a specific binary
create-launcher:
	@echo "Creating launcher script for $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	@echo '#!/bin/bash' > $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '# Auto-generated launcher script for $(BINARY_NAME)' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '# Detects platform and executes the correct binary' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '# Get the directory where this script is located' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo 'SCRIPT_DIR="$$(cd "$$(dirname "$${BASH_SOURCE[0]}")" && pwd)"' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '# Detect OS' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo 'OS=$$(uname -s | tr "[:upper:]" "[:lower:]")' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '# Detect architecture' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo 'ARCH=$$(uname -m)' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '# Map architecture names to Go convention' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo 'case "$$ARCH" in' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '    x86_64)' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '        ARCH="amd64"' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '        ;;' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '    aarch64)' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '        ARCH="arm64"' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '        ;;' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '    arm64)' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '        ARCH="arm64"' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '        ;;' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '    *)' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '        echo "Unsupported architecture: $$ARCH" >&2' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '        exit 1' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '        ;;' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo 'esac' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '# Construct binary name' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo 'BINARY="$$SCRIPT_DIR/$(BINARY_NAME)-$$OS-$$ARCH"' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '# Check if binary exists' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo 'if [ ! -f "$$BINARY" ]; then' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '    echo "Error: Binary not found for platform $$OS-$$ARCH" >&2' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '    echo "Expected: $$BINARY" >&2' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '    echo "" >&2' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '    echo "Available binaries:" >&2' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '    ls -1 "$$SCRIPT_DIR"/$(BINARY_NAME)-* 2>/dev/null | sed "s|^|  |" >&2' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '    exit 1' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo 'fi' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo '# Execute the binary with all arguments' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo 'exec "$$BINARY" "$$@"' >> $(BUILD_DIR)/$(BINARY_NAME).sh
	@chmod +x $(BUILD_DIR)/$(BINARY_NAME).sh
	@echo "✓ Created launcher script: $(BUILD_DIR)/$(BINARY_NAME).sh"

# Generate go.sum
$(GO_SUM_PATH): $(GO_MOD_PATH)
	@echo "Downloading dependencies..."
	@go mod download
	@go mod tidy
	@touch $(GO_SUM_PATH)
	@echo "Dependencies downloaded"

# Initialize go.mod - dedicated target for module initialization
init-mod:
	@if [ -f "$(GO_MOD_PATH)" ]; then \
		echo "go.mod already exists"; \
	else \
		echo "Initializing Go module $(MODULE_NAME)..."; \
		go mod init $(MODULE_NAME); \
		echo "✓ Created $(GO_MOD_PATH)"; \
	fi

# Initialize dependencies (go.mod + go.sum) - run after init-mod
init-deps: init-mod
	@echo "Downloading dependencies..."
	@go mod download
	@go mod tidy
	@echo "✓ Dependencies downloaded and go.sum updated"

# Generate go.mod (only if it doesn't exist) - implicit rule
$(GO_MOD_PATH):
	@echo "Initializing Go module..."
	@go mod init $(MODULE_NAME)

# Install binary (installs current platform binaries)
install: build
	@echo "Installing all commands for current platform ($(CURRENT_PLATFORM))..."
ifndef TARGET
	@mkdir -p $(DEFAULT_INSTALL_DIR)
	@$(foreach cmd,$(COMMANDS), \
		if [ -f "$(BUILD_DIR)/$(cmd)-$(CURRENT_PLATFORM)" ]; then \
			echo "Installing $(cmd) to $(DEFAULT_INSTALL_DIR)..."; \
			cp $(BUILD_DIR)/$(cmd)-$(CURRENT_PLATFORM) $(DEFAULT_INSTALL_DIR)/$(cmd); \
		fi;)
ifeq ($(GOOS),darwin)
	@echo "Signing binaries for macOS..."
	@$(foreach cmd,$(COMMANDS), \
		if [ -f "$(DEFAULT_INSTALL_DIR)/$(cmd)" ]; then \
			codesign -f -s - $(DEFAULT_INSTALL_DIR)/$(cmd); \
		fi;)
endif
else
	@$(foreach cmd,$(COMMANDS), \
		if [ -f "$(BUILD_DIR)/$(cmd)-$(CURRENT_PLATFORM)" ]; then \
			echo "Installing $(cmd) to $(TARGET)..."; \
			cp $(BUILD_DIR)/$(cmd)-$(CURRENT_PLATFORM) $(TARGET)/$(cmd); \
		fi;)
ifeq ($(GOOS),darwin)
	@echo "Signing binaries for macOS..."
	@$(foreach cmd,$(COMMANDS), \
		if [ -f "$(TARGET)/$(cmd)" ]; then \
			codesign -f -s - $(TARGET)/$(cmd); \
		fi;)
endif
endif
	@echo "Installation complete!"

# Install launcher scripts (for multi-platform distribution)
install-launcher: build-all
	@echo "Installing launcher scripts for all commands..."
ifndef TARGET
	@mkdir -p $(DEFAULT_INSTALL_DIR)
	@$(foreach cmd,$(COMMANDS), \
		echo "Installing launcher for $(cmd) to $(DEFAULT_INSTALL_DIR)..."; \
		cp $(BUILD_DIR)/$(cmd).sh $(DEFAULT_INSTALL_DIR)/$(cmd); \
		mkdir -p $(DEFAULT_LIB_DIR)/$(cmd); \
		cp $(BUILD_DIR)/$(cmd)-linux-amd64 $(DEFAULT_LIB_DIR)/$(cmd)/ 2>/dev/null || true; \
		cp $(BUILD_DIR)/$(cmd)-darwin-amd64 $(DEFAULT_LIB_DIR)/$(cmd)/ 2>/dev/null || true; \
		cp $(BUILD_DIR)/$(cmd)-darwin-arm64 $(DEFAULT_LIB_DIR)/$(cmd)/ 2>/dev/null || true; \
		cp $(BUILD_DIR)/$(cmd)-windows-amd64.exe $(DEFAULT_LIB_DIR)/$(cmd)/ 2>/dev/null || true;)
ifeq ($(GOOS),darwin)
	@echo "Signing macOS binaries after install..."
	@$(foreach cmd,$(COMMANDS), \
		if [ -f "$(DEFAULT_LIB_DIR)/$(cmd)/$(cmd)-darwin-amd64" ]; then codesign -f -s - $(DEFAULT_LIB_DIR)/$(cmd)/$(cmd)-darwin-amd64; fi; \
		if [ -f "$(DEFAULT_LIB_DIR)/$(cmd)/$(cmd)-darwin-arm64" ]; then codesign -f -s - $(DEFAULT_LIB_DIR)/$(cmd)/$(cmd)-darwin-arm64; fi;)
endif
else
	@$(foreach cmd,$(COMMANDS), \
		echo "Installing launcher for $(cmd) to $(TARGET)..."; \
		cp $(BUILD_DIR)/$(cmd).sh $(TARGET)/$(cmd);)
	@echo "Note: Platform binaries remain in $(BUILD_DIR)/"
endif
	@echo "Installation complete!"

# Uninstall binaries
uninstall:
	@echo "Uninstalling all commands..."
	@$(foreach cmd,$(COMMANDS), \
		BINARY_PATH=$$(which $(cmd) 2>/dev/null); \
		if [ -n "$$BINARY_PATH" ]; then \
			echo "Removing $(cmd) from $$BINARY_PATH..."; \
			rm -f "$$BINARY_PATH" 2>/dev/null || sudo rm -f "$$BINARY_PATH"; \
			if [ -d "/usr/local/lib/$(cmd)" ]; then \
				echo "Removing platform binaries for $(cmd) from /usr/local/lib..."; \
				sudo rm -rf "/usr/local/lib/$(cmd)"; \
			fi; \
			if [ -d "$(HOME)/.local/lib/$(cmd)" ]; then \
				echo "Removing platform binaries for $(cmd) from ~/.local/lib..."; \
				rm -rf "$(HOME)/.local/lib/$(cmd)"; \
			fi; \
		fi;)
	@echo "Uninstallation complete!"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -f ./$(DEFAULT_BINARY_NAME)
	@echo "Clean complete!"

# Clean all (including go.mod and go.sum)
clean-all: clean
	@echo "Cleaning go.mod & go.sum..."
	@rm -f $(GO_MOD_PATH) $(GO_SUM_PATH)
	@echo "Clean complete!"

# Run functional tests (shell scripts in tests/)
test: build
ifeq ($(HAS_FUNCTIONAL_TESTS),yes)
	@echo "Running functional tests..."
	@chmod +x tests/*.sh 2>/dev/null || true
	@tests/run_tests.sh
else
	@echo "No functional tests found (tests/run_tests.sh not present)"
	@echo "Run 'make test-unit' for Go unit tests"
endif

# Run Go unit tests only
test-unit:
	@echo "Running Go unit tests..."
	@go test -v ./...

# Run all tests (functional + unit)
test-all: build
	@echo "Running all tests..."
ifeq ($(HAS_FUNCTIONAL_TESTS),yes)
	@echo "=== Functional Tests ==="
	@chmod +x tests/*.sh 2>/dev/null || true
	@tests/run_tests.sh
endif
	@echo ""
	@echo "=== Go Unit Tests ==="
	@go test -v ./...
	@echo ""
	@echo "All tests completed!"

# Format code
fmt:
	@echo "Formatting code..."
	@go fmt ./...
	@echo "Format complete!"

# Run go vet
vet:
	@echo "Running go vet..."
	@go vet ./...
	@echo "Vet complete!"

# Run linter (golangci-lint if available, otherwise fallback to vet)
lint:
	@if command -v golangci-lint >/dev/null 2>&1; then \
		echo "Running golangci-lint..."; \
		golangci-lint run ./...; \
		echo "Lint complete!"; \
	else \
		echo "golangci-lint not found, falling back to go vet..."; \
		echo "Install golangci-lint: https://golangci-lint.run/welcome/install/"; \
		$(MAKE) vet; \
	fi

# Run all checks (fmt, vet, lint, test)
check: fmt vet lint test
	@echo "All checks passed!"

# Run the application (passes arguments via ARGS and CMD variables)
run: build
ifndef CMD
	@echo "Error: Please specify CMD variable."
	@echo "Example: make run CMD=mycommand ARGS='--help'"
	@echo "Available commands:"
	@$(foreach cmd,$(COMMANDS),echo "  - $(cmd)";)
	@exit 1
else
	@echo "Running $(CMD)..."
	@$(BUILD_DIR)/$(CMD)-$(CURRENT_PLATFORM) $(ARGS)
endif

# List all available commands
list-commands:
	@echo "Available commands in this project:"
	@$(foreach cmd,$(COMMANDS),echo "  - $(cmd)";)

# Build and push all Docker images (linux-amd64)
docker: docker-build docker-push

# Build Docker images for all commands
docker-build:
	@for cmd in $(COMMANDS); do \
		echo "Building Docker image: $(MAKE_DOCKER_PREFIX)$(PROJECT_NAME)-$$cmd:$(DOCKER_TAG)"; \
		docker build -t $(MAKE_DOCKER_PREFIX)$(PROJECT_NAME)-$$cmd:$(DOCKER_TAG) . \
			--build-arg GO_BIN=$$cmd \
			--build-arg HAS_INTERNAL=$(HAS_INTERNAL) \
			--build-arg HAS_DATA=$(HAS_DATA); \
	done

# Push Docker images for all commands
docker-push:
	@for cmd in $(COMMANDS); do \
		echo "Pushing: $(MAKE_DOCKER_PREFIX)$(PROJECT_NAME)-$$cmd:$(DOCKER_TAG)"; \
		docker push $(MAKE_DOCKER_PREFIX)$(PROJECT_NAME)-$$cmd:$(DOCKER_TAG); \
	done

# Show current platform info
info:
	@echo "Current platform: $(CURRENT_PLATFORM)"
	@echo "Build directory: $(BUILD_DIR)"
	@echo "Commands: $(COMMANDS)"

# Help
help:
	@echo "Available targets:"
	@echo "  build            - Build binaries for current platform ($(CURRENT_PLATFORM))"
	@echo "  build-all        - Build for all platforms and create launcher scripts"
	@echo "  run              - Build and run the binary"
	@echo "  rebuild          - Clean all and rebuild for current platform"
	@echo "  rebuild-all      - Clean all and rebuild for all platforms"
	@echo "  install          - Install current platform binaries (root: /usr/local/bin, user: ~/.local/bin, or TARGET)"
	@echo "  install-launcher - Install launcher scripts with all platform binaries"
	@echo "  uninstall        - Remove installed binaries"
	@echo "  clean            - Remove build artifacts"
	@echo "  clean-all        - Remove build artifacts, go.mod, and go.sum"
	@echo "  init-mod         - Initialize go.mod with module name (uses MODULE_NAME)"
	@echo "  init-deps        - Initialize go.mod and download dependencies"
	@echo "  test             - Run functional tests (shell scripts in tests/)"
	@echo "  test-unit        - Run Go unit tests only"
	@echo "  test-all         - Run all tests (functional + unit)"
	@echo "  fmt              - Format code"
	@echo "  vet              - Run go vet"
	@echo "  lint             - Run golangci-lint (or go vet if not installed)"
	@echo "  check            - Run fmt, vet, lint, and test"
	@echo "  docker           - Build and push Docker images (linux-amd64)"
	@echo "  docker-build     - Build Docker images for all commands"
	@echo "  docker-push      - Push Docker images to registry"
	@echo "  list-commands    - List all available commands (multi-command projects)"
	@echo "  info             - Show current platform and project information"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Available commands:"
	@$(foreach cmd,$(COMMANDS),echo "  - $(cmd)";)
	@echo ""
	@echo "Examples:"
	@echo "  make build                     - Build all commands for current platform"
	@echo "  make build-all                 - Build all commands for all platforms"
	@echo "  make run CMD=mycommand         - Run specific command"
	@echo "  make run CMD=mycommand ARGS='--help' - Run with arguments"
	@echo "  make install                   - Install all commands for current platform"
	@echo "  make install-launcher          - Install launcher scripts for all commands"
	@echo ""
	@echo "Platform-specific binaries are created in $(BUILD_DIR)/ with suffixes:"
	@echo "  -linux-amd64        - Linux (Intel/AMD 64-bit)"
	@echo "  -darwin-amd64       - macOS (Intel)"
	@echo "  -darwin-arm64       - macOS (Apple Silicon)"
	@echo "  -windows-amd64.exe  - Windows (Intel/AMD 64-bit)"
	@echo ""
	@echo "Launcher scripts (.sh) automatically detect platform and execute the right binary."
	@echo ""
	@echo "Configuration variables:"
	@echo "  MODULE_NAME        - Go module name (default: $(MODULE_NAME))"
	@echo "                       Override with: make init-mod MODULE_NAME=github.com/myorg/myproject"
	@echo "  MAKE_DOCKER_PREFIX - Docker registry prefix (default: empty)"
	@echo "                       Example: MAKE_DOCKER_PREFIX=gcr.io/my-project/ make docker"
	@echo "  DOCKER_TAG         - Docker image tag (default: latest)"
	@echo "                       Example: DOCKER_TAG=v1.0.0 make docker"
