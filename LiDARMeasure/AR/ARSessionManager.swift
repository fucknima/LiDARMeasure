import ARKit
import Combine
import RealityKit

@MainActor
final class ARSessionManager: NSObject, ObservableObject {
    let session = ARSession()
    let renderer = ARRenderer()

    @Published private(set) var capabilities = DeviceCapabilityService.detect()
    @Published private(set) var trackingState = "未开始"
    @Published private(set) var lastFrame: ARFrame?
    @Published private(set) var depthAvailable = false
    @Published private(set) var pointCount = 0
    @Published private(set) var lastError: String?

    weak var arView: ARView?
    var frameHandler: ((ARFrame) -> Void)?

    override init() {
        super.init()
        session.delegate = self
        capabilities = DeviceCapabilityService.detect()
    }

    func attach(to view: ARView) {
        arView = view
        view.session = session
        view.automaticallyConfigureSession = false
    }

    func start() {
        guard capabilities.arKitAvailable else {
            lastError = "当前设备不支持 ARKit"
            trackingState = "不可用"
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]

        if capabilities.sceneDepthAvailable {
            configuration.frameSemantics.insert(.sceneDepth)
            if capabilities.smoothedSceneDepthAvailable {
                configuration.frameSemantics.insert(.smoothedSceneDepth)
            }
        }
        if capabilities.meshReconstructionAvailable {
            configuration.sceneReconstruction = .meshWithClassification
        }

        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        trackingState = "初始化中"
        lastError = nil
    }

    func pause() {
        session.pause()
        trackingState = "已暂停"
    }

    func clearError() {
        lastError = nil
    }

    func setPointCount(_ count: Int) {
        pointCount = count
    }

    private func handle(frame: ARFrame) {
        lastFrame = frame
        depthAvailable = frame.smoothedSceneDepth != nil || frame.sceneDepth != nil
        switch frame.camera.trackingState {
        case .normal:
            trackingState = "正常"
        case .limited(let reason):
            trackingState = "受限：\(String(describing: reason))"
        case .notAvailable:
            trackingState = "不可用"
        @unknown default:
            trackingState = "未知"
        }
        frameHandler?(frame)
    }
}

extension ARSessionManager: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { @MainActor [weak self] in
            self?.handle(frame: frame)
        }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.lastError = "ARKit：\(error.localizedDescription)"
            AppLogger.ar.error("AR session failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        Task { @MainActor [weak self] in self?.trackingState = "被中断" }
    }

    nonisolated func sessionInterruptionEnded(_ session: ARSession) {
        Task { @MainActor [weak self] in self?.start() }
    }
}
