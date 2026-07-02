import Foundation

enum Currency: String, CaseIterable, Identifiable, Hashable {
    case uah
    case usd

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .uah: return "₴"
        case .usd: return "$"
        }
    }

    var code: String {
        rawValue.uppercased()
    }

    var title: String {
        switch self {
        case .uah: return "Гривна"
        case .usd: return "Доллар"
        }
    }
}
