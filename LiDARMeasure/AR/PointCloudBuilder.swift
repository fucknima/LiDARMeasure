import ARKit
import CoreVideo
import simd

struct PointCloudBuilder {
    struct Configuration {
        var stride = 4
        var minimumConfidence: Float = 0.5
        var depthBand: ClosedRange<Float>?
        var roi: CGRect?
    }

    func build(from frame: ARFrame, configuration: Configuration = .init()) -> [Point3D] {
        guard let depthData = DepthProvider.bestDepthData(from: frame) else { return [] }
        let depthMap = depthData.depthMap
        let confidenceMap = depthData.confidenceMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)

        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        if let confidenceMap { CVPixelBufferLockBaseAddress(confidenceMap, .readOnly) }
        defer {
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            if let confidenceMap { CVPixelBufferUnlockBaseAddress(confidenceMap, .readOnly) }
        }

        guard let depthBase = CVPixelBufferGetBaseAddress(depthMap) else { return [] }
        let depthStride = CVPixelBufferGetBytesPerRow(depthMap) / MemoryLayout<Float32>.stride
        let depthValues = depthBase.assumingMemoryBound(to: Float32.self)

        let confidenceValues: UnsafeMutablePointer<UInt8>?
        let confidenceStride: Int
        if let confidenceMap, let base = CVPixelBufferGetBaseAddress(confidenceMap) {
            confidenceValues = base.assumingMemoryBound(to: UInt8.self)
            confidenceStride = CVPixelBufferGetBytesPerRow(confidenceMap)
        } else {
            confidenceValues = nil
            confidenceStride = 0
        }

        let stride = max(1, configuration.stride)
        let intrinsics = frame.camera.intrinsics
        let cameraTransform = frame.camera.transform
        var result: [Point3D] = []
        result.reserveCapacity((width / stride) * (height / stride))

        for y in stride / 2..<height where y % stride == stride / 2 {
            for x in stride / 2..<width where x % stride == stride / 2 {
                if let roi = configuration.roi {
                    let normalized = CGPoint(x: CGFloat(x) / CGFloat(width), y: CGFloat(y) / CGFloat(height))
                    guard roi.contains(normalized) else { continue }
                }
                let depth = depthValues[y * depthStride + x]
                guard depth.isFinite, depth > 0 else { continue }
                if let depthBand = configuration.depthBand, !depthBand.contains(depth) { continue }

                let confidence: Float
                if let confidenceValues {
                    confidence = Float(confidenceValues[y * confidenceStride + x]) / 2
                } else {
                    confidence = 1
                }
                guard confidence >= configuration.minimumConfidence else { continue }

                let cameraPoint = intrinsics.inverse * SIMD3(Float(x), Float(y), 1) * depth
                let worldPoint = cameraTransform * SIMD4(cameraPoint, 1)
                result.append(Point3D(SIMD3(worldPoint.x, worldPoint.y, worldPoint.z), confidence: confidence))
            }
        }
        return result
    }

    func foregroundBand(around centerDepth: Float, tolerance: Float = 0.1) -> ClosedRange<Float> {
        let filtered = RobustStatistics.filterByMAD([centerDepth - tolerance, centerDepth, centerDepth + tolerance])
        let center = RobustStatistics.median(filtered) ?? centerDepth
        return max(0, center - tolerance)...(center + tolerance)
    }
}
