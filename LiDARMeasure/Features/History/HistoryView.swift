import SwiftUI

struct HistoryView: View {
    @ObservedObject var storage: MeasurementStorage

    var body: some View {
        NavigationStack {
            Group {
                if storage.records.isEmpty {
                    ContentUnavailableView("暂无测量记录", systemImage: "clock", description: Text("完成一次测量后，点击保存即可在这里查看。"))
                } else {
                    List {
                        ForEach(storage.records) { record in
                            HistoryRow(record: record)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { storage.delete(record) } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("测量历史")
            .toolbar {
                if !storage.records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("清空", role: .destructive) { storage.removeAll() }
                    }
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let record: MeasurementRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(record.mode.title, systemImage: icon)
                    .font(.headline)
                Spacer()
                Text(record.date, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(record.dimensions.formatted(using: record.unit))
                .font(.subheadline.monospacedDigit())
            HStack {
                Text(record.quality.grade.rawValue)
                if record.screenshotPath != nil {
                    Label("截图", systemImage: "photo")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var icon: String {
        switch record.mode {
        case .automatic: return "wand.and.stars"
        case .manualDimensions: return "cube"
        case .distance: return "ruler"
        case .roomScan: return "rectangle.3.group"
        }
    }
}

