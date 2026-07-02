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
                    Strings.ContentView.selectSection,
                    systemImage: "sidebar.left",
                    description: Text(Strings.ContentView.selectSectionDescription)
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BudgetStore.preview)
}
