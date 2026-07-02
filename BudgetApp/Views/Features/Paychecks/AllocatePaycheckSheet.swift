import SwiftUI

private struct RemainderOption: Hashable, Identifiable {
    let id: String
    let title: String
    let destination: AllocationDestination?
}

struct AllocatePaycheckSheet: View {
    let paycheck: Paycheck
    var isEditingExisting: Bool = false

    @EnvironmentObject private var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    @State private var amounts: [UUID: String] = [:]
    @State private var remainderSelection: String = "none"
    @State private var didPrefill = false

    private var paycheckCurrency: Currency { paycheck.amount.currency }

    private var allocatedSum: Double {
        store.sortedCategories.reduce(0) { sum, category in
            sum + (CurrencyFormatter.parse(amounts[category.id] ?? "") ?? 0)
        }
    }

    private var remainder: Double {
        paycheck.amount.amount - allocatedSum
    }

    private var isOverBudget: Bool {
        remainder < -0.5
    }

    private var remainderOptions: [RemainderOption] {
        var options: [RemainderOption] = [
            RemainderOption(id: "none", title: "Оставить на руках", destination: nil)
        ]
        for goal in store.sortedGoals {
            options.append(
                RemainderOption(
                    id: "goal-\(goal.id)",
                    title: "🎯 Цель: \(goal.name)",
                    destination: .goal(goal.id)
                )
            )
        }
        for asset in store.sortedAssets where !asset.kind.isPotential {
            options.append(
                RemainderOption(
                    id: "asset-\(asset.id)",
                    title: "\(asset.emoji) Актив: \(asset.name)",
                    destination: .asset(asset.id)
                )
            )
        }
        return options
    }

    private var selectedDestination: AllocationDestination? {
        remainderOptions.first { $0.id == remainderSelection }?.destination
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(store.sortedCategories) { category in
                        CategoryAllocationRow(
                            category: category,
                            paycheckCurrency: paycheckCurrency,
                            text: bindingForCategory(category)
                        )
                    }
                }
                .padding()
            }

            Divider()

            footer

            Divider()

            HStack {
                Button("Отмена") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Сбросить к плану", action: resetToPlan)
                Button(isEditingExisting ? "Сохранить" : "Применить", action: apply)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isOverBudget)
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 700)
        .onAppear(perform: prefill)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(isEditingExisting ? "Изменить распределение" : "Распределение")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                MoneyView(money: paycheck.amount, primaryFont: .title3, primaryWeight: .bold, primaryColor: .green)
            }
            Text("\(paycheck.kind.emoji) \(paycheck.kind.title) · \(paycheck.date.formatted(date: .abbreviated, time: .omitted))\(paycheck.note.isEmpty ? "" : " · \(paycheck.note)")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var footer: some View {
        VStack(spacing: 12) {
            HStack {
                summaryColumn(
                    title: "Распределено",
                    money: Money(allocatedSum, paycheckCurrency),
                    color: .primary
                )
                Spacer()
                summaryColumn(
                    title: remainder >= 0 ? "Остаток" : "Перерасход",
                    money: Money(abs(remainder), paycheckCurrency),
                    color: remainder < 0 ? .red : (remainder > 0 ? .blue : .secondary)
                )
            }

            HStack {
                Text("Остаток отправить:")
                    .fontWeight(.medium)
                Picker("Куда", selection: $remainderSelection) {
                    ForEach(remainderOptions) { option in
                        Text(option.title).tag(option.id)
                    }
                }
                .labelsHidden()
                .disabled(remainder <= 0)
            }
        }
        .padding()
    }

    private func summaryColumn(title: String, money: Money, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            MoneyView(money: money, primaryFont: .title3, primaryWeight: .semibold, primaryColor: color)
        }
    }

    private func bindingForCategory(_ category: ExpenseCategory) -> Binding<String> {
        Binding(
            get: { amounts[category.id] ?? "" },
            set: { amounts[category.id] = $0 }
        )
    }

    private func prefill() {
        guard !didPrefill else { return }
        didPrefill = true
        if isEditingExisting {
            let extracted = store.extractAllocation(paycheckId: paycheck.id)
            var next: [UUID: String] = [:]
            for category in store.sortedCategories {
                if let value = extracted.items[category.id], value > 0 {
                    next[category.id] = String(format: "%.0f", value)
                } else {
                    next[category.id] = ""
                }
            }
            amounts = next
            if let destination = extracted.remainderDestination {
                switch destination {
                case .asset(let id):
                    remainderSelection = "asset-\(id)"
                case .goal(let id):
                    remainderSelection = "goal-\(id)"
                case .expense:
                    remainderSelection = "none"
                }
            } else {
                remainderSelection = "none"
            }
        } else {
            resetToPlan()
            if let firstGoal = store.sortedGoals.first {
                remainderSelection = "goal-\(firstGoal.id)"
            } else if let firstAsset = store.sortedAssets.first(where: { !$0.kind.isPotential }) {
                remainderSelection = "asset-\(firstAsset.id)"
            }
        }
    }

    private func resetToPlan() {
        var next: [UUID: String] = [:]
        for category in store.sortedCategories {
            let planned = category.plannedAmount
                .converted(to: paycheckCurrency, uahPerUsd: store.exchangeRate.uahPerUsd)
            next[category.id] = planned.amount > 0
                ? String(format: "%.0f", planned.amount)
                : ""
        }
        amounts = next
    }

    private func apply() {
        let items = store.sortedCategories.map { category in
            AllocationItem(
                categoryId: category.id,
                amount: CurrencyFormatter.parse(amounts[category.id] ?? "") ?? 0,
                currency: paycheckCurrency
            )
        }
        if isEditingExisting {
            store.reallocate(
                paycheckId: paycheck.id,
                items: items,
                remainderDestination: remainder > 0 ? selectedDestination : nil
            )
        } else {
            store.allocate(
                paycheckId: paycheck.id,
                items: items,
                remainderDestination: remainder > 0 ? selectedDestination : nil
            )
        }
        dismiss()
    }
}

private struct CategoryAllocationRow: View {
    @EnvironmentObject private var store: BudgetStore
    let category: ExpenseCategory
    let paycheckCurrency: Currency
    @Binding var text: String

    private var convertedToDestination: Money? {
        guard let amount = CurrencyFormatter.parse(text), amount > 0 else { return nil }
        let money = Money(amount, paycheckCurrency)
        switch category.destination {
        case .expense:
            return nil
        case .asset(let id):
            guard let target = store.asset(id: id)?.money.currency, target != paycheckCurrency else { return nil }
            return money.converted(to: target, uahPerUsd: store.exchangeRate.uahPerUsd)
        case .goal(let id):
            guard let target = store.goal(id: id)?.target.currency, target != paycheckCurrency else { return nil }
            return money.converted(to: target, uahPerUsd: store.exchangeRate.uahPerUsd)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(category.emoji)
                .font(.title2)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(category.name)
                        .fontWeight(.medium)
                    Text("· \(store.destinationLabel(category.destination))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Text("план:")
                    MoneyView(money: category.plannedAmount, primaryFont: .caption, primaryColor: .secondary, showConversion: false)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    TextField("0", text: $text)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                    Text(paycheckCurrency.symbol)
                        .foregroundStyle(.secondary)
                }
                if let converted = convertedToDestination {
                    Text("≈ \(CurrencyFormatter.string(converted))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    AllocatePaycheckSheet(
        paycheck: Paycheck(kind: .advance, amount: .uah(89200), note: "Июнь")
    )
    .environmentObject(BudgetStore.preview)
}
