import Foundation
import simd

struct OrientedBoundingBox {
    let center: SIMD3<Float>
    let axes: simd_float3x3
    let dimensions: MeasurementDimensions
    let corners: [SIMD3<Float>]

    var transform: simd_float4x4 {
        var value = matrix_identity_float4x4
        value.columns.0 = SIMD4(axes.columns.0, 0)
        value.columns.1 = SIMD4(axes.columns.1, 0)
        value.columns.2 = SIMD4(axes.columns.2, 0)
        value.columns.3 = SIMD4(center, 1)
        return value
    }
}

enum MeasurementGeometry {
    static func distance(_ first: SIMD3<Float>, _ second: SIMD3<Float>) -> Float {
        simd_distance(first, second)
    }

    static func aabb(for points: [SIMD3<Float>]) -> MeasurementDimensions? {
        let valid = points.filter { isFiniteVector($0) }
        guard let first = valid.first else { return nil }
        var minValue = first
        var maxValue = first
        for point in valid.dropFirst() {
            minValue = simd_min(minValue, point)
            maxValue = simd_max(maxValue, point)
        }
        let size = maxValue - minValue
        return MeasurementDimensions(width: abs(size.x), height: abs(size.y), depth: abs(size.z))
    }

    static func filterOutliers(_ points: [Point3D], multiplier: Float = 3) -> [Point3D] {
        let valid = points.filter { isFiniteVector($0.value) }
        guard valid.count >= 8 else { return valid }
        let center = valid.reduce(SIMD3<Float>.zero) { $0 + $1.value } / Float(valid.count)
        let distances = valid.map { simd_distance($0.value, center) }
        guard let median = RobustStatistics.median(distances),
              let mad = RobustStatistics.mad(distances),
              mad > Float.ulpOfOne else { return valid }
        let limit = median + multiplier * 1.4826 * mad
        return valid.filter { simd_distance($0.value, center) <= limit }
    }

    static func orientedBoundingBox(
        for points: [SIMD3<Float>],
        gravity: SIMD3<Float> = SIMD3<Float>(0, 1, 0)
    ) -> OrientedBoundingBox? {
        let validPoints = points.filter { isFiniteVector($0) }
        guard validPoints.count >= 4 else { return nil }

        let center = validPoints.reduce(SIMD3<Float>.zero, +) / Float(validPoints.count)
        let up = normalizedOrFallback(gravity, fallback: SIMD3<Float>(0, 1, 0))
        let zAxis = SIMD3<Float>(0, 0, 1)
        let xAxis = SIMD3<Float>(1, 0, 0)
        let reference = abs(simd_dot(up, zAxis)) > 0.9 ? xAxis : zAxis
        let projectedReference = reference - up * simd_dot(reference, up)
        let forward = normalizedOrFallback(projectedReference, fallback: zAxis)
        let right = normalizedOrFallback(simd_cross(up, forward), fallback: xAxis)

        // A 2D PCA on the plane orthogonal to gravity. The closed-form angle
        // for a symmetric 2x2 covariance matrix avoids an unstable custom solver.
        var covarianceXX: Float = 0
        var covarianceXZ: Float = 0
        var covarianceZZ: Float = 0
        for point in validPoints {
            let delta = point - center
            let x = simd_dot(delta, right)
            let z = simd_dot(delta, forward)
            covarianceXX += x * x
            covarianceXZ += x * z
            covarianceZZ += z * z
        }
        let angle = 0.5 * atan2(2 * covarianceXZ, covarianceXX - covarianceZZ)
        let rotatedRight = right * cos(angle)
        let rotatedForward = forward * sin(angle)
        let horizontalA = normalizedOrFallback(rotatedRight + rotatedForward, fallback: right)
        let horizontalB = normalizedOrFallback(simd_cross(up, horizontalA), fallback: forward)
        let axes = simd_float3x3(columns: (horizontalA, up, horizontalB))

        var minProjection = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var maxProjection = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        for point in validPoints {
            let delta = point - center
            let projection = SIMD3(
                simd_dot(delta, horizontalA),
                simd_dot(delta, up),
                simd_dot(delta, horizontalB)
            )
            minProjection = simd_min(minProjection, projection)
            maxProjection = simd_max(maxProjection, projection)
        }

        let dimensions = MeasurementDimensions(
            width: maxProjection.x - minProjection.x,
            height: maxProjection.y - minProjection.y,
            depth: maxProjection.z - minProjection.z
        )
        let localCenter = (minProjection + maxProjection) * 0.5
        let worldCenter = center + axes * localCenter
        let corners = Self.corners(center: worldCenter, axes: axes, dimensions: dimensions)
        return OrientedBoundingBox(center: worldCenter, axes: axes, dimensions: dimensions, corners: corners)
    }

    static func corners(
        center: SIMD3<Float>,
        axes: simd_float3x3,
        dimensions: MeasurementDimensions
    ) -> [SIMD3<Float>] {
        let half = SIMD3<Float>(dimensions.width, dimensions.height, dimensions.depth) * 0.5
        let signs: [Float] = [-1, 1]
        return signs.flatMap { x in
            signs.flatMap { y in
                signs.map { z in
                    let localCorner = SIMD3<Float>(x, y, z) * half
                    return center + axes * localCorner
                }
            }
        }
    }

    private static func normalizedOrFallback(_ value: SIMD3<Float>, fallback: SIMD3<Float>) -> SIMD3<Float> {
        let length = simd_length(value)
        return length > Float.ulpOfOne && length.isFinite ? value / length : fallback
    }

    private static func isFiniteVector(_ value: SIMD3<Float>) -> Bool {
        value.x.isFinite && value.y.isFinite && value.z.isFinite
    }
}
