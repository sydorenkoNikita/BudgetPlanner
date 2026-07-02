import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var store: BudgetStore

    @State private var editingGoal: Goal?
    @State private var isAddingGoal = false
    @State private var goalPendingDeletion: Goal?
    @State private var selectedGoal: Goal?
    @State private var topUpGoal: Goal?

    var body: some View {
        VStack(spacing: 16) {
            header

            if store.goals.isEmpty {
                ContentUnavailableView(
                    "Целей пока нет",
                    systemImage: "target",
                    description: Text("Создайте цель, чтобы откладывать к ней с зарплаты")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.sortedGoals) { goal in
                            GoalCard(
                                goal: goal,
                                onOpen: { selectedGoal = goal },
                                onTopUp: { topUpGoal = goal },
                                onEdit: { editingGoal = goal },
                                onDelete: { goalPendingDeletion = goal }
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle(AppSection.goals.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingGoal = true
                } label: {
                    Label("Добавить", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingGoal) {
            GoalEditorSheet(mode: .add) { goal in
                store.addGoal(goal)
            }
        }
        .sheet(item: $editingGoal) { goal in
            GoalEditorSheet(mode: .edit(goal)) { updated in
                store.updateGoal(updated)
            }
        }
        .sheet(item: $selectedGoal) { goal in
            GoalDetailSheet(goal: goal)
        }
        .sheet(item: $topUpGoal) { goal in
            GoalContributionSheet(goal: goal) { contribution in
                store.addGoalContribution(contribution)
            }
        }
        .confirmationDialog(
            "Удалить цель?",
            isPresented: Binding(
                get: { goalPendingDeletion != nil },
                set: { if !$0 { goalPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: goalPendingDeletion
        ) { goal in
            Button("Удалить", role: .destructive) {
                store.deleteGoal(goal)
                goalPendingDeletion = nil
            }
            Button("Отмена", role: .cancel) {
                goalPendingDeletion = nil
            }
        } message: { _ in
            Text("История пополнений будет удалена; категории, направленные на эту цель, переключатся на обычный расход.")
        }
    }

    private var header: some View {
        HStack {
            Text("\(AppSection.goals.emoji) \(AppSection.goals.title)")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Всего накоплено")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MoneyView(money: store.goalsTotal, primaryFont: .title2, primaryWeight: .bold, primaryColor: .blue)
            }
        }
        .padding()
        .background(AppSection.goals.color.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct GoalCard: View {
    @EnvironmentObject private var store: BudgetStore
    let goal: Goal
    let onOpen: () -> Void
    let onTopUp: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(goal.emoji)
                    .font(.title)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    HStack(spacing: 4) {
                        MoneyView(money: progress, primaryFont: .body, primaryWeight: .semibold, primaryColor: .blue, showConversion: false)
                        Text("из")
                            .foregroundStyle(.secondary)
                        MoneyView(money: goal.target, primaryFont: .body, primaryColor: .secondary, showConversion: false)
                    }
                }
                Spacer()
                Text("\(Int(percent * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                Menu {
                    Button("Открыть", systemImage: "arrow.up.right.square", action: onOpen)
                    Button("Изменить", systemImage: "pencil", action: onEdit)
                    Button("Удалить", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            ProgressView(value: percent)
                .tint(.blue)

            HStack {
                Label {
                    HStack(spacing: 4) {
                        Text("план:")
                        MoneyView(money: goal.monthlyPlan, primaryFont: .caption, primaryColor: .secondary, showConversion: false)
                        Text("/мес")
                    }
                } icon: {
                    Image(systemName: "calendar.badge.clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                if let projectedDate {
                    Label("к \(projectedDate.formatted(.dateTime.month(.wide).year()))", systemImage: "flag.checkered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if percent >= 1 {
                    Label("Достигнута 🎉", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            HStack(spacing: 8) {
                Button {
                    onTopUp()
                } label: {
                    Label("Пополнить", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onOpen()
                } label: {
                    Label("Детали и история", systemImage: "list.bullet.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        GoalsView()
            .environmentObject(BudgetStore.preview)
    }
}
