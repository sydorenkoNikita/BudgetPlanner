# Task 7: Update ContentView to Import from New Locations

## Overview
Update the main ContentView to use centralized strings and import views from their new feature-folder locations.

## Exact Modifications

### Replace BudgetApp/ContentView.swift
New content from plan lines 551-579:

```swift
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
```

All strings use `Strings.ContentView.*` — no hardcoded text.

## Success Criteria
- ContentView.swift updated with exact content from plan
- Compiles without errors
- All view imports resolve correctly (views should be in feature folders by this point)
- Single commit: "refactor: update ContentView to use Strings and new view imports"

## Dependencies
- Task 2 (Strings.swift) complete
- Task 6 (Assets views moved) complete
- Other feature views should be moved (Tasks 8-10) before this compiles fully

## Note
This task may have import issues if other feature views haven't been moved yet. That's fine — compile errors about missing view imports mean later tasks are not yet complete.

## Steps from Plan
See lines 539-579 of the implementation plan.
