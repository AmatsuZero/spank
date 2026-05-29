import Foundation

/// Audio playback mode for the spank engine.
public enum SpankMode: Sendable {
    /// Default "ow!" pain responses, random playback.
    case pain
    /// Escalating intensity responses — the more you slap, the more intense.
    case sexy
    /// Halo death sounds, random playback.
    case halo
    /// Lizard mode, escalating intensity.
    case lizard
    /// Custom audio files provided by the caller.
    case custom(urls: [URL])

    /// Whether this mode uses escalation (intensity increases with frequency)
    /// or random selection.
    var isEscalation: Bool {
        switch self {
        case .sexy, .lizard:
            return true
        case .pain, .halo, .custom:
            return false
        }
    }

    /// Directory name within the asset bundle for built-in modes.
    public var assetDirectoryName: String? {
        switch self {
        case .pain: return "pain"
        case .sexy: return "sexy"
        case .halo: return "halo"
        case .lizard: return "lizard"
        case .custom: return nil
        }
    }
}
