import Foundation
import SpankKit

/// Provides access to built-in audio assets bundled with the package.
///
/// Audio files are organized by mode in the resource bundle:
/// - `pain/` — 10 "ow!" responses
/// - `sexy/` — 60 escalating responses
/// - `halo/` — 9 Halo death sounds
/// - `lizard/` — lizard mode sounds
public struct SpankAssets: Sendable {
    /// Returns sorted audio file URLs for the given mode.
    ///
    /// For `.custom` mode, this returns an empty array — use the URLs
    /// you provided directly.
    ///
    /// - Parameter mode: The playback mode.
    /// - Returns: An array of file URLs for MP3 audio files, sorted by filename.
    public static func audioURLs(for mode: SpankMode) -> [URL] {
        guard let dirName = mode.assetDirectoryName else { return [] }

        guard let resourceURL = Bundle.module.url(
            forResource: dirName,
            withExtension: nil,
            subdirectory: "Resources"
        ) else {
            return []
        }

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: resourceURL,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        let mp3Files = contents.filter { $0.pathExtension.lowercased() == "mp3" }
        return mp3Files.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
