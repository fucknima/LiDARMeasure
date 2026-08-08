import Foundation

struct RoomPlanMeasurement: Identifiable, Equatable {
    let id: UUID
    let category: String
    let dimensions: MeasurementDimensions

    init(id: UUID = UUID(), category: String, dimensions: MeasurementDimensions) {
        self.id = id
        self.category = category
        self.dimensions = dimensions
    }
}

