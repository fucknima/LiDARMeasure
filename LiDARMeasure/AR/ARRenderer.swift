import RealityKit
import simd
import UIKit

@MainActor
final class ARRenderer {
    private let anchor = AnchorEntity(world: .zero)
    private weak var arView: ARView?

    func attach(to arView: ARView) {
        self.arView = arView
        if !arView.scene.anchors.contains(where: { $0 === anchor }) {
            arView.scene.addAnchor(anchor)
        }
    }

    func clear() {
        anchor.children.removeAll()
    }

    func showDistance(from start: SIMD3<Float>, to end: SIMD3<Float>, color: UIColor = .systemYellow) {
        let entity = lineEntity(from: start, to: end, color: color, thickness: 0.006)
        anchor.addChild(entity)
        anchor.addChild(sphere(at: start, color: color, radius: 0.012))
        anchor.addChild(sphere(at: end, color: color, radius: 0.012))
    }

    func showManualDimensions(points: [SIMD3<Float>], color: UIColor = .systemYellow) {
        guard points.count >= 4 else { return }
        clear()
        let edges = [(0, 1), (0, 2), (0, 3)]
        for (start, end) in edges {
            anchor.addChild(lineEntity(from: points[start], to: points[end], color: color, thickness: 0.006))
        }
        for point in points.prefix(4) {
            anchor.addChild(sphere(at: point, color: color, radius: 0.012))
        }
    }

    func showBoundingBox(_ box: OrientedBoundingBox, color: UIColor = .systemGreen) {
        clear()
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3),
            (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)
        ]
        for (start, end) in edges where start < box.corners.count && end < box.corners.count {
            anchor.addChild(lineEntity(from: box.corners[start], to: box.corners[end], color: color, thickness: 0.004))
        }
    }

    private func lineEntity(from start: SIMD3<Float>, to end: SIMD3<Float>, color: UIColor, thickness: Float) -> ModelEntity {
        let vector = end - start
        let length = simd_length(vector)
        let mesh = MeshResource.generateBox(size: [max(length, 0.001), thickness, thickness])
        let material = SimpleMaterial(color: color, roughness: 0.25, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = (start + end) / 2
        if length > .ulpOfOne {
            entity.orientation = simd_quatf(from: SIMD3(1, 0, 0), to: vector / length)
        }
        return entity
    }

    private func sphere(at position: SIMD3<Float>, color: UIColor, radius: Float) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
        entity.position = position
        return entity
    }
}
