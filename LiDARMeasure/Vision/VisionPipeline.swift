import ARKit
import CoreVideo
import Vision

struct VisionPipelineResult {
    let observation: VisionObjectObservation?
    let foregroundMask: CVPixelBuffer?

    var hasForegroundMask: Bool { foregroundMask != nil }
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
            var foregroundMask: CVPixelBuffer?
            if let segmenter {
                foregroundMask = try? segmenter.mask(pixelBuffer: frame.capturedImage)
            }
            return VisionPipelineResult(observation: observation, foregroundMask: foregroundMask)
        } catch {
            AppLogger.vision.error("Vision analysis failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
