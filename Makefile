# Tessera Mobile - Makefile
# Flutter development commands

.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup and Dependencies
.PHONY: setup
setup: ## Initial project setup
	flutter pub get
	flutter doctor

.PHONY: deps
deps: ## Get Flutter dependencies
	flutter pub get

.PHONY: upgrade
upgrade: ## Upgrade Flutter dependencies
	flutter pub upgrade

.PHONY: clean
clean: ## Clean build artifacts
	flutter clean
	flutter pub get

# Development - Running the app
.PHONY: run
run: ## Run on default device (Android if available)
	flutter run

.PHONY: run-android
run-android: ## Run on Android device/emulator
	flutter run -d android

.PHONY: run-ios
run-ios: ## Run on iOS simulator (Mac only)
	flutter run -d ios

.PHONY: run-web
run-web: ## Run on Chrome
	flutter run -d chrome --web-renderer html

.PHONY: run-web-server
run-web-server: ## Run web server mode (accessible from network)
	flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0

.PHONY: devices
devices: ## List all available devices
	flutter devices

.PHONY: emulators
emulators: ## List available emulators
	flutter emulators

# Testing
.PHONY: test
test: ## Run all tests
	flutter test

.PHONY: test-coverage
test-coverage: ## Run tests with coverage
	flutter test --coverage
	@echo "Coverage report generated in coverage/lcov.info"

.PHONY: test-watch
test-watch: ## Run tests in watch mode
	flutter test --watch

.PHONY: test-unit
test-unit: ## Run unit tests only
	flutter test test/unit/

.PHONY: test-widget
test-widget: ## Run widget tests only
	flutter test test/widget/

.PHONY: test-integration
test-integration: ## Run integration tests
	flutter test integration_test/

# Code Quality
.PHONY: format
format: ## Format code
	dart format .

fmt: format ## Alias for format (standard command)

.PHONY: format-check
format-check: ## Check if code is formatted
	dart format --set-exit-if-changed .

.PHONY: analyze
analyze: ## Analyze code for issues
	flutter analyze

.PHONY: lint
lint: analyze format-check ## Run all linters

.PHONY: fix
fix: ## Auto-fix code issues
	dart fix --apply
	dart format .

# Building
.PHONY: build-apk
build-apk: ## Build Android APK (debug)
	flutter build apk --debug

.PHONY: build-apk-release
build-apk-release: ## Build Android APK (release)
	flutter build apk --release

.PHONY: build-appbundle
build-appbundle: ## Build Android App Bundle (release)
	flutter build appbundle --release

.PHONY: build-ios
build-ios: ## Build iOS (Mac only, no codesign)
	flutter build ios --no-codesign

.PHONY: build-ios-simulator
build-ios-simulator: ## Build for iOS Simulator (Mac only)
	flutter build ios --simulator

.PHONY: build-web
build-web: ## Build for web
	flutter build web --release

.PHONY: build-all
build-all: ## Build for all platforms (where available)
	@echo "Building for all available platforms..."
	@flutter build apk --release || echo "Android APK build failed"
	@flutter build appbundle --release || echo "Android App Bundle build failed"
	@flutter build ios --no-codesign || echo "iOS build failed (Mac required)"
	@flutter build web --release || echo "Web build failed"

# Debugging and Profiling
.PHONY: doctor
doctor: ## Check Flutter installation and dependencies
	flutter doctor -v

.PHONY: logs
logs: ## Show device logs
	flutter logs

.PHONY: inspect
inspect: ## Open Flutter Inspector
	flutter inspect

.PHONY: profile
profile: ## Run in profile mode
	flutter run --profile

.PHONY: release
release: ## Run in release mode
	flutter run --release

# CI/CD helpers
.PHONY: ci-test
ci-test: ## Run CI test suite (mirrors GitHub Actions)
	flutter pub get
	flutter analyze
	flutter test
	dart format --set-exit-if-changed .

.PHONY: ci-build-android
ci-build-android: ## CI Android build
	flutter pub get
	flutter build apk --release
	flutter build appbundle --release

.PHONY: ci-build-ios
ci-build-ios: ## CI iOS build (Mac only)
	flutter pub get
	flutter build ios --release --no-codesign
	flutter build ios --simulator

.PHONY: ci-build-web
ci-build-web: ## CI Web build
	flutter pub get
	flutter build web --release

# Server connection configuration
.PHONY: config-local
config-local: ## Configure for local backend (localhost:8081)
	@echo "Configuring for local backend..."
	@sed -i.bak "s|http://[^'\"]*|http://localhost:8081|g" lib/core/network/api_client.dart
	@sed -i.bak "s|ws://[^'\"]*|ws://localhost:8081|g" lib/core/network/websocket_manager.dart
	@rm lib/core/network/*.bak
	@echo "Configured for localhost:8081"

.PHONY: config-network
config-network: ## Configure for network access (requires IP)
	@read -p "Enter your machine's IP address: " ip; \
	sed -i.bak "s|http://localhost:8081|http://$$ip:8081|g" lib/core/network/api_client.dart; \
	sed -i.bak "s|ws://localhost:8081|ws://$$ip:8081|g" lib/core/network/websocket_manager.dart; \
	rm lib/core/network/*.bak; \
	echo "Configured for $$ip:8081"

# Utility commands
.PHONY: screenshots
screenshots: ## Capture screenshots from running app
	flutter screenshot

.PHONY: install-apk
install-apk: ## Install APK on connected Android device
	flutter install

.PHONY: uninstall
uninstall: ## Uninstall app from device
	@read -p "Device ID (leave empty for default): " device; \
	if [ -z "$$device" ]; then \
		flutter uninstall com.tessera.tessera_mobile; \
	else \
		flutter uninstall com.tessera.tessera_mobile -d $$device; \
	fi

.PHONY: cache-clean
cache-clean: ## Clean Flutter cache
	flutter clean
	rm -rf ~/.pub-cache
	flutter pub cache clean
	flutter pub get

.PHONY: reset
reset: clean cache-clean deps ## Full reset (clean everything and reinstall)
	@echo "Project reset complete"

# Development workflow shortcuts
.PHONY: dev
dev: deps run ## Quick start development (get deps and run)

.PHONY: dev-android
dev-android: deps run-android ## Quick start Android development

.PHONY: dev-web
dev-web: deps run-web ## Quick start web development

.PHONY: check
check: lint test ## Run all checks (lint and test)

# Performance and size analysis
.PHONY: size-apk
size-apk: ## Analyze APK size
	flutter build apk --analyze-size

.PHONY: size-appbundle
size-appbundle: ## Analyze App Bundle size
	flutter build appbundle --analyze-size

.PHONY: size-ios
size-ios: ## Analyze iOS app size (Mac only)
	flutter build ios --analyze-size

# Git helpers
.PHONY: pre-commit
pre-commit: format lint test ## Run before committing
	@echo "✅ Ready to commit!"

.PHONY: pre-push
pre-push: ci-test ## Run before pushing
	@echo "✅ Ready to push!"

# Platform-specific helpers
ifeq ($(shell uname),Darwin)
    # Mac-specific commands
    .PHONY: open-xcode
    open-xcode: ## Open iOS project in Xcode (Mac only)
	open ios/Runner.xcworkspace

    .PHONY: open-simulator
    open-simulator: ## Open iOS Simulator (Mac only)
	open -a Simulator
endif

.PHONY: open-android
open-android: ## Open Android project in Android Studio
	@if [ -d "android" ]; then \
		echo "Opening Android project..."; \
		studio android/ 2>/dev/null || echo "Android Studio not found in PATH"; \
	else \
		echo "Android directory not found"; \
	fi

# Docker alternatives (for CI or containerized builds)
.PHONY: docker-test
docker-test: ## Run tests in Docker container
	docker run --rm -v $(PWD):/app -w /app cirrusci/flutter:stable sh -c "flutter pub get && flutter test"

.PHONY: docker-build-apk
docker-build-apk: ## Build APK in Docker container
	docker run --rm -v $(PWD):/app -w /app cirrusci/flutter:stable sh -c "flutter pub get && flutter build apk --release"

.PHONY: docker-build-web
docker-build-web: ## Build web in Docker container
	docker run --rm -v $(PWD):/app -w /app cirrusci/flutter:stable sh -c "flutter pub get && flutter build web --release"

# Version and release helpers
.PHONY: version
version: ## Show Flutter and Dart versions
	@flutter --version
	@echo ""
	@dart --version

.PHONY: bump-version
bump-version: ## Bump version number
	@read -p "New version (current: $(shell grep version pubspec.yaml | head -1 | cut -d ' ' -f 2)): " version; \
	sed -i.bak "s/^version: .*/version: $$version/" pubspec.yaml; \
	rm pubspec.yaml.bak; \
	echo "Version bumped to $$version"

# Default target
.DEFAULT_GOAL := help