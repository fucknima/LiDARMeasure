import Foundation

enum MeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case millimeter = "mm"
    case centimeter = "cm"
    case meter = "m"
    case inch = "in"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .millimeter: return "毫米 (mm)"
        case .centimeter: return "厘米 (cm)"
        case .meter: return "米 (m)"
        case .inch: return "英寸 (in)"
        }
    }

    var metersPerUnit: Float {
        switch self {
        case .millimeter: return 0.001
        case .centimeter: return 0.01
        case .meter: return 1
        case .inch: return 0.0254
        }
    }

    func value(fromMeters meters: Float) -> Float {
        meters / metersPerUnit
    }

    func format(_ meters: Float, decimals: Int = 1) -> String {
        let value = value(fromMeters: meters)
        return "\(value.formatted(.number.precision(.fractionLength(decimals)))) \(rawValue)"
    }
}

