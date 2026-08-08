import SwiftUI

struct ContentView: View {
    @ObservedObject var model: MeasureViewModel
    @State private var showingHistory = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    if model.mode == .roomScan && model.capabilities.roomPlanAvailable {
                        RoomCaptureViewContainer(service: model.roomPlanService)
                            .ignoresSafeArea()
                    } else {
                        ARViewContainer(sessionManager: model.sessionManager)
                            .ignoresSafeArea()
                            .overlay(alignment: .center) { CrosshairView() }
                            .contentShape(Rectangle())
                            .gesture(tapGesture)
                            .simultaneousGesture(selectionGesture)
                    }

                    VStack(spacing: 12) {
                        topBar
                        Spacer()
                        if let selectionRect = model.selectionRect {
                            Rectangle()
                                .stroke(.yellow, style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .frame(width: selectionRect.width, height: selectionRect.height)
                                .position(x: selectionRect.midX, y: selectionRect.midY)
                        }
                        resultCard
                        debugOverlay
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .onAppear { model.setViewportSize(proxy.size) }
                .onChange(of: proxy.size) { _, size in model.setViewportSize(size) }
            }
            .safeAreaInset(edge: .bottom) { controls }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("测量历史", systemImage: "clock") { showingHistory = true }
                        Button("设置", systemImage: "gearshape") { showingSettings = true }
                        Toggle("调试覆盖层", isOn: $model.showDebugOverlay)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingHistory) { HistoryView(storage: model.storage) }
            .sheet(isPresented: $showingSettings) { SettingsView(model: model) }
        }
    }

    private var tapGesture: some Gesture {
        SpatialTapGesture().onEnded { value in
            model.handleTap(at: value.location)
        }
    }

    private var selectionGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if model.selectionRect == nil { model.beginSelection(at: value.startLocation) }
                model.updateSelection(to: value.location)
            }
            .onEnded { _ in model.endSelection() }
    }

    private var topBar: some View {
        HStack {
            Label("LiDAR Measure", systemImage: "cube.transparent")
                .font(.headline.weight(.semibold))
            Spacer()
            Text(model.capabilities.hasLiDAR ? "LiDAR" : "普通 AR")
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
        }
    }

    @ViewBuilder
    private var resultCard: some View {
        if let dimensions = model.currentDimensions {
            VStack(alignment: .leading, spacing: 6) {
                if let label = model.automaticLabel { Text(label).font(.subheadline.bold()) }
                Text(dimensions.formatted(using: model.unitSettings.unit))
                    .font(.subheadline.monospacedDigit())
                HStack {
                    Text(model.statusMessage)
                    Spacer()
                    Text(model.quality.grade.rawValue)
                        .foregroundStyle(qualityColor(model.quality.grade))
                }
                .font(.caption)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else if let distance = model.formattedDistance {
            VStack(alignment: .leading, spacing: 6) {
                Text("距离").font(.subheadline.bold())
                Text(distance).font(.title3.monospacedDigit())
                Text(model.statusMessage).font(.caption)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else {
            Text(model.statusMessage)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Picker("模式", selection: $model.mode) {
                ForEach(MeasurementMode.allCases) { mode in Text(mode.title).tag(mode) }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Button("撤销", systemImage: "arrow.uturn.backward", action: model.undo)
                Button("清除", systemImage: "xmark.circle", action: model.clearMeasurement)
                Button("保存", systemImage: "square.and.arrow.down") {
                    Task { await model.saveCurrentMeasurement() }
                }
                .disabled(model.isSaving)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var debugOverlay: some View {
        if model.showDebugOverlay {
            VStack(alignment: .leading, spacing: 3) {
                Text("Tracking: \(model.sessionManager.trackingState)")
                Text("Depth: \(model.sessionManager.depthAvailable ? "available" : "unavailable")")
                Text("Points: \(model.sessionManager.pointCount)")
                Text("Quality: \(model.quality.confidence, specifier: "%.2f")")
            }
            .font(.caption2.monospaced())
            .padding(8)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func qualityColor(_ grade: MeasurementQuality.Grade) -> Color {
        switch grade {
        case .excellent: return .green
        case .good: return .yellow
        case .poor: return .orange
        case .unknown: return .secondary
        }
    }
}

private struct CrosshairView: View {
    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.9), lineWidth: 1.5).frame(width: 32, height: 32)
            Rectangle().fill(.white).frame(width: 1, height: 42)
            Rectangle().fill(.white).frame(width: 42, height: 1)
        }
        .shadow(radius: 2)
        .allowsHitTesting(false)
    }
}

