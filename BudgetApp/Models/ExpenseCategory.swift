import Foundation

enum AllocationDestination: Hashable {
    case expense
    case asset(UUID)
    case goal(UUID)

    var isExpense: Bool {
        if case .expense = self { return true }
        return false
    }
}

struct ExpenseCategory: Identifiable, Hashable {
    let id: UUID
    var name: String
    var emoji: String
    var plannedAmount: Money
    var destination: AllocationDestination
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String = "📦",
        plannedAmount: Money = .zeroUAH,
        destination: AllocationDestination = .expense,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.plannedAmount = plannedAmount
        self.destination = destination
        self.sortOrder = sortOrder
    }
}
