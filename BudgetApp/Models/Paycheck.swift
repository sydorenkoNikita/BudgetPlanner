import Foundation

enum PaycheckKind: String, CaseIterable, Identifiable, Hashable {
    case advance
    case salary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .advance: return "Аванс"
        case .salary: return "Зарплата"
        }
    }

    var emoji: String {
        switch self {
        case .advance: return "💵"
        case .salary: return "💰"
        }
    }
}

struct Paycheck: Identifiable, Hashable {
    let id: UUID
    var kind: PaycheckKind
    var amount: Money
    var date: Date
    var note: String
    var isAllocated: Bool

    init(
        id: UUID = UUID(),
        kind: PaycheckKind,
        amount: Money,
        date: Date = Date(),
        note: String = "",
        isAllocated: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.amount = amount
        self.date = date
        self.note = note
        self.isAllocated = isAllocated
    }
}
