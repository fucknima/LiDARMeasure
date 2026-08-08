import XCTest
import simd
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

    func testPointCloudOutlierFilterRemovesFarPoint() {
        var points = (0..<20).map { index in
            Point3D(SIMD3<Float>(Float(index % 4) * 0.01, Float(index / 4) * 0.01, 1))
        }
        points.append(Point3D(SIMD3<Float>(10, 10, 10)))
        let filtered = MeasurementGeometry.filterOutliers(points)
        XCTAssertEqual(filtered.count, 20)
    }
}
