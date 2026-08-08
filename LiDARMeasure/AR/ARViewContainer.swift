import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var sessionManager: ARSessionManager

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        sessionManager.attach(to: view)
        sessionManager.renderer.attach(to: view)
        sessionManager.start()
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if sessionManager.arView !== uiView {
            sessionManager.attach(to: uiView)
            sessionManager.renderer.attach(to: uiView)
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: ()) {
        uiView.session.pause()
    }
}
