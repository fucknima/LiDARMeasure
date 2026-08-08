import ARKit
import RealityKit
import UIKit

struct RaycastService {
    func worldPoint(from screenPoint: CGPoint, in arView: ARView) -> SIMD3<Float>? {
        let results = arView.raycast(from: screenPoint, allowing: .estimatedPlane, alignment: .any)
        guard let transform = results.first?.worldTransform else { return nil }
        return SIMD3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }

    func depthWorldPoint(
        from screenPoint: CGPoint,
        in arView: ARView,
        frame: ARFrame,
        sampleRadius: Int = 3
    ) -> (point: SIMD3<Float>, confidence: Float, depth: Float)? {
        guard let depthData = DepthProvider.bestDepthData(from: frame),
              arView.bounds.width > 0,
              arView.bounds.height > 0 else { return nil }

        let viewportPoint = CGPoint(
            x: screenPoint.x / arView.bounds.width,
            y: screenPoint.y / arView.bounds.height
        )
        let orientation = arView.window?.windowScene?.interfaceOrientation ?? .portrait
        let transform = frame.displayTransform(for: orientation, viewportSize: arView.bounds.size)
        let imagePoint = viewportPoint.applying(transform.inverted())
        let width = CVPixelBufferGetWidth(depthData.depthMap)
        let height = CVPixelBufferGetHeight(depthData.depthMap)
        let depthPixel = SIMD2(
            min(max(Int(imagePoint.x * CGFloat(width)), 0), width - 1),
            min(max(Int((1 - imagePoint.y) * CGFloat(height)), 0), height - 1)
        )
        let samples = DepthProvider.samples(from: depthData, center: depthPixel, radius: sampleRadius)
        guard let depth = RobustStatistics.median(samples.map(\.depth)), !samples.isEmpty else { return nil }
        let confidence = RobustStatistics.mean(samples.map(\.confidence)) ?? 0

        let camera = frame.camera
        let intrinsics = camera.intrinsics
        let cameraWidth = Float(CVPixelBufferGetWidth(frame.capturedImage))
        let cameraHeight = Float(CVPixelBufferGetHeight(frame.capturedImage))
        let scaleX = cameraWidth / Float(width)
        let scaleY = cameraHeight / Float(height)
        let cameraPixel = SIMD3(Float(depthPixel.x) * scaleX, Float(depthPixel.y) * scaleY, 1)
        let cameraPoint = intrinsics.inverse * cameraPixel * depth
        let world = camera.transform * SIMD4(cameraPoint, 1)
        return (SIMD3(world.x, world.y, world.z), confidence, depth)
    }
}
