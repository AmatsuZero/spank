# SpankKit SPM Integration Design

> Date: 2025-05-28

## Goal

Wrap the existing gomobile xcframework output into a Swift Package Manager-friendly library so that Apple platform consumers can integrate via a single SPM dependency.

## Decisions

| Decision | Choice |
|----------|--------|
| Platform scope | iOS + macOS combined |
| Underlying binary | gomobile bind `-target=ios,macos` (unified xcframework) |
| Distribution | Pre-built xcframework zip on GitHub Release, `binaryTarget(url:checksum:)` |
| Repo location | Main spank repo (no separate SPM repo) |
| Audio resources | Optional `SpankKitAssets` target with bundled MP3s |
| Playback responsibility | Full managed — SDK handles detection + playback |

## Directory Structure (additions to main repo)

```
spank/
├── Package.swift
├── Sources/
│   ├── SpankKit/
│   │   ├── SpankEngine.swift        # High-level managed API
│   │   ├── SpankMode.swift          # Mode enum (pain/sexy/halo/custom)
│   │   ├── SpankEvent.swift         # Event types
│   │   └── AudioPlayer.swift        # AVFoundation playback wrapper
│   └── SpankKitAssets/
│       ├── SpankAssets.swift         # Bundle accessor
│       └── Resources/
│           ├── pain/                 # symlink or copy of audio/pain/*.mp3
│           ├── sexy/                 # symlink or copy of audio/sexy/*.mp3
│           └── halo/                 # symlink or copy of audio/halo/*.mp3
├── Tests/
│   └── SpankKitTests/
│       └── SpankKitTests.swift
```

## Package.swift

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SpankKit",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "SpankKit", targets: ["SpankKit"]),
        .library(name: "SpankKitAssets", targets: ["SpankKitAssets"]),
    ],
    targets: [
        .binaryTarget(
            name: "Spank",
            url: "https://github.com/AmatsuZero/spank/releases/download/v<VERSION>/Spank.xcframework.zip",
            checksum: "<SHA256>"
        ),
        .target(
            name: "SpankKit",
            dependencies: ["Spank"]
        ),
        .target(
            name: "SpankKitAssets",
            dependencies: ["SpankKit"],
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "SpankKitTests",
            dependencies: ["SpankKit", "SpankKitAssets"]
        ),
    ]
)
```

## Swift API

### SpankMode

```swift
public enum SpankMode {
    case pain
    case sexy
    case halo
    case custom(urls: [URL])
}
```

### SpankEvent

```swift
public struct SpankEvent {
    public let amplitude: Double
    public let severity: String
    public let timestamp: Date
}
```

### SpankEngine

```swift
public final class SpankEngine {
    public var onSlap: ((SpankEvent) -> Void)?

    public init(mode: SpankMode,
                minAmplitude: Double = SpankEngine.defaultMinAmplitude,
                cooldownMs: Int = 750)

    public static var defaultMinAmplitude: Double { get }
    public static func amplitudeToVolume(_ amplitude: Double) -> Double

    /// Feed raw accelerometer data. Engine decides whether to trigger.
    public func feed(x: Double, y: Double, z: Double)

    /// Update detection parameters at runtime.
    public func updateConfig(minAmplitude: Double, cooldownMs: Int)

    /// Stop playback and release resources.
    public func stop()
}
```

### Internal Flow

1. `feed(x:y:z:)` computes magnitude → calls Go `Gate.Accept()`
2. If accepted → picks audio file based on mode (random or escalation)
3. Plays via `AVAudioPlayer`
4. Fires `onSlap` callback

## Build & CI

### New Makefile Targets

```makefile
build-xcframework:
    $(GOMOBILE) bind -tags lite -target=ios,macos -o $(DIST_DIR)/Spank.xcframework ./bindings/mobile

package-spm:
    cd $(DIST_DIR) && zip -r Spank.xcframework.zip Spank.xcframework
    shasum -a 256 $(DIST_DIR)/Spank.xcframework.zip
```

### Release Workflow Update

Add to `release-sdk.yml`:

1. Build xcframework with `gomobile bind -target=ios,macos`
2. Zip the xcframework
3. Compute SHA256 checksum
4. Upload zip to GitHub Release
5. Update `Package.swift` with new URL and checksum (commit or PR)

## Implementation Steps

1. Add `Package.swift` to repo root
2. Create `Sources/SpankKit/` with Swift wrapper files
3. Create `Sources/SpankKitAssets/` with bundle accessor and audio resources
4. Create `Tests/SpankKitTests/`
5. Update `Makefile` with `build-xcframework` and `package-spm` targets
6. Update `release-sdk.yml` with xcframework build + release steps
7. Verify: `swift build`, local SPM resolution, xcframework generation
8. Update `Progress.md`
