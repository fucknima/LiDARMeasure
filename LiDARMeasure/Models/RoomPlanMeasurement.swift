import Foundation
import simd

struct RoomPlanMeasurement: Identifiable {
    let id: UUID
    let category: String
    let dimensions: MeasurementDimensions
    let transform: simd_float4x4

    init(id: UUID = UUID(), category: String, dimensions: MeasurementDimensions, transform: simd_float4x4 = matrix_identity_float4x4) {
        self.id = id
        self.category = category
        self.dimensions = dimensions
        self.transform = transform
    }
}
