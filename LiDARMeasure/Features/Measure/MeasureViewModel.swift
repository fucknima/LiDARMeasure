import ARKit
import Combine
import Foundation
import RealityKit
import UIKit

@MainActor
final class MeasureViewModel: ObservableObject {
    let sessionManager: ARSessionManager
    let roomPlanService: RoomPlanService
    let storage: MeasurementStorage
    let unitSettings: UnitSettings

    @Published var mode: MeasurementMode = .automatic {
        didSet { modeDidChange(oldValue: oldValue) }
    }
    @Published private(set) var currentDistanceMeters: Float?
    @Published private(set) var currentDimensions: MeasurementDimensions?
    @Published private(set) var quality = MeasurementQuality.unknown
    @Published private(set) var statusMessage = "对准物体并保持手机稳定"
    @Published private(set) var automaticLabel: String?
    @Published private(set) var selectedPoints: [SIMD3<Float>] = []
    @Published private(set) var selectionRect: CGRect?
    @Published private(set) var isSaving = false
    @Published var showDebugOverlay = false

    private let raycastService = RaycastService()
    private let pointCloudBuilder = PointCloudBuilder()
    private let visionPipeline = VisionPipeline()
    private let screenshotService = ScreenshotService()
    private var smoother = MeasurementSmoother()
    private var dragStart: CGPoint?
    private var viewportSize: CGSize = .zero

    init(
        sessionManager: ARSessionManager = ARSessionManager(),
        roomPlanService: RoomPlanService = RoomPlanService(),
        storage: MeasurementStorage = MeasurementStorage(),
        unitSettings: UnitSettings = UnitSettings()
    ) {
        self.sessionManager = sessionManager
        self.roomPlanService = roomPlanService
        self.storage = storage
        self.unitSettings = unitSettings
        sessionManager.frameHandler = { [weak self] frame in
            self?.process(frame: frame)
        }
    }

    var capabilities: DeviceCapabilities { sessionManager.capabilities }
    var formattedDistance: String? {
        guard let currentDistanceMeters else { return nil }
        return unitSettings.unit.format(currentDistanceMeters)
    }

    var formattedDimensions: String? {
        guard let currentDimensions else { return nil }
        return currentDimensions.formatted(using: unitSettings.unit)
    }

    func setViewportSize(_ size: CGSize) {
        viewportSize = size
    }

    func setMode(_ newMode: MeasurementMode) {
        mode = newMode
    }

    func handleTap(at location: CGPoint) {
        guard mode == .distance || mode == .manualDimensions else { return }
        guard let frame = sessionManager.lastFrame,
              let arView = sessionManager.arView else {
            statusMessage = "AR 还未准备好"
            return
        }
        let point = raycastService.depthWorldPoint(from: location, in: arView, frame: frame)?.point
            ?? raycastService.worldPoint(from: location, in: arView)
        guard let point else {
            statusMessage = "没有找到可测量的表面"
            return
        }

        selectedPoints.append(point)
        if mode == .distance {
            if selectedPoints.count > 2 { selectedPoints.removeFirst() }
            if selectedPoints.count == 2 {
                currentDistanceMeters = MeasurementGeometry.distance(selectedPoints[0], selectedPoints[1])
                currentDimensions = nil
                sessionManager.renderer.clear()
                sessionManager.renderer.showDistance(from: selectedPoints[0], to: selectedPoints[1])
                statusMessage = "长度已计算"
            } else {
                statusMessage = "已记录点 A，再点一下记录点 B"
            }
        } else {
            if selectedPoints.count > 4 { selectedPoints.removeFirst() }
            if selectedPoints.count == 4 {
                let width = MeasurementGeometry.distance(selectedPoints[0], selectedPoints[1])
                let height = MeasurementGeometry.distance(selectedPoints[0], selectedPoints[2])
                let depth = MeasurementGeometry.distance(selectedPoints[0], selectedPoints[3])
                currentDimensions = MeasurementDimensions(width: width, height: height, depth: depth)
                currentDistanceMeters = nil
                statusMessage = "长宽高已计算"
            } else {
                statusMessage = "依次点击左下、右下、左上和后角（\(selectedPoints.count)/4）"
            }
        }
    }

    func beginSelection(at location: CGPoint) {
        guard mode == .automatic else { return }
        dragStart = location
        selectionRect = CGRect(origin: location, size: .zero)
    }

    func updateSelection(to location: CGPoint) {
        guard let dragStart else { return }
        selectionRect = CGRect(
            x: min(dragStart.x, location.x),
            y: min(dragStart.y, location.y),
            width: abs(location.x - dragStart.x),
            height: abs(location.y - dragStart.y)
        )
    }

    func endSelection() {
        dragStart = nil
        if let rect = selectionRect, (rect.width < 12 || rect.height < 12) {
            selectionRect = nil
        } else if selectionRect != nil {
            statusMessage = "已选择区域，保持手机稳定"
        }
    }

    func undo() {
        if !selectedPoints.isEmpty {
            selectedPoints.removeLast()
            currentDistanceMeters = nil
            if mode == .manualDimensions { currentDimensions = nil }
            sessionManager.renderer.clear()
        } else {
            clearMeasurement()
        }
    }

    func clearMeasurement() {
        selectedPoints.removeAll()
        currentDistanceMeters = nil
        currentDimensions = nil
        automaticLabel = nil
        selectionRect = nil
        smoother.reset()
        sessionManager.renderer.clear()
        statusMessage = "对准物体并保持手机稳定"
    }

    func saveCurrentMeasurement() async {
        guard currentDistanceMeters != nil || currentDimensions != nil else {
            statusMessage = "还没有可保存的测量结果"
            return
        }
        isSaving = true
        defer { isSaving = false }

        var screenshotPath: String?
        if let arView = sessionManager.arView, let image = screenshotService.capture(view: arView) {
            screenshotPath = try? screenshotService.saveToDocuments(image)
            do { try await screenshotService.saveToPhotos(image) }
            catch { AppLogger.measure.error("Photo save skipped: \(error.localizedDescription, privacy: .public)") }
        }

        let dimensions = currentDimensions ?? MeasurementDimensions(
            width: currentDistanceMeters ?? 0,
            height: 0,
            depth: 0
        )
        let record = MeasurementRecord(
            mode: mode,
            dimensions: dimensions,
            unit: unitSettings.unit,
            distanceMeters: currentDistanceMeters,
            screenshotPath: screenshotPath,
            quality: quality
        )
        storage.append(record)
        statusMessage = "已保存到测量历史"
    }

    func startRoomScan() {
        guard mode == .roomScan else { return }
        roomPlanService.start()
        statusMessage = "正在扫描房间，缓慢移动手机"
    }

    func stopRoomScan() {
        roomPlanService.stop()
        if let measurement = roomPlanService.measurements.first {
            currentDimensions = measurement.dimensions
            automaticLabel = measurement.category
            statusMessage = "RoomPlan 已识别：\(measurement.category)"
        }
    }

    private func modeDidChange(oldValue: MeasurementMode) {
        guard oldValue != mode else { return }
        clearMeasurement()
        if oldValue == .roomScan { roomPlanService.stop() }
        if mode == .roomScan { startRoomScan() }
    }

    private func process(frame: ARFrame) {
        guard mode == .automatic else { return }
        guard let depthSample = DepthProvider.centerSample(from: frame) else {
            statusMessage = capabilities.hasLiDAR ? "正在等待深度数据" : "当前设备不支持 LiDAR，自动三维测量受限"
            return
        }

        let vision = visionPipeline.analyze(frame: frame)
        automaticLabel = vision?.observation?.identifier
        let roi: CGRect?
        if let selectionRect, viewportSize.width > 0, viewportSize.height > 0 {
            roi = CGRect(
                x: selectionRect.minX / viewportSize.width,
                y: selectionRect.minY / viewportSize.height,
                width: selectionRect.width / viewportSize.width,
                height: selectionRect.height / viewportSize.height
            )
        } else if let box = vision?.observation?.boundingBox {
            roi = CGRect(x: box.minX, y: 1 - box.maxY, width: box.width, height: box.height)
        } else {
            roi = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        }

        let band = pointCloudBuilder.foregroundBand(around: depthSample.depth)
        let points = pointCloudBuilder.build(from: frame, configuration: .init(
            stride: 5,
            minimumConfidence: 0.5,
            depthBand: band,
            roi: roi
        ))
        sessionManager.setPointCount(points.count)
        // ARKit's world coordinate system is gravity-aligned for the default
        // world-tracking configuration, so world Y is the stable height axis.
        guard let box = MeasurementGeometry.orientedBoundingBox(for: points, gravity: SIMD3(0, 1, 0)) else {
            statusMessage = "没有足够的有效点，请调整距离或框选物体"
            quality = .evaluate(
                trackingState: sessionManager.trackingState,
                depthConfidence: depthSample.confidence,
                pointCount: points.count,
                distanceMeters: depthSample.depth,
                stability: smoother.stabilityScore
            )
            return
        }

        currentDimensions = smoother.add(box.dimensions)
        let stable = smoother.isStable
        statusMessage = stable ? "测量稳定" : "请保持手机稳定"
        quality = .evaluate(
            trackingState: sessionManager.trackingState,
            depthConfidence: depthSample.confidence,
            pointCount: points.count,
            distanceMeters: depthSample.depth,
            stability: smoother.stabilityScore
        )
        sessionManager.renderer.showBoundingBox(box)
    }
}
