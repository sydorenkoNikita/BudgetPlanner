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
