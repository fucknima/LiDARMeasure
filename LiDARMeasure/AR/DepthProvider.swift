import ARKit
import CoreVideo

struct DepthProvider {
    struct Sample {
        let depth: Float
        let confidence: Float
        let pixel: SIMD2<Int>
    }

    static func bestDepthData(from frame: ARFrame) -> ARDepthData? {
        frame.smoothedSceneDepth ?? frame.sceneDepth
    }

    static func centerSample(from frame: ARFrame, radius: Int = 3) -> Sample? {
        guard let depthData = bestDepthData(from: frame) else { return nil }
        let depthMap = depthData.depthMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let center = SIMD2(width / 2, height / 2)
        let samples = samples(from: depthData, center: center, radius: radius)
        guard let depth = RobustStatistics.median(samples.map(\.depth)) else { return nil }
        let confidence = RobustStatistics.mean(samples.map(\.confidence)) ?? 0
        return Sample(depth: depth, confidence: confidence, pixel: center)
    }

    static func samples(from data: ARDepthData, center: SIMD2<Int>, radius: Int) -> [Sample] {
        let depthMap = data.depthMap
        let confidenceMap = data.confidenceMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let xRange = max(0, center.x - radius)...min(width - 1, center.x + radius)
        let yRange = max(0, center.y - radius)...min(height - 1, center.y + radius)

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

        var result: [Sample] = []
        result.reserveCapacity((radius * 2 + 1) * (radius * 2 + 1))
        for y in yRange {
            for x in xRange {
                let depth = depthValues[y * depthStride + x]
                guard depth.isFinite, depth > 0 else { continue }
                let confidence: Float
                if let confidenceValues {
                    // ARKit confidence is 0 (low) through 2 (high).
                    confidence = Float(confidenceValues[y * confidenceStride + x]) / 2
                } else {
                    confidence = 1
                }
                guard confidence >= 0.5 else { continue }
                result.append(Sample(depth: depth, confidence: confidence, pixel: SIMD2(x, y)))
            }
        }
        return result
    }
}

