import SwiftUI

@main
struct MoyaHogushiApp: App {
    @StateObject private var store = MoyaStore()
    @StateObject private var purchase = PurchaseManager()
    @StateObject private var reminder = ReminderManager()

    init() {
        PurchaseManager.configure()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(purchase)
                .environmentObject(reminder)
                .task {
                    await purchase.start()
                    if purchase.isLoaded && !purchase.isPro {
                        await reminder.disableBecauseNotPro()
                    }
                }
                .onChange(of: purchase.isPro) { isPro in
                    guard !isPro, purchase.isLoaded else { return }
                    Task { await reminder.disableBecauseNotPro() }
                }
        }
    }
}
