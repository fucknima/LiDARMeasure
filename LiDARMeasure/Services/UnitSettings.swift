import Foundation
import Combine

@MainActor
final class UnitSettings: ObservableObject {
    @Published var unit: MeasurementUnit {
        didSet { UserDefaults.standard.set(unit.rawValue, forKey: key) }
    }

    private let key = "preferredMeasurementUnit"

    init() {
        unit = MeasurementUnit(rawValue: UserDefaults.standard.string(forKey: key) ?? "cm") ?? .centimeter
    }
}
