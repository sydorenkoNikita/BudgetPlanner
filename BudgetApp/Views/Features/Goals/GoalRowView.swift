import SwiftUI

struct GoalRowView: View {
    let goal: Goal
    @EnvironmentObject private var store: BudgetStore

    private var percent: Double { store.progressPercent(for: goal) }

    var body: some View {
        HStack(spacing: 12) {
            Text(goal.emoji)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.body)
                ProgressView(value: percent)
                    .tint(.blue)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                MoneyView(money: store.display(store.progress(for: goal)), primaryFont: .body, primaryWeight: .semibold, primaryColor: .blue, showConversion: false)
                Text("\(Int(percent * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppConfig.UI.listItemPadding)
    }
}

#if DEBUG
struct GoalRowView_Previews: PreviewProvider {
    static var previews: some View {
        GoalRowView(
            goal: Goal(name: "Машина", target: .uah(800_000), monthlyPlan: .uah(25000))
        )
        .environmentObject(BudgetStore.preview)
    }
}
#endif
