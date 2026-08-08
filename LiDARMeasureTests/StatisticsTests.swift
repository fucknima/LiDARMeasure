import XCTest
@testable import LiDARMeasure

final class StatisticsTests: XCTestCase {
    func testMedianAndMADIgnoreNonFiniteValues() {
        let values: [Float] = [1, 2, 3, 100, .infinity, .nan]
        XCTAssertEqual(RobustStatistics.median(values), 2.5, accuracy: 0.0001)
        XCTAssertEqual(RobustStatistics.mad(values), 1, accuracy: 0.0001)
    }

    func testIQRFilterRemovesExtremeOutlier() {
        let values: [Float] = [1, 2, 3, 4, 5, 100]
        let filtered = RobustStatistics.filterByIQR(values)
        XCTAssertFalse(filtered.contains(100))
        XCTAssertEqual(filtered.count, 5)
    }
}

