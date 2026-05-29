import AVFoundation
import Foundation

/// Plays MP3 audio files using AVAudioPlayer.
final class AudioPlayer: @unchecked Sendable {
    private let lock = NSLock()
    private var currentPlayer: AVAudioPlayer?

    /// Minimum volume (maps to amplitude at threshold).
    private static let minVolume: Float = 0.125 // ~1/8 volume
    /// Maximum volume (maps to hard slap).
    private static let maxVolume: Float = 1.0

    /// Play an audio file at the given URL.
    ///
    /// - Parameters:
    ///   - url: Path to the MP3 file.
    ///   - amplitude: Detected slap amplitude (used for volume scaling).
    ///   - volumeScaling: Whether to scale volume by amplitude.
    func play(url: URL, amplitude: Double, volumeScaling: Bool) {
        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: url)
        } catch {
            return
        }

        if volumeScaling {
            player.volume = Self.amplitudeToVolume(amplitude)
        }

        lock.lock()
        currentPlayer = player
        lock.unlock()

        player.play()
    }

    /// Stop any currently playing audio.
    func stop() {
        lock.lock()
        let player = currentPlayer
        currentPlayer = nil
        lock.unlock()
        player?.stop()
    }

    /// Map amplitude to AVAudioPlayer volume (0.0 to 1.0).
    ///
    /// Uses the same logarithmic curve as the Go implementation in
    /// `pkg/core/volume.go`, but mapped to AVAudioPlayer's 0-1 range.
    static func amplitudeToVolume(_ amplitude: Double) -> Float {
        let minAmp = 0.05
        let maxAmp = 0.80

        if amplitude <= minAmp { return minVolume }
        if amplitude >= maxAmp { return maxVolume }

        let t = (amplitude - minAmp) / (maxAmp - minAmp)
        let logT = log(1.0 + t * 99.0) / log(100.0)

        return minVolume + Float(logT) * (maxVolume - minVolume)
    }
}
