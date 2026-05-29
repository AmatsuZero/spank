import XCTest
import SpankKit
@testable import SpankKitAssets

final class SpankAssetsTests: XCTestCase {
    func testPainAudioURLsNotEmpty() {
        let urls = SpankAssets.audioURLs(for: .pain)
        XCTAssertFalse(urls.isEmpty, "Pain audio should contain files")
        XCTAssertEqual(urls.count, 10, "Pain pack should have 10 files")
    }

    func testSexyAudioURLsNotEmpty() {
        let urls = SpankAssets.audioURLs(for: .sexy)
        XCTAssertFalse(urls.isEmpty, "Sexy audio should contain files")
        XCTAssertEqual(urls.count, 60, "Sexy pack should have 60 files")
    }

    func testHaloAudioURLsNotEmpty() {
        let urls = SpankAssets.audioURLs(for: .halo)
        XCTAssertFalse(urls.isEmpty, "Halo audio should contain files")
        XCTAssertEqual(urls.count, 9, "Halo pack should have 9 files")
    }

    func testLizardAudioURLsNotEmpty() {
        let urls = SpankAssets.audioURLs(for: .lizard)
        XCTAssertFalse(urls.isEmpty, "Lizard audio should contain files")
        XCTAssertEqual(urls.count, 1, "Lizard pack should have 1 file")
    }

    func testCustomModeReturnsEmpty() {
        let urls = SpankAssets.audioURLs(for: .custom(urls: []))
        XCTAssertTrue(urls.isEmpty, "Custom mode should return empty from assets")
    }

    func testAudioFilesAreSorted() {
        let urls = SpankAssets.audioURLs(for: .pain)
        let names = urls.map(\.lastPathComponent)
        XCTAssertEqual(names, names.sorted(), "Audio URLs should be sorted by filename")
    }

    func testAudioFilesExist() {
        let urls = SpankAssets.audioURLs(for: .pain)
        for url in urls {
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: url.path),
                "Audio file should exist: \(url.lastPathComponent)"
            )
        }
    }
}
