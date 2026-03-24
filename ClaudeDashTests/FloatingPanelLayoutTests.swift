import XCTest
@testable import ClaudeDash

final class FloatingPanelLayoutTests: XCTestCase {
    func testVisibleSessionCountIsCappedForCompactIsland() {
        XCTAssertEqual(FloatingPanelLayout.visibleSessionCount(forTotalSessionCount: 0), 1)
        XCTAssertEqual(FloatingPanelLayout.visibleSessionCount(forTotalSessionCount: 1), 1)
        XCTAssertEqual(FloatingPanelLayout.visibleSessionCount(forTotalSessionCount: 4), 4)
        XCTAssertEqual(FloatingPanelLayout.visibleSessionCount(forTotalSessionCount: 9), FloatingPanelLayout.maxVisibleSessions)
    }

    func testPanelHeightUsesCompactRowsAndKeepsSingleRowForEmptyState() {
        XCTAssertEqual(FloatingPanelLayout.panelHeight(forTotalSessionCount: 0), 52, accuracy: 0.1)
        XCTAssertEqual(FloatingPanelLayout.panelHeight(forTotalSessionCount: 1), 52, accuracy: 0.1)
        XCTAssertEqual(FloatingPanelLayout.panelHeight(forTotalSessionCount: 3), 112, accuracy: 0.1)
        XCTAssertEqual(FloatingPanelLayout.panelHeight(forTotalSessionCount: 10), 142, accuracy: 0.1)
    }
}
