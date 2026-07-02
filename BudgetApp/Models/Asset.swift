import SwiftUI

enum AssetKind: String, CaseIterable, Identifiable, Hashable {
    case cash       // прямой доступ — карта, наличные, у Маши
    case savings    // отдельная копилка, депозит
    case sellable   // имущество, продам — получу деньги
    case receivable // должники

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: return "Кошельки"
        case .savings: return "Копилка"
        case .sellable: return "Имущество"
        case .receivable: return "Долги мне"
        }
    }

    var icon: String {
        switch self {
        case .cash: return "creditcard.fill"
        case .savings: return "banknote.fill"
        case .sellable: return "shippingbox.fill"
        case .receivable: return "person.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .cash: return .green
        case .savings: return .blue
        case .sellable: return .purple
        case .receivable: return .orange
        }
    }

    /// Активы этого типа считаются «потенциальными» — деньгами, которые ещё не на руках.
    var isPotential: Bool {
        switch self {
        case .cash, .savings: return false
        case .sellable, .receivable: return true
        }
    }
}

struct Asset: Identifiable, Hashable {
    let id: UUID
    var name: String
    var emoji: String
    var kind: AssetKind
    var money: Money
    var monthlyPlan: Money
    var note: String
    var expectedDate: Date?
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String = "💼",
        kind: AssetKind,
        money: Money,
        monthlyPlan: Money? = nil,
        note: String = "",
        expectedDate: Date? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.kind = kind
        self.money = money
        self.monthlyPlan = monthlyPlan ?? Money(0, money.currency)
        self.note = note
        self.expectedDate = expectedDate
        self.sortOrder = sortOrder
    }
}

struct AssetMovement: Identifiable, Hashable {
    let id: UUID
    var assetId: UUID
    var delta: Money
    var date: Date
    var source: String
    var paycheckId: UUID?
    /// Если движение пришло из распределения зарплаты — связь с категорией.
    /// nil = пришло от «Остатка» или вручную.
    var categoryId: UUID?

    init(
        id: UUID = UUID(),
        assetId: UUID,
        delta: Money,
        date: Date = Date(),
        source: String,
        paycheckId: UUID? = nil,
        categoryId: UUID? = nil
    ) {
        self.id = id
        self.assetId = assetId
        self.delta = delta
        self.date = date
        self.source = source
        self.paycheckId = paycheckId
        self.categoryId = categoryId
    }
}
