import SwiftUI

@main
struct LiDARMeasureApp: App {
    @StateObject private var model = MeasureViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .preferredColorScheme(.dark)
        }
    }
}

