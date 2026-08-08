import Foundation

enum MeasurementMode: String, Codable, CaseIterable, Identifiable {
    case automatic
    case manualDimensions
    case distance
    case roomScan

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "自动"
        case .manualDimensions: return "长宽高"
        case .distance: return "长度"
        case .roomScan: return "房间"
        }
    }
}

