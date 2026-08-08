import CoreImage
import CoreVideo
import Vision

struct VisionObjectObservation: Equatable, Sendable {
    let identifier: String
    let confidence: Float
    let boundingBox: CGRect
}

final class ObjectDetector {
    func detect(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .right) throws -> VisionObjectObservation? {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        try handler.perform([request])
        guard let observation = request.results?.first(where: { $0.confidence > 0.15 }) else { return nil }
        return VisionObjectObservation(
            identifier: observation.identifier,
            confidence: observation.confidence,
            // Classification observations do not carry a region of interest;
            // treat the full frame as the fallback selection.
            boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1)
        )
    }
}
