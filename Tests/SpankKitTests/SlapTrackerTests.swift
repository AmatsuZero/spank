import XCTest
@testable import SpankKit

final class SlapTrackerTests: XCTestCase {
    private func makeDummyURLs(count: Int) -> [URL] {
        (0..<count).map { URL(fileURLWithPath: "/tmp/test_\(String(format: "%02d", $0)).mp3") }
    }

    // MARK: - Random mode

    func testRandomModeReturnsFileFromList() {
        let urls = makeDummyURLs(count: 10)
        let tracker = SlapTracker(files: urls, isEscalation: false, cooldown: 0.75)

        for _ in 0..<20 {
            let file = tracker.getFile(score: 1.0)
            XCTAssertNotNil(file)
            XCTAssertTrue(urls.contains(file!))
        }
    }

    func testRandomModeEmptyFilesReturnsNil() {
        let tracker = SlapTracker(files: [], isEscalation: false, cooldown: 0.75)
        XCTAssertNil(tracker.getFile(score: 1.0))
    }

    // MARK: - Escalation mode

    func testEscalationLowScoreReturnsEarlyIndex() {
        let urls = makeDummyURLs(count: 60)
        let tracker = SlapTracker(files: urls, isEscalation: true, cooldown: 0.75)

        let file = tracker.getFile(score: 1.0)
        XCTAssertNotNil(file)
        // Score of 1.0 should produce index 0 (the formula gives 1 - exp(0) = 0)
        XCTAssertEqual(file, urls[0])
    }

    func testEscalationHighScoreReturnsLaterIndex() {
        let urls = makeDummyURLs(count: 60)
        let tracker = SlapTracker(files: urls, isEscalation: true, cooldown: 0.75)

        let lowFile = tracker.getFile(score: 2.0)
        let highFile = tracker.getFile(score: 20.0)

        XCTAssertNotNil(lowFile)
        XCTAssertNotNil(highFile)

        let lowIdx = urls.firstIndex(of: lowFile!)!
        let highIdx = urls.firstIndex(of: highFile!)!
        XCTAssertGreaterThan(highIdx, lowIdx, "Higher score should produce higher file index")
    }

    // MARK: - Score tracking

    func testRecordIncrementsSlapCount() {
        let tracker = SlapTracker(files: makeDummyURLs(count: 5), isEscalation: false, cooldown: 0.75)
        let now = Date()

        let (count1, _) = tracker.record(now: now)
        let (count2, _) = tracker.record(now: now.addingTimeInterval(1))
        let (count3, _) = tracker.record(now: now.addingTimeInterval(2))

        XCTAssertEqual(count1, 1)
        XCTAssertEqual(count2, 2)
        XCTAssertEqual(count3, 3)
    }

    func testScoreDecaysOverTime() {
        let tracker = SlapTracker(files: makeDummyURLs(count: 5), isEscalation: true, cooldown: 0.75)
        let now = Date()

        let (_, score1) = tracker.record(now: now)
        // Wait a full half-life (30s) — score should decay to ~half then add 1
        let (_, score2) = tracker.record(now: now.addingTimeInterval(30))

        // After 30s decay: score1 * 0.5 + 1.0
        let expected = score1 * 0.5 + 1.0
        XCTAssertEqual(score2, expected, accuracy: 0.001)
    }
}
