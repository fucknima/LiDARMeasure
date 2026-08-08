import CoreVideo
import Vision

@available(iOS 17.0, *)
final class ObjectSegmenter {
    func mask(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation = .right
    ) throws -> CVPixelBuffer? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        try handler.perform([request])
        guard let observation = request.results?.first else { return nil }
        return try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler)
    }
}

