import Foundation

/// Represents a detected slap event.
public struct SpankEvent: Sendable {
    /// Detected acceleration amplitude.
    public let amplitude: Double
    /// Severity label from the detection engine (e.g. "shock").
    public let severity: String
    /// When the slap was detected.
    public let timestamp: Date
    /// Sequential slap counter.
    public let slapNumber: Int
    /// URL of the audio file selected for playback.
    public let audioURL: URL?
}
