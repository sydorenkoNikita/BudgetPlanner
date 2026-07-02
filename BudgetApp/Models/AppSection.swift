import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case paychecks
    case expenses
    case assets
    case goals
    case forecast
    case categories
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paychecks: return "Зарплаты"
        case .expenses: return "Расходы"
        case .assets: return "Активы"
        case .goals: return "Цели"
        case .forecast: return "Прогноз"
        case .categories: return "Категории"
        case .settings: return "Настройки"
        }
    }

    var icon: String {
        switch self {
        case .paychecks: return "dollarsign.circle.fill"
        case .expenses: return "cart.fill"
        case .assets: return "wallet.pass.fill"
        case .goals: return "target"
        case .forecast: return "chart.line.uptrend.xyaxis"
        case .categories: return "tag.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var color: Color {
        switch self {
        case .paychecks: return .green
        case .expenses: return .red
        case .assets: return .teal
        case .goals: return .blue
        case .forecast: return .purple
        case .categories: return .orange
        case .settings: return .gray
        }
    }

    var emoji: String {
        switch self {
        case .paychecks: return "💵"
        case .expenses: return "💸"
        case .assets: return "💼"
        case .goals: return "🎯"
        case .forecast: return "📈"
        case .categories: return "🗂"
        case .settings: return "⚙️"
        }
    }
}
