import Foundation

struct Goal: Identifiable, Hashable {
    let id: UUID
    var name: String
    var emoji: String
    var target: Money
    var monthlyPlan: Money
    var deadline: Date?
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String = "🎯",
        target: Money,
        monthlyPlan: Money,
        deadline: Date? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.target = target
        self.monthlyPlan = monthlyPlan
        self.deadline = deadline
        self.sortOrder = sortOrder
    }
}

struct GoalContribution: Identifiable, Hashable {
    let id: UUID
    var goalId: UUID
    var amount: Money
    var date: Date
    var source: String
    var paycheckId: UUID?
    /// Если пополнение из распределения зарплаты — связь с категорией.
    /// nil = «Остаток» или ручное пополнение.
    var categoryId: UUID?

    init(
        id: UUID = UUID(),
        goalId: UUID,
        amount: Money,
        date: Date = Date(),
        source: String,
        paycheckId: UUID? = nil,
        categoryId: UUID? = nil
    ) {
        self.id = id
        self.goalId = goalId
        self.amount = amount
        self.date = date
        self.source = source
        self.paycheckId = paycheckId
        self.categoryId = categoryId
    }
}
