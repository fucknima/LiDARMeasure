import Foundation
import Combine
import RoomPlan
import simd
import SwiftUI

@available(iOS 17.0, *)
@MainActor
final class RoomPlanService: NSObject, ObservableObject, RoomCaptureSessionDelegate {
    let session = RoomCaptureSession()

    @Published private(set) var measurements: [RoomPlanMeasurement] = []
    @Published private(set) var isScanning = false
    @Published private(set) var lastError: String?

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        guard RoomCaptureSession.isSupported else {
            lastError = "当前设备不支持 RoomPlan"
            return
        }
        session.run(configuration: RoomCaptureSession.Configuration())
        isScanning = true
        lastError = nil
    }

    func stop() {
        session.stop()
        isScanning = false
    }

    func reset() {
        measurements.removeAll()
        lastError = nil
    }

    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        update(room)
    }

    func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {
        update(room)
    }

    func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
        update(room)
    }

    func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {
        // `didRemove` contains only the removed subset. Keep the latest full
        // snapshot from `didUpdate` instead of replacing it with that subset.
    }

    private func update(_ room: CapturedRoom) {
        measurements = room.objects.map { object in
            let dimensions = MeasurementDimensions(
                width: abs(object.dimensions.x),
                height: abs(object.dimensions.y),
                depth: abs(object.dimensions.z)
            )
            return RoomPlanMeasurement(
                category: String(describing: object.category),
                dimensions: dimensions,
                transform: object.transform
            )
        }
    }
}

@available(iOS 17.0, *)
struct RoomCaptureViewContainer: UIViewRepresentable {
    @ObservedObject var service: RoomPlanService

    func makeUIView(context: Context) -> RoomCaptureView {
        let view = RoomCaptureView(frame: .zero)
        view.captureSession = service.session
        return view
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}
}
