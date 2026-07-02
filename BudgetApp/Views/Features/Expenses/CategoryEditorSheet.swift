import SwiftUI

private enum DestinationKind: String, CaseIterable, Identifiable {
    case expense
    case asset
    case goal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: return "Расход"
        case .asset: return "Актив"
        case .goal: return "Цель"
        }
    }
}

struct CategoryEditorSheet: View {
    enum Mode {
        case add
        case edit(ExpenseCategory)
    }

    let mode: Mode
    let onSave: (ExpenseCategory) -> Void

    @EnvironmentObject private var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var plannedText: String
    @State private var plannedCurrency: Currency
    @State private var destinationKind: DestinationKind
    @State private var selectedAssetId: UUID?
    @State private var selectedGoalId: UUID?

    private let editingId: UUID?
    private let sortOrder: Int

    init(mode: Mode, onSave: @escaping (ExpenseCategory) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add:
            _name = State(initialValue: "")
            _emoji = State(initialValue: "📦")
            _plannedText = State(initialValue: "")
            _plannedCurrency = State(initialValue: .uah)
            _destinationKind = State(initialValue: .expense)
            _selectedAssetId = State(initialValue: nil)
            _selectedGoalId = State(initialValue: nil)
            editingId = nil
            sortOrder = 0
        case .edit(let category):
            _name = State(initialValue: category.name)
            _emoji = State(initialValue: category.emoji)
            _plannedText = State(initialValue: String(format: "%.0f", category.plannedAmount.amount))
            _plannedCurrency = State(initialValue: category.plannedAmount.currency)
            switch category.destination {
            case .expense:
                _destinationKind = State(initialValue: .expense)
                _selectedAssetId = State(initialValue: nil)
                _selectedGoalId = State(initialValue: nil)
            case .asset(let id):
                _destinationKind = State(initialValue: .asset)
                _selectedAssetId = State(initialValue: id)
                _selectedGoalId = State(initialValue: nil)
            case .goal(let id):
                _destinationKind = State(initialValue: .goal)
                _selectedAssetId = State(initialValue: nil)
                _selectedGoalId = State(initialValue: id)
            }
            editingId = category.id
            sortOrder = category.sortOrder
        }
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        switch destinationKind {
        case .expense: return true
        case .asset: return selectedAssetId != nil
        case .goal: return selectedGoalId != nil
        }
    }

    private var title: String {
        switch mode {
        case .add: return "Новая категория"
        case .edit: return "Редактировать категорию"
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
                        TextField("📦", text: $emoji)
                            .font(.title)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                        TextField("Например: Бронь", text: $name)
                    }
                }

                Section("Плановая сумма") {
                    MoneyField(amountText: $plannedText, currency: $plannedCurrency)
                }

                Section("Куда уходят деньги") {
                    Picker("Тип", selection: $destinationKind) {
                        ForEach(DestinationKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    switch destinationKind {
                    case .expense:
                        Label(
                            "Создаётся обычный расход в этой категории",
                            systemImage: "cart"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    case .asset:
                        Picker("Актив", selection: $selectedAssetId) {
                            Text("Не выбран").tag(UUID?.none)
                            ForEach(store.sortedAssets) { asset in
                                Text("\(asset.emoji) \(asset.name)").tag(Optional(asset.id))
                            }
                        }
                        if store.assets.isEmpty {
                            Text("Сначала добавьте актив в разделе «Активы»")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    case .goal:
                        Picker("Цель", selection: $selectedGoalId) {
                            Text("Не выбрана").tag(UUID?.none)
                            ForEach(store.sortedGoals) { goal in
                                Text("\(goal.emoji) \(goal.name)").tag(Optional(goal.id))
                            }
                        }
                        if store.goals.isEmpty {
                            Text("Сначала добавьте цель в разделе «Цели»")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .onAppear(perform: prefillDefaults)

            Divider()

            HStack {
                Button("Отмена") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Сохранить", action: save)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding()
        }
        .frame(minWidth: 540, minHeight: 580)
    }

    private func prefillDefaults() {
        if destinationKind == .asset, selectedAssetId == nil {
            selectedAssetId = store.sortedAssets.first?.id
        }
        if destinationKind == .goal, selectedGoalId == nil {
            selectedGoalId = store.sortedGoals.first?.id
        }
    }

    private func save() {
        let destination: AllocationDestination
        switch destinationKind {
        case .expense:
            destination = .expense
        case .asset:
            guard let id = selectedAssetId else { return }
            destination = .asset(id)
        case .goal:
            guard let id = selectedGoalId else { return }
            destination = .goal(id)
        }

        let planned = CurrencyFormatter.parse(plannedText) ?? 0
        let category = ExpenseCategory(
            id: editingId ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji.trimmingCharacters(in: .whitespaces).isEmpty ? "📦" : emoji.trimmingCharacters(in: .whitespaces),
            plannedAmount: Money(planned, plannedCurrency),
            destination: destination,
            sortOrder: sortOrder
        )
        onSave(category)
        dismiss()
    }
}

#Preview {
    CategoryEditorSheet(mode: .add) { _ in }
        .environmentObject(BudgetStore.preview)
}
