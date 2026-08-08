import Foundation

struct DeviceCapabilities: Equatable {
    var arKitAvailable = false
    var sceneDepthAvailable = false
    var smoothedSceneDepthAvailable = false
    var meshReconstructionAvailable = false
    var roomPlanAvailable = false

    var hasLiDAR: Bool { sceneDepthAvailable }
}

