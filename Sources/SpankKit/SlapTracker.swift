import Foundation

/// Tracks slap frequency and selects audio files.
///
/// Ports the algorithm from `pkg/core/tracker.go`:
/// - Random mode: picks a random file.
/// - Escalation mode: maps an exponentially-decaying score to
///   a file index so intensity increases with slap frequency.
final class SlapTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var score: Double = 0
    private var lastTime: Date?
    private var total: Int = 0
    private let halfLife: Double = 30.0 // seconds
    private let scale: Double
    private let isEscalation: Bool
    let files: [URL]

    init(files: [URL], isEscalation: Bool, cooldown: TimeInterval) {
        self.files = files
        self.isEscalation = isEscalation

        if files.isEmpty {
            self.scale = 1.0
        } else {
            let ssMax = 1.0 / (1.0 - pow(0.5, cooldown / 30.0))
            self.scale = (ssMax - 1.0) / log(Double(files.count + 1))
        }
    }

    /// Record a slap and return (slapNumber, currentScore).
    func record(now: Date) -> (Int, Double) {
        lock.lock()
        defer { lock.unlock() }

        if let last = lastTime {
            let elapsed = now.timeIntervalSince(last)
            score *= pow(0.5, elapsed / halfLife)
        }
        score += 1.0
        lastTime = now
        total += 1
        return (total, score)
    }

    /// Select an audio file based on the current score.
    func getFile(score: Double) -> URL? {
        guard !files.isEmpty else { return nil }

        if !isEscalation {
            return files[Int.random(in: 0..<files.count)]
        }

        let maxIdx = files.count - 1
        guard scale > 0, !scale.isNaN, !scale.isInfinite else {
            return files[maxIdx]
        }

        var idx = Int(Double(files.count) * (1.0 - exp(-(score - 1.0) / scale)))
        idx = min(idx, maxIdx)
        if idx < 0 { idx = 0 }
        return files[idx]
    }
}
