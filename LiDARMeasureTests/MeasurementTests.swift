import XCTest
@testable import LiDARMeasure

final class MeasurementTests: XCTestCase {
    func testUnitConversionIsBasedOnMeters() {
        XCTAssertEqual(MeasurementUnit.centimeter.value(fromMeters: 0.425), 42.5, accuracy: 0.0001)
        XCTAssertEqual(MeasurementUnit.inch.value(fromMeters: 0.0254), 1, accuracy: 0.0001)
    }

    func testSmootherUsesMedianAndLocksAfterStableSamples() {
        var smoother = MeasurementSmoother(windowSize: 5, relativeTolerance: 0.02, stableFrameCount: 3)
        for _ in 0..<5 {
            _ = smoother.add(MeasurementDimensions(width: 0.425, height: 0.312, depth: 0.281))
        }
        XCTAssertTrue(smoother.isStable)
        XCTAssertEqual(smoother.current?.width ?? 0, 0.425, accuracy: 0.0001)
    }

    func testMeasurementQualityGradesLowPointCountAsPoor() {
        let quality = MeasurementQuality.evaluate(
            trackingState: "受限",
            depthConfidence: 0.2,
            pointCount: 4,
            distanceMeters: 5,
            stability: 0
        )
        XCTAssertEqual(quality.grade, .poor)
    }
}

