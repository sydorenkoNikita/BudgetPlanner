import Foundation

struct Expense: Identifiable, Hashable {
    let id: UUID
    var categoryId: UUID
    var name: String
    var amount: Money
    var date: Date
    var paycheckId: UUID?
    var note: String?

    init(
        id: UUID = UUID(),
        categoryId: UUID,
        name: String,
        amount: Money,
        date: Date = Date(),
        paycheckId: UUID? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.categoryId = categoryId
        self.name = name
        self.amount = amount
        self.date = date
        self.paycheckId = paycheckId
        self.note = note
    }
}
