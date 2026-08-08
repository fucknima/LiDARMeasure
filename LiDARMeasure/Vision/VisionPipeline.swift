import ARKit
import CoreVideo
import Vision

struct VisionPipelineResult: Equatable, Sendable {
    let observation: VisionObjectObservation?
    let hasForegroundMask: Bool
}

final class VisionPipeline {
    private let detector = ObjectDetector()
    private let segmenter: ObjectSegmenter?
    private var lastAnalysisTime: TimeInterval = 0
    private let interval: TimeInterval

    init(interval: TimeInterval = 0.15) {
        self.interval = interval
        if #available(iOS 17.0, *) { segmenter = ObjectSegmenter() }
        else { segmenter = nil }
    }

    func analyze(frame: ARFrame, now: TimeInterval = ProcessInfo.processInfo.systemUptime) -> VisionPipelineResult? {
        guard now - lastAnalysisTime >= interval else { return nil }
        lastAnalysisTime = now

        do {
            let observation = try detector.detect(pixelBuffer: frame.capturedImage)
            var hasMask = false
            if let segmenter {
                hasMask = (try? segmenter.mask(pixelBuffer: frame.capturedImage)) != nil
            }
            return VisionPipelineResult(observation: observation, hasForegroundMask: hasMask)
        } catch {
            AppLogger.vision.error("Vision analysis failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}

