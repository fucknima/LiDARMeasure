import ARKit
import Foundation
import RoomPlan

enum DeviceCapabilityService {
    static func detect() -> DeviceCapabilities {
        var result = DeviceCapabilities()
        result.arKitAvailable = ARWorldTrackingConfiguration.isSupported
        result.sceneDepthAvailable = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
        result.smoothedSceneDepthAvailable = ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth)
        result.meshReconstructionAvailable = ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification)
        if #available(iOS 17.0, *) {
            result.roomPlanAvailable = RoomCaptureSession.isSupported
        }
        return result
    }
}

