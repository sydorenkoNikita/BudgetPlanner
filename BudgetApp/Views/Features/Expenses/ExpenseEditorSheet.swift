import SwiftUI

struct ExpenseEditorSheet: View {
    enum Mode {
        case add
        case edit(Expense)
    }

    let mode: Mode
    let onSave: (Expense) -> Void

    @EnvironmentObject private var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    @State private var categoryId: UUID?
    @State private var name: String
    @State private var amountText: String
    @State private var currency: Currency
    @State private var date: Date

    private let editingId: UUID?
    private let paycheckId: UUID?

    init(mode: Mode, onSave: @escaping (Expense) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add:
            _categoryId = State(initialValue: nil)
            _name = State(initialValue: "")
            _amountText = State(initialValue: "")
            _currency = State(initialValue: .uah)
            _date = State(initialValue: Date())
            editingId = nil
            paycheckId = nil
        case .edit(let expense):
            _categoryId = State(initialValue: expense.categoryId)
            _name = State(initialValue: expense.name)
            _amountText = State(initialValue: String(format: "%.0f", expense.amount.amount))
            _currency = State(initialValue: expense.amount.currency)
            _date = State(initialValue: expense.date)
            editingId = expense.id
            paycheckId = expense.paycheckId
        }
    }

    private var spendableCategories: [ExpenseCategory] {
        store.sortedCategories.filter { $0.destination.isExpense }
    }

    private var isValid: Bool {
        categoryId != nil &&
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        CurrencyFormatter.parsePositive(amountText) != nil
    }

    private var title: String {
        switch mode {
        case .add: return "Новый расход"
        case .edit: return "Редактировать расход"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section("Категория") {
                    Picker("Категория", selection: $categoryId) {
                        Text("Не выбрана").tag(UUID?.none)
                        ForEach(spendableCategories) { category in
                            Text("\(category.emoji) \(category.name)").tag(Optional(category.id))
                        }
                    }
                    .labelsHidden()
                }

                Section("Описание") {
                    TextField("Например: продукты", text: $name)
                }

                Section("Сумма") {
                    MoneyField(amountText: $amountText, currency: $currency)
                }

                Section("Дата") {
                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            .formStyle(.grouped)
            .onAppear {
                if categoryId == nil {
                    categoryId = spendableCategories.first?.id
                }
            }

            Divider()

            HStack {
                Button(Strings.Common.cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(Strings.Common.save, action: save)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 520)
    }

    private func save() {
        guard let categoryId,
              let amount = CurrencyFormatter.parsePositive(amountText) else { return }
        let expense = Expense(
            id: editingId ?? UUID(),
            categoryId: categoryId,
            name: name.trimmingCharacters(in: .whitespaces),
            amount: Money(amount, currency),
            date: date,
            paycheckId: paycheckId
        )
        onSave(expense)
        dismiss()
    }
}

#Preview {
    ExpenseEditorSheet(mode: .add) { _ in }
        .environmentObject(BudgetStore.preview)
}
