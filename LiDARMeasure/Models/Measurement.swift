import Foundation
import simd

struct MeasurementDimensions: Codable, Equatable {
    var width: Float
    var height: Float
    var depth: Float

    static let zero = MeasurementDimensions(width: 0, height: 0, depth: 0)

    var isValid: Bool {
        width.isFinite && height.isFinite && depth.isFinite &&
        width >= 0 && height >= 0 && depth >= 0
    }

    var volume: Float { width * height * depth }

    func formatted(using unit: MeasurementUnit) -> String {
        "宽 (unit.format(width))  高 (unit.format(height))  深 (unit.format(depth))"
    }
}

struct MeasurementRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let mode: MeasurementMode
    let dimensions: MeasurementDimensions
    let unit: MeasurementUnit
    let distanceMeters: Float?
    let screenshotPath: String?
    let quality: MeasurementQuality

    init(
        id: UUID = UUID(),
        date: Date = .now,
        mode: MeasurementMode,
        dimensions: MeasurementDimensions,
        unit: MeasurementUnit,
        distanceMeters: Float? = nil,
        screenshotPath: String? = nil,
        quality: MeasurementQuality = .unknown
    ) {
        self.id = id
        self.date = date
        self.mode = mode
        self.dimensions = dimensions
        self.unit = unit
        self.distanceMeters = distanceMeters
        self.screenshotPath = screenshotPath
        self.quality = quality
    }
}

struct MeasurementQuality: Codable, Equatable {
    enum Grade: String, Codable {
        case excellent = "优秀"
        case good = "良好"
        case poor = "较差"
        case unknown = "未知"
    }

    var grade: Grade
    var confidence: Float
    var validPointCount: Int
    var trackingState: String
    var stability: Float

    static let unknown = MeasurementQuality(
        grade: .unknown,
        confidence: 0,
        validPointCount: 0,
        trackingState: "未开始",
        stability: 0
    )

    static func evaluate(
        trackingState: String,
        depthConfidence: Float,
        pointCount: Int,
        distanceMeters: Float?,
        stability: Float
    ) -> MeasurementQuality {
        let distanceScore: Float
        if let distanceMeters {
            if distanceMeters < 0.2 { distanceScore = 0.2 }
            else if distanceMeters <= 3 { distanceScore = 1 }
            else if distanceMeters <= 4 { distanceScore = 0.7 }
            else { distanceScore = 0.4 }
        } else {
            distanceScore = 0.6
        }

        let pointScore: Float = min(1, Float(pointCount) / 200)
        let trackingScore: Float = trackingState == "正常" ? 1 : 0.45
        let confidenceScore = depthConfidence * 0.4
        let pointCountScore = pointScore * 0.2
        let stabilityScore = stability * 0.25
        let distanceQualityScore = distanceScore * 0.1
        let trackingQualityScore = trackingScore * 0.05
        let score = confidenceScore + pointCountScore + stabilityScore +
            distanceQualityScore + trackingQualityScore

        let grade: Grade
        if score >= 0.78 { grade = .excellent }
        else if score >= 0.52 { grade = .good }
        else { grade = .poor }

        return MeasurementQuality(
            grade: grade,
            confidence: score,
            validPointCount: pointCount,
            trackingState: trackingState,
            stability: stability
        )
    }
}

struct Point3D: Sendable, Equatable {
    let value: SIMD3<Float>
    let confidence: Float

    init(_ value: SIMD3<Float>, confidence: Float = 1) {
        self.value = value
        self.confidence = confidence
    }
}
