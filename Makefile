GO ?= go
GOMOBILE ?= gomobile
DIST_DIR ?= dist

# CLI entry package.
CLI_PKG ?= ./cmd/spank

.PHONY: build-cli build-cli-lite build-mac-dylib build-mac-static build-ios-sdk build-android-sdk build-sdk

build-cli:
	mkdir -p $(DIST_DIR)
	$(GO) build -tags with_assets -o $(DIST_DIR)/spank $(CLI_PKG)

build-cli-lite:
	mkdir -p $(DIST_DIR)
	$(GO) build -tags lite -o $(DIST_DIR)/spank-lite $(CLI_PKG)

build-mac-dylib:
	mkdir -p $(DIST_DIR)
	$(GO) build -tags lite -buildmode=c-shared -o $(DIST_DIR)/libspank.dylib ./bindings/capi

build-mac-static:
	mkdir -p $(DIST_DIR)
	$(GO) build -tags lite -buildmode=c-archive -o $(DIST_DIR)/libspank.a ./bindings/capi

build-ios-sdk:
	mkdir -p $(DIST_DIR)
	$(GOMOBILE) bind -tags lite -target=ios -o $(DIST_DIR)/Spank.xcframework ./bindings/mobile

build-android-sdk:
	mkdir -p $(DIST_DIR)
	$(GOMOBILE) bind -tags lite -target=android -androidapi 21 -o $(DIST_DIR)/spank.aar ./bindings/mobile

build-sdk: build-mac-dylib build-ios-sdk build-android-sdk
