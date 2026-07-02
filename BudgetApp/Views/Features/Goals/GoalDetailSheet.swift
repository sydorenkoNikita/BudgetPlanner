import SwiftUI

struct GoalDetailSheet: View {
    let goal: Goal

    @EnvironmentObject private var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    @State private var editingContribution: GoalContribution?
    @State private var contributionPendingDeletion: GoalContribution?

    private var contributions: [GoalContribution] {
        store.contributions(for: goal)
    }

    private var progress: Money { store.progress(for: goal) }
    private var percent: Double { store.progressPercent(for: goal) }

    private var monthsLeft: Int? {
        let remaining = goal.target.amount - progress.amount
        let monthly = goal.monthlyPlan.converted(to: goal.target.currency, uahPerUsd: store.exchangeRate.uahPerUsd).amount
        guard remaining > 0, monthly > 0 else { return nil }
        return Int((remaining / monthly).rounded(.up))
    }

    private var projectedDate: Date? {
        guard let months = monthsLeft else { return nil }
        return Calendar.current.date(byAdding: .month, value: months, to: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text(goal.emoji)
                    .font(.system(size: 40))
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.title)
                        .fontWeight(.bold)
                    HStack(spacing: 4) {
                        MoneyView(money: progress, primaryFont: .title3, primaryWeight: .semibold, primaryColor: .blue, showConversion: false)
                        Text("из")
                            .foregroundStyle(.secondary)
                        MoneyView(money: goal.target, primaryFont: .title3, primaryColor: .secondary, showConversion: false)
                    }
                    ProgressView(value: percent)
                        .tint(.blue)
                }
                Spacer()
                Button(Strings.Common.close) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            HStack(spacing: 12) {
                infoCard(title: "Прогресс", value: "\(Int(percent * 100))%", color: .blue)
                infoCard(title: "Осталось", value: formattedRemaining, color: .orange)
                infoCard(title: "План/мес", value: CurrencyFormatter.string(goal.monthlyPlan), color: .green)
                if let projectedDate {
                    infoCard(title: "Прогноз", value: projectedDate.formatted(.dateTime.month(.wide).year()), color: .purple)
                }
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("История пополнений")
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top, 8)

                if contributions.isEmpty {
                    ContentUnavailableView(
                        "Пока пусто",
                        systemImage: "tray",
                        description: Text("Распределите зарплату или пополните вручную")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(contributions) { contribution in
                            ContributionRow(contribution: contribution)
                                .contextMenu {
                                    if contribution.paycheckId == nil {
                                        Button("Изменить", systemImage: "pencil") {
                                            editingContribution = contribution
                                        }
                                        Button(Strings.Common.delete, systemImage: "trash", role: .destructive) {
                                            contributionPendingDeletion = contribution
                                        }
                                    } else {
                                        Text("Связано с зарплатой — управляется на экране «Зарплаты»")
                                    }
                                }
                        }
                    }
                    .listStyle(.inset)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .sheet(item: $editingContribution) { contribution in
            GoalContributionSheet(
                goal: goal,
                editing: contribution
            ) { updated in
                store.updateGoalContribution(updated)
            }
        }
        .confirmationDialog(
            "Удалить пополнение?",
            isPresented: Binding(
                get: { contributionPendingDeletion != nil },
                set: { if !$0 { contributionPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: contributionPendingDeletion
        ) { contribution in
            Button(Strings.Common.delete, role: .destructive) {
                store.deleteGoalContribution(contribution)
                contributionPendingDeletion = nil
            }
            Button(Strings.Common.cancel, role: .cancel) {
                contributionPendingDeletion = nil
            }
        }
    }

    private var formattedRemaining: String {
        let remaining = max(goal.target.amount - progress.amount, 0)
        return CurrencyFormatter.string(Money(remaining, goal.target.currency))
    }

    private func infoCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

private struct ContributionRow: View {
    let contribution: GoalContribution

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(contribution.source)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(contribution.date.formatted(date: .abbreviated, time: .omitted))
                    if contribution.paycheckId != nil && contribution.categoryId == nil {
                        Text("·")
                        Label("остаток зарплаты", systemImage: "tray.fill")
                            .labelStyle(.titleAndIcon)
                    } else if contribution.paycheckId != nil {
                        Text("·")
                        Label("из зарплаты", systemImage: "link")
                            .labelStyle(.titleAndIcon)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            MoneyView(money: contribution.amount, primaryFont: .body, primaryWeight: .bold, primaryColor: .blue)
        }
        .padding(.vertical, 2)
    }
}

struct GoalContributionSheet: View {
    let goal: Goal
    var editing: GoalContribution?
    let onSave: (GoalContribution) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String
    @State private var currency: Currency
    @State private var date: Date
    @State private var source: String

    private let editingId: UUID?

    init(goal: Goal, editing: GoalContribution? = nil, onSave: @escaping (GoalContribution) -> Void) {
        self.goal = goal
        self.editing = editing
        self.onSave = onSave
        if let editing {
            _amountText = State(initialValue: String(format: "%.0f", editing.amount.amount))
            _currency = State(initialValue: editing.amount.currency)
            _date = State(initialValue: editing.date)
            _source = State(initialValue: editing.source)
            editingId = editing.id
        } else {
            _amountText = State(initialValue: "")
            _currency = State(initialValue: goal.target.currency)
            _date = State(initialValue: Date())
            _source = State(initialValue: "")
            editingId = nil
        }
    }

    private var isValid: Bool {
        CurrencyFormatter.parsePositive(amountText) != nil &&
        !source.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(goal.emoji) \(goal.name)")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section("Сумма") {
                    MoneyField(amountText: $amountText, currency: $currency)
                }

                Section("Откуда") {
                    TextField("Например: подарок, бонус", text: $source)
                }

                Section(Strings.Forms.date) {
                    DatePicker(Strings.Forms.date, selection: $date, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            .formStyle(.grouped)

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
        .frame(minWidth: 460, minHeight: 460)
    }

    private func save() {
        guard let amount = CurrencyFormatter.parsePositive(amountText) else { return }
        let contribution = GoalContribution(
            id: editingId ?? UUID(),
            goalId: goal.id,
            amount: Money(amount, currency),
            date: date,
            source: source.trimmingCharacters(in: .whitespaces),
            paycheckId: nil
        )
        onSave(contribution)
        dismiss()
    }
}

#Preview {
    GoalDetailSheet(goal: Goal(name: "Машина", target: .uah(800_000), monthlyPlan: .uah(25000)))
        .environmentObject(BudgetStore.preview)
}
