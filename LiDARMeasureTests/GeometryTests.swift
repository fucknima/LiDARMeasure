import XCTest
import simd
@testable import LiDARMeasure

final class GeometryTests: XCTestCase {
    func testDistanceUsesMeters() {
        let a = SIMD3<Float>(0, 0, 0)
        let b = SIMD3<Float>(0.3, 0.4, 0)
        XCTAssertEqual(MeasurementGeometry.distance(a, b), 0.5, accuracy: 0.0001)
    }

    func testOrientedBoundingBoxReturnsDimensionsForRotatedCuboid() {
        let dimensions = SIMD3<Float>(0.4, 0.8, 0.2)
        let rotation = simd_float3x3(simd_quatf(angle: .pi / 4, axis: SIMD3(0, 1, 0)))
        let points = MeasurementGeometry.corners(
            center: .zero,
            axes: rotation,
            dimensions: MeasurementDimensions(width: dimensions.x, height: dimensions.y, depth: dimensions.z)
        )

        let box = MeasurementGeometry.orientedBoundingBox(for: points)
        XCTAssertNotNil(box)
        XCTAssertEqual(box?.dimensions.height ?? 0, 0.8, accuracy: 0.0001)
        XCTAssertEqual(box?.dimensions.width ?? 0, 0.4, accuracy: 0.0001)
        XCTAssertEqual(box?.dimensions.depth ?? 0, 0.2, accuracy: 0.0001)
    }
}

