import SwiftUI

@main
struct MoyaHogushiApp: App {
    @StateObject private var store = MoyaStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
        }
    }
}
