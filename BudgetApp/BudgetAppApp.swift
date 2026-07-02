import SwiftUI

@main
struct BudgetApp: App {
    @StateObject private var store = BudgetStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 760, minHeight: 600)
        }
    }
}
