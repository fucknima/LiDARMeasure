import Foundation
import Combine

@MainActor
final class MeasurementStorage: ObservableObject {
    @Published private(set) var records: [MeasurementRecord] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        fileURL = directory.appendingPathComponent("measurements.json")

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func append(_ record: MeasurementRecord) {
        records.insert(record, at: 0)
        persist()
    }

    func delete(_ record: MeasurementRecord) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    func removeAll() {
        records.removeAll()
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            records = try decoder.decode([MeasurementRecord].self, from: data)
        } catch {
            AppLogger.measure.error("Unable to decode measurement history: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            AppLogger.measure.error("Unable to persist measurement history: \(error.localizedDescription, privacy: .public)")
        }
    }
}
