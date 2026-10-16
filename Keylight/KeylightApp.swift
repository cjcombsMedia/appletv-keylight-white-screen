import SwiftUI

@main
struct KeylightApp: App {
    @State private var store = LightStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}
