import Foundation
import Spank

/// Full-managed slap detection and audio playback engine.
///
/// Usage:
/// ```swift
/// let engine = SpankEngine(mode: .pain, audioURLs: SpankAssets.audioURLs(for: .pain))
/// engine.onSlap = { event in print("Slap #\(event.slapNumber)!") }
/// engine.feed(x: 0.1, y: 0.2, z: 2.5)
/// ```
public final class SpankEngine: @unchecked Sendable {
    /// Called when a slap is detected and audio is triggered.
    public var onSlap: ((SpankEvent) -> Void)?

    /// Whether to scale playback volume by slap amplitude.
    public var volumeScaling: Bool = false

    private let gate: MobileGate
    private let tracker: SlapTracker
    private let player: AudioPlayer
    private let playbackQueue = DispatchQueue(label: "com.spankkit.playback", qos: .userInitiated)
    private var slapCount: Int = 0

    /// The default minimum amplitude threshold.
    public static var defaultMinAmplitude: Double {
        MobileDefaultMinAmplitude()
    }

    /// Map an amplitude value to a volume factor.
    public static func amplitudeToVolume(_ amplitude: Double) -> Double {
        MobileAmplitudeToVolume(amplitude)
    }

    /// Create a new SpankEngine.
    ///
    /// - Parameters:
    ///   - mode: Audio playback mode (determines random vs escalation selection).
    ///   - minAmplitude: Minimum acceleration amplitude to trigger a response.
    ///   - cooldownMs: Minimum milliseconds between audio responses.
    ///   - audioURLs: Audio file URLs to use. For built-in modes, pass
    ///     `SpankAssets.audioURLs(for: mode)` from the `SpankKitAssets` module.
    public init(
        mode: SpankMode,
        minAmplitude: Double = MobileDefaultMinAmplitude(),
        cooldownMs: Int = 750,
        audioURLs: [URL]
    ) {
        let urls: [URL]
        if case .custom(let customURLs) = mode {
            urls = customURLs
        } else {
            urls = audioURLs.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }

        self.gate = MobileNewGate(minAmplitude, Int64(cooldownMs))!
        self.tracker = SlapTracker(
            files: urls,
            isEscalation: mode.isEscalation,
            cooldown: TimeInterval(cooldownMs) / 1000.0
        )
        self.player = AudioPlayer()
    }

    /// Feed raw accelerometer data. The engine computes the magnitude
    /// and decides whether to trigger audio playback.
    ///
    /// - Parameters:
    ///   - x: X-axis acceleration in g.
    ///   - y: Y-axis acceleration in g.
    ///   - z: Z-axis acceleration in g.
    public func feed(x: Double, y: Double, z: Double) {
        let magnitude = sqrt(x * x + y * y + z * z)
        let now = Date()
        let nowNanos = Int64(now.timeIntervalSince1970 * 1e9)

        guard gate.accept(nowNanos, amplitude: magnitude, severity: "shock", nowUnixNanos: nowNanos) else {
            return
        }

        let (num, score) = tracker.record(now: now)
        let file = tracker.getFile(score: score)
        slapCount = num

        let event = SpankEvent(
            amplitude: magnitude,
            severity: "shock",
            timestamp: now,
            slapNumber: num,
            audioURL: file
        )

        onSlap?(event)

        if let url = file {
            let volumeScaling = self.volumeScaling
            let amplitude = magnitude
            playbackQueue.async { [weak self] in
                self?.player.play(url: url, amplitude: amplitude, volumeScaling: volumeScaling)
            }
        }
    }

    /// Update detection parameters at runtime.
    public func updateConfig(minAmplitude: Double, cooldownMs: Int) {
        gate.update(minAmplitude, cooldownMs: Int64(cooldownMs))
    }

    /// Stop any playing audio and release resources.
    public func stop() {
        player.stop()
    }
}
