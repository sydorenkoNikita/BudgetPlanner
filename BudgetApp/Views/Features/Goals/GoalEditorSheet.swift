import SwiftUI

struct GoalEditorSheet: View {
    enum Mode {
        case add
        case edit(Goal)
    }

    let mode: Mode
    let onSave: (Goal) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var targetText: String
    @State private var targetCurrency: Currency
    @State private var monthlyText: String
    @State private var monthlyCurrency: Currency
    @State private var hasDeadline: Bool
    @State private var deadline: Date

    private let editingId: UUID?
    private let sortOrder: Int

    init(mode: Mode, onSave: @escaping (Goal) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add:
            _name = State(initialValue: "")
            _emoji = State(initialValue: "🎯")
            _targetText = State(initialValue: "")
            _targetCurrency = State(initialValue: .uah)
            _monthlyText = State(initialValue: "")
            _monthlyCurrency = State(initialValue: .uah)
            _hasDeadline = State(initialValue: false)
            _deadline = State(initialValue: Date())
            editingId = nil
            sortOrder = 0
        case .edit(let goal):
            _name = State(initialValue: goal.name)
            _emoji = State(initialValue: goal.emoji)
            _targetText = State(initialValue: String(format: "%.0f", goal.target.amount))
            _targetCurrency = State(initialValue: goal.target.currency)
            _monthlyText = State(initialValue: String(format: "%.0f", goal.monthlyPlan.amount))
            _monthlyCurrency = State(initialValue: goal.monthlyPlan.currency)
            _hasDeadline = State(initialValue: goal.deadline != nil)
            _deadline = State(initialValue: goal.deadline ?? Date())
            editingId = goal.id
            sortOrder = goal.sortOrder
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        CurrencyFormatter.parsePositive(targetText) != nil
    }

    private var title: String {
        switch mode {
        case .add: return "Новая цель"
        case .edit: return "Редактировать цель"
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
                Section("Эмодзи и название") {
                    HStack {
                        TextField("🎯", text: $emoji)
                            .font(.title)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                        TextField("Например: Новая машина", text: $name)
                    }
                }

                Section("Целевая сумма") {
                    MoneyField(amountText: $targetText, currency: $targetCurrency)
                }

                Section("Откладывать в месяц") {
                    MoneyField(amountText: $monthlyText, currency: $monthlyCurrency)
                    Text("Используется в прогнозе — сколько накопится к будущим месяцам")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Дедлайн") {
                    Toggle("Установить дату", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker(Strings.Forms.date, selection: $deadline, displayedComponents: .date)
                            .labelsHidden()
                    }
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
        .frame(minWidth: 500, minHeight: 600)
    }

    private func save() {
        guard let target = CurrencyFormatter.parsePositive(targetText) else { return }
        let monthly = CurrencyFormatter.parse(monthlyText) ?? 0
        let goal = Goal(
            id: editingId ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji.trimmingCharacters(in: .whitespaces).isEmpty ? "🎯" : emoji.trimmingCharacters(in: .whitespaces),
            target: Money(target, targetCurrency),
            monthlyPlan: Money(monthly, monthlyCurrency),
            deadline: hasDeadline ? deadline : nil,
            sortOrder: sortOrder
        )
        onSave(goal)
        dismiss()
    }
}

#Preview {
    GoalEditorSheet(mode: .add) { _ in }
        .environmentObject(BudgetStore.preview)
}
