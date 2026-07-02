import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    @EnvironmentObject private var store: BudgetStore

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.name)
                    .font(.body)
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            MoneyView(money: store.display(expense.amount), primaryFont: .body, primaryWeight: .bold, primaryColor: .red)
        }
        .padding(AppConfig.UI.listItemPadding)
    }
}

#if DEBUG
struct ExpenseRowView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseRowView(
            expense: Expense(categoryId: UUID(), name: "Продукты", amount: .uah(1200))
        )
        .environmentObject(BudgetStore.preview)
    }
}
#endif
