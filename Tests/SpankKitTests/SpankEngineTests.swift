import XCTest
@testable import SpankKit

final class SpankEngineTests: XCTestCase {
    private func makeDummyURLs(count: Int) -> [URL] {
        (0..<count).map { URL(fileURLWithPath: "/tmp/engine_test_\(String(format: "%02d", $0)).mp3") }
    }

    func testEngineCreation() {
        let engine = SpankEngine(mode: .pain, audioURLs: makeDummyURLs(count: 10))
        XCTAssertNotNil(engine)
    }

    func testDefaultMinAmplitude() {
        let value = SpankEngine.defaultMinAmplitude
        XCTAssertGreaterThan(value, 0)
        XCTAssertLessThan(value, 1)
    }

    func testAmplitudeToVolume() {
        let vol = SpankEngine.amplitudeToVolume(0.4)
        XCTAssertGreaterThanOrEqual(vol, -3.0)
        XCTAssertLessThanOrEqual(vol, 0.0)
    }

    func testFeedHighAmplitudeTriggersSlap() {
        let urls = makeDummyURLs(count: 5)
        let engine = SpankEngine(mode: .pain, minAmplitude: 0.05, cooldownMs: 100, audioURLs: urls)

        let expectation = expectation(description: "onSlap called")
        engine.onSlap = { event in
            XCTAssertGreaterThan(event.amplitude, 0)
            XCTAssertEqual(event.slapNumber, 1)
            XCTAssertNotNil(event.audioURL)
            expectation.fulfill()
        }

        // Feed a high-amplitude acceleration (simulating a strong slap)
        engine.feed(x: 0.0, y: 0.0, z: 3.0)

        wait(for: [expectation], timeout: 1.0)
        engine.stop()
    }

    func testFeedLowAmplitudeDoesNotTrigger() {
        let urls = makeDummyURLs(count: 5)
        let engine = SpankEngine(mode: .pain, minAmplitude: 0.5, cooldownMs: 100, audioURLs: urls)

        var triggered = false
        engine.onSlap = { _ in triggered = true }

        // Feed a very low amplitude — should not trigger
        engine.feed(x: 0.01, y: 0.01, z: 0.01)

        // Give a small window for any async processing
        let exp = expectation(description: "wait")
        exp.isInverted = true
        wait(for: [exp], timeout: 0.2)

        XCTAssertFalse(triggered, "Low amplitude should not trigger slap")
        engine.stop()
    }

    func testCooldownPreventsDoubleTrigger() {
        let urls = makeDummyURLs(count: 5)
        let engine = SpankEngine(mode: .pain, minAmplitude: 0.05, cooldownMs: 2000, audioURLs: urls)

        var triggerCount = 0
        engine.onSlap = { _ in triggerCount += 1 }

        // Two rapid feeds — only the first should trigger due to 2s cooldown
        engine.feed(x: 0.0, y: 0.0, z: 3.0)
        engine.feed(x: 0.0, y: 0.0, z: 3.0)

        let exp = expectation(description: "wait")
        exp.isInverted = true
        wait(for: [exp], timeout: 0.3)

        XCTAssertEqual(triggerCount, 1, "Cooldown should prevent double trigger")
        engine.stop()
    }

    func testUpdateConfig() {
        let urls = makeDummyURLs(count: 5)
        // Start with impossibly high threshold
        let engine = SpankEngine(mode: .pain, minAmplitude: 10.0, cooldownMs: 50, audioURLs: urls)

        var triggered = false
        engine.onSlap = { _ in triggered = true }

        // With minAmplitude=10.0, normal feed should not trigger
        engine.feed(x: 0.0, y: 0.0, z: 3.0)

        let exp1 = expectation(description: "wait1")
        exp1.isInverted = true
        wait(for: [exp1], timeout: 0.2)
        XCTAssertFalse(triggered)

        // Lower the threshold and wait for cooldown to expire
        engine.updateConfig(minAmplitude: 0.05, cooldownMs: 50)

        // Wait for cooldown to expire then feed again
        let exp2 = expectation(description: "onSlap after config update")
        engine.onSlap = { _ in exp2.fulfill() }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            engine.feed(x: 0.0, y: 0.0, z: 3.0)
        }

        wait(for: [exp2], timeout: 2.0)
        engine.stop()
    }
}
