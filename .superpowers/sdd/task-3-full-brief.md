# Task 3: Create Configuration System (AppConfig.swift) - FULL CONTENT

## Overview
Extract all hardcoded UI constants, defaults, and formatting rules into a centralized `AppConfig` struct.

## Create BudgetApp/Config/AppConfig.swift

Copy this exact content:

```swift
import SwiftUI

struct AppConfig {
    // MARK: - UI Constants
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
    
    // MARK: - Defaults
    struct Defaults {
        static let displayCurrency: Currency = .uah
        static let exchangeRateDefault: Double = 1.0
        
        // Default expense categories
        static let defaultCategories: [ExpenseCategory] = [
            ExpenseCategory(
                name: Strings.Categories.reserve,
                emoji: "🛡",
                plannedAmount: .uah(13200),
                destination: .expense,
                sortOrder: 0
            ),
            ExpenseCategory(
                name: Strings.Categories.apartment,
                emoji: "🏠",
                plannedAmount: .uah(20000),
                destination: .expense,
                sortOrder: 1
            ),
            ExpenseCategory(
                name: Strings.Categories.mom,
                emoji: "👩",
                plannedAmount: .uah(5000),
                destination: .expense,
                sortOrder: 2
            ),
            ExpenseCategory(
                name: Strings.Categories.foodAndOutings,
                emoji: "🍔",
                plannedAmount: .uah(14000),
                destination: .expense,
                sortOrder: 3
            ),
            ExpenseCategory(
                name: Strings.Categories.loans,
                emoji: "💳",
                plannedAmount: .uah(12000),
                destination: .expense,
                sortOrder: 4
            ),
            ExpenseCategory(
                name: Strings.Categories.savings,
                emoji: "🏦",
                plannedAmount: .uah(25000),
                destination: .expense,
                sortOrder: 5
            ),
        ]
    }
    
    // MARK: - Formatting
    struct Formatting {
        static let currencyDecimalPlaces: Int = 2
        static let dateFormat: String = "dd.MM.yyyy"
        static let monthDateFormat: String = "LLLL"
    }
    
    // MARK: - Forecast
    struct Forecast {
        static let defaultMonthsAhead: Int = 12
    }
}
```

## Modify BudgetApp/Stores/BudgetStore.swift

Find `seedDefaults()` method (around line 544) and replace entire method body:

OLD:
```swift
private func seedDefaults() {
    categories = [
        ExpenseCategory(name: "Бронь", emoji: "🛡", plannedAmount: .uah(13200), destination: .expense, sortOrder: 0),
        ExpenseCategory(name: "Квартира", emoji: "🏠", plannedAmount: .uah(20000), destination: .expense, sortOrder: 1),
        ExpenseCategory(name: "Маме", emoji: "👩", plannedAmount: .uah(5000), destination: .expense, sortOrder: 2),
        ExpenseCategory(name: "Еда / гульки", emoji: "🍔", plannedAmount: .uah(14000), destination: .expense, sortOrder: 3),
        ExpenseCategory(name: "Кредиты", emoji: "💳", plannedAmount: .uah(12000), destination: .expense, sortOrder: 4),
        ExpenseCategory(name: "Отложить", emoji: "🏦", plannedAmount: .uah(25000), destination: .expense, sortOrder: 5)
    ]
}
```

NEW:
```swift
private func seedDefaults() {
    categories = AppConfig.Defaults.defaultCategories
}
```

## Success Criteria
- AppConfig.swift created at correct path
- BudgetStore.seedDefaults() updated
- Both files compile without errors
- Single commit: "feat: add configuration system and use defaults from AppConfig"

## Dependencies
- Task 2 (Strings.swift) complete and compiles
