import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject private var store: BudgetStore

    @State private var isAddingExpense = false
    @State private var editingExpense: Expense?
    @State private var expensePendingDeletion: Expense?

    private var spendableCategories: [ExpenseCategory] {
        store.sortedCategories.filter { $0.destination.isExpense }
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            if store.expenses.isEmpty {
                ContentUnavailableView(
                    "Расходов пока нет",
                    systemImage: "cart",
                    description: Text("Распределите зарплату или добавьте разовый расход")
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(spendableCategories) { category in
                        let items = store.expenses(in: category)
                        if !items.isEmpty {
                            CategorySection(
                                category: category,
                                items: items,
                                onEdit: { expense in editingExpense = expense },
                                onDelete: { expense in expensePendingDeletion = expense }
                            )
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding()
        .navigationTitle(AppSection.expenses.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingExpense = true
                } label: {
                    Label(Strings.Common.add, systemImage: "plus")
                }
                .disabled(spendableCategories.isEmpty)
            }
        }
        .sheet(isPresented: $isAddingExpense) {
            ExpenseEditorSheet(mode: .add) { expense in
                store.addExpense(expense)
            }
        }
        .sheet(item: $editingExpense) { expense in
            ExpenseEditorSheet(mode: .edit(expense)) { updated in
                store.updateExpense(updated)
            }
        }
        .confirmationDialog(
            "Удалить расход?",
            isPresented: Binding(
                get: { expensePendingDeletion != nil },
                set: { if !$0 { expensePendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: expensePendingDeletion
        ) { expense in
            Button(Strings.Common.delete, role: .destructive) {
                store.deleteExpense(expense)
                expensePendingDeletion = nil
            }
            Button(Strings.Common.cancel, role: .cancel) {
                expensePendingDeletion = nil
            }
        }
    }

    private var header: some View {
        HStack {
            Text("\(AppSection.expenses.emoji) \(AppSection.expenses.title)")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Всего потрачено")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MoneyView(money: store.totalExpenses, primaryFont: .title2, primaryWeight: .bold, primaryColor: .red)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct CategorySection: View {
    @EnvironmentObject private var store: BudgetStore
    let category: ExpenseCategory
    let items: [Expense]
    let onEdit: (Expense) -> Void
    let onDelete: (Expense) -> Void

    private var spent: Money {
        store.totalSpent(in: category)
    }

    private var overBudget: Bool {
        category.plannedAmount.amount > 0 && spent.amount > category.plannedAmount.amount
    }

    var body: some View {
        Section {
            ForEach(items) { expense in
                ExpenseRow(expense: expense)
                    .contextMenu {
                        if expense.paycheckId == nil {
                            Button("Изменить", systemImage: "pencil") { onEdit(expense) }
                            Button(Strings.Common.delete, systemImage: "trash", role: .destructive) {
                                onDelete(expense)
                            }
                        } else {
                            Text("Связано с зарплатой — управляется на экране «Зарплаты»")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if expense.paycheckId == nil {
                            Button(role: .destructive) {
                                onDelete(expense)
                            } label: {
                                Label(Strings.Common.delete, systemImage: "trash")
                            }
                            Button {
                                onEdit(expense)
                            } label: {
                                Label("Изменить", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
            }
        } header: {
            HStack(spacing: 8) {
                Text(category.emoji)
                Text(category.name)
                    .fontWeight(.semibold)
                Spacer()
                MoneyView(money: spent, primaryFont: .body, primaryWeight: .semibold, primaryColor: overBudget ? .red : .primary, showConversion: false)
                if category.plannedAmount.amount > 0 {
                    Text("/")
                        .foregroundStyle(.secondary)
                    MoneyView(money: category.plannedAmount, primaryFont: .caption, primaryColor: .secondary, showConversion: false)
                }
            }
            .textCase(nil)
        }
    }
}

private struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.name)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    if expense.paycheckId != nil {
                        Text("·")
                        Label("из зарплаты", systemImage: "link")
                            .labelStyle(.titleAndIcon)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            MoneyView(money: expense.amount, primaryFont: .body, primaryWeight: .bold, primaryColor: .red)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        ExpensesView()
            .environmentObject(BudgetStore.preview)
    }
}
