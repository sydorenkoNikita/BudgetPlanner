import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject private var store: BudgetStore

    @State private var editingCategory: ExpenseCategory?
    @State private var isAddingCategory = false
    @State private var categoryPendingDeletion: ExpenseCategory?

    private var totalPlanned: Money {
        let amount = store.categories.reduce(0.0) { acc, category in
            acc + store.convert(category.plannedAmount, to: store.displayCurrency).amount
        }
        return Money(amount, store.displayCurrency)
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            if store.categories.isEmpty {
                ContentUnavailableView(
                    "Категорий нет",
                    systemImage: "tag",
                    description: Text("Создайте категории, чтобы распределять зарплату по статьям")
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.sortedCategories) { category in
                        CategoryRow(category: category)
                            .contextMenu {
                                Button("Изменить", systemImage: "pencil") {
                                    editingCategory = category
                                }
                                Button(Strings.Common.delete, systemImage: "trash", role: .destructive) {
                                    categoryPendingDeletion = category
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    categoryPendingDeletion = category
                                } label: {
                                    Label(Strings.Common.delete, systemImage: "trash")
                                }
                                Button {
                                    editingCategory = category
                                } label: {
                                    Label("Изменить", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding()
        .navigationTitle(AppSection.categories.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingCategory = true
                } label: {
                    Label(Strings.Common.add, systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingCategory) {
            CategoryEditorSheet(mode: .add) { category in
                store.addCategory(category)
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorSheet(mode: .edit(category)) { updated in
                store.updateCategory(updated)
            }
        }
        .confirmationDialog(
            "Удалить категорию?",
            isPresented: Binding(
                get: { categoryPendingDeletion != nil },
                set: { if !$0 { categoryPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: categoryPendingDeletion
        ) { category in
            Button(Strings.Common.delete, role: .destructive) {
                store.deleteCategory(category)
                categoryPendingDeletion = nil
            }
            Button(Strings.Common.cancel, role: .cancel) {
                categoryPendingDeletion = nil
            }
        } message: { category in
            let count = store.expenses(in: category).count
            if count > 0 {
                Text("Будет удалено \(count) расход(ов), привязанных к этой категории.")
            } else {
                Text("Это действие нельзя отменить.")
            }
        }
    }

    private var header: some View {
        HStack {
            Text("\(AppSection.categories.emoji) \(AppSection.categories.title)")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("План на месяц")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MoneyView(money: totalPlanned, primaryFont: .title2, primaryWeight: .bold, primaryColor: .orange)
            }
        }
        .padding()
        .background(AppSection.categories.color.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct CategoryRow: View {
    @EnvironmentObject private var store: BudgetStore
    let category: ExpenseCategory

    var body: some View {
        HStack(spacing: 12) {
            Text(category.emoji)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(category.name)
                    .fontWeight(.medium)
                HStack(spacing: 6) {
                    Text("план:")
                        .foregroundStyle(.secondary)
                    MoneyView(money: category.plannedAmount, primaryFont: .caption, primaryColor: .secondary, showConversion: false)
                }
                .font(.caption)

                destinationBadge
            }

            Spacer()

            if category.destination.isExpense {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("потрачено")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    MoneyView(
                        money: store.totalSpent(in: category),
                        primaryFont: .caption,
                        primaryWeight: .semibold,
                        primaryColor: store.totalSpent(in: category).amount > category.plannedAmount.amount ? .red : .secondary,
                        showConversion: false
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var destinationBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: destinationIcon)
            Text(store.destinationLabel(category.destination))
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(destinationColor.opacity(0.12))
        .foregroundStyle(destinationColor)
        .cornerRadius(4)
    }

    private var destinationIcon: String {
        switch category.destination {
        case .expense: return "cart"
        case .asset: return "wallet.pass.fill"
        case .goal: return "target"
        }
    }

    private var destinationColor: Color {
        switch category.destination {
        case .expense: return .red
        case .asset: return .teal
        case .goal: return .blue
        }
    }
}

#Preview {
    NavigationStack {
        CategoriesView()
            .environmentObject(BudgetStore.preview)
    }
}
