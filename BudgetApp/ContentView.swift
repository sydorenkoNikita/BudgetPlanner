import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: BudgetStore
    @State private var selectedSection: AppSection? = .paychecks

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSection: $selectedSection)
        } detail: {
            switch selectedSection {
            case .paychecks:
                PaychecksView()
            case .expenses:
                ExpensesView()
            case .assets:
                AssetsView()
            case .goals:
                GoalsView()
            case .forecast:
                ForecastView()
            case .categories:
                CategoriesView()
            case .settings:
                SettingsView()
            case .none:
                ContentUnavailableView(
                    "Выберите раздел",
                    systemImage: "sidebar.left",
                    description: Text("Откройте раздел в боковой панели")
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BudgetStore.preview)
}
