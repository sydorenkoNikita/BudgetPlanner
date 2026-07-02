# Task 3: Create Configuration System (AppConfig.swift)

## Overview
Extract all hardcoded UI constants, defaults, and formatting rules into a centralized `AppConfig` struct. Also update `BudgetStore` to use the new config defaults.

## Exact Deliverable

Create file: `BudgetApp/Config/AppConfig.swift` with:

```swift
struct AppConfig {
    struct UI {
        static let windowMinWidth: CGFloat = 760
        static let windowMinHeight: CGFloat = 600
        static let listItemSpacing: CGFloat = 8
        static let listItemPadding: CGFloat = 12
        static let sectionSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let buttonCornerRadius: CGFloat = 6
        static let defaultListRowHeight: CGFloat = 50
    }
    
    struct Defaults {
        static let displayCurrency: Currency = .uah
        static let exchangeRateDefault: Double = 1.0
        static let defaultCategories: [ExpenseCategory] = [
            // 6 categories as specified in plan lines 288-347
        ]
    }
    
    struct Formatting {
        static let currencyDecimalPlaces: Int = 2
        static let dateFormat: String = "dd.MM.yyyy"
        static let monthDateFormat: String = "LLLL"
    }
    
    struct Forecast {
        static let defaultMonthsAhead: Int = 12
    }
}
```

All exact values must match the plan (lines 265-353).

## Also Modify
In `BudgetApp/Stores/BudgetStore.swift`, find the `seedDefaults()` method (around line 544) and replace:

Old:
```swift
private func seedDefaults() {
    categories = [
        ExpenseCategory(name: "Бронь", emoji: "🛡", ...),
        ...
    ]
}
```

New:
```swift
private func seedDefaults() {
    categories = AppConfig.Defaults.defaultCategories
}
```

## Success Criteria
- AppConfig.swift created with all exact values from plan
- Compiles without errors
- BudgetStore.seedDefaults() updated to use AppConfig.Defaults.defaultCategories
- Single commit: "feat: add configuration system and use defaults from AppConfig"

## Dependencies
- Task 2 must be complete (Strings.swift exists and compiles)
- Note: AppConfig.Defaults.defaultCategories references Strings.Categories.* values, so Strings must exist first

## Steps from Plan
See lines 250-393 of the implementation plan.
