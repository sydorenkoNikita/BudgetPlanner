import SwiftUI

struct AssetEditorSheet: View {
    enum Mode {
        case add
        case edit(Asset)
    }

    let mode: Mode
    let onSave: (Asset) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var kind: AssetKind
    @State private var amountText: String
    @State private var currency: Currency
    @State private var monthlyText: String
    @State private var monthlyCurrency: Currency
    @State private var note: String
    @State private var hasExpectedDate: Bool
    @State private var expectedDate: Date

    private let editingId: UUID?
    private let sortOrder: Int

    init(mode: Mode, onSave: @escaping (Asset) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add:
            _name = State(initialValue: "")
            _emoji = State(initialValue: "💼")
            _kind = State(initialValue: .cash)
            _amountText = State(initialValue: "")
            _currency = State(initialValue: .uah)
            _monthlyText = State(initialValue: "")
            _monthlyCurrency = State(initialValue: .uah)
            _note = State(initialValue: "")
            _hasExpectedDate = State(initialValue: false)
            _expectedDate = State(initialValue: Date())
            editingId = nil
            sortOrder = 0
        case .edit(let asset):
            _name = State(initialValue: asset.name)
            _emoji = State(initialValue: asset.emoji)
            _kind = State(initialValue: asset.kind)
            _amountText = State(initialValue: String(format: "%.2f", asset.money.amount))
            _currency = State(initialValue: asset.money.currency)
            _monthlyText = State(initialValue: asset.monthlyPlan.amount > 0 ? String(format: "%.0f", asset.monthlyPlan.amount) : "")
            _monthlyCurrency = State(initialValue: asset.monthlyPlan.currency)
            _note = State(initialValue: asset.note)
            _hasExpectedDate = State(initialValue: asset.expectedDate != nil)
            _expectedDate = State(initialValue: asset.expectedDate ?? Date())
            editingId = asset.id
            sortOrder = asset.sortOrder
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        CurrencyFormatter.parse(amountText) != nil
    }

    private var title: String {
        switch mode {
        case .add: return "Новый актив"
        case .edit: return "Редактировать актив"
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
                Section("Тип") {
                    Picker("Тип", selection: $kind) {
                        ForEach(AssetKind.allCases) { item in
                            Label(item.title, systemImage: item.icon).tag(item)
                        }
                    }
                    .labelsHidden()
                }

                Section("Эмодзи и название") {
                    HStack {
                        TextField("💼", text: $emoji)
                            .font(.title)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                        TextField("Например: У Маши", text: $name)
                    }
                }

                Section("Сумма") {
                    MoneyField(amountText: $amountText, currency: $currency)
                }

                if !kind.isPotential {
                    Section("Откладывать каждый месяц") {
                        MoneyField(amountText: $monthlyText, currency: $monthlyCurrency)
                        Text("Используется в прогнозе. Например: если каждый месяц с зарплат отправляешь сюда 550$, поставь 550 — прогноз покажет рост.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Заметка") {
                    TextField("Например: долгосрочные сбережения", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                if kind.isPotential {
                    Section("Ожидаемая дата получения") {
                        Toggle("Знаю дату", isOn: $hasExpectedDate)
                        if hasExpectedDate {
                            DatePicker("Дата", selection: $expectedDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                }
            }
            .formStyle(.grouped)

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
        .frame(minWidth: 500, minHeight: 560)
    }

    private func save() {
        guard let amount = CurrencyFormatter.parse(amountText) else { return }
        let monthly = CurrencyFormatter.parse(monthlyText) ?? 0
        let asset = Asset(
            id: editingId ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji.trimmingCharacters(in: .whitespaces).isEmpty ? "💼" : emoji.trimmingCharacters(in: .whitespaces),
            kind: kind,
            money: Money(amount, currency),
            monthlyPlan: kind.isPotential ? Money(0, currency) : Money(monthly, monthlyCurrency),
            note: note.trimmingCharacters(in: .whitespaces),
            expectedDate: (kind.isPotential && hasExpectedDate) ? expectedDate : nil,
            sortOrder: sortOrder
        )
        onSave(asset)
        dismiss()
    }
}

struct AssetMovementSheet: View {
    let asset: Asset
    let onSave: (AssetMovement) -> Void

    @EnvironmentObject private var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var currency: Currency
    @State private var date = Date()
    @State private var source = ""
    @State private var isWithdrawal = false

    init(asset: Asset, onSave: @escaping (AssetMovement) -> Void) {
        self.asset = asset
        self.onSave = onSave
        _currency = State(initialValue: asset.money.currency)
    }

    private var isValid: Bool {
        CurrencyFormatter.parsePositive(amountText) != nil &&
        !source.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(asset.emoji) \(asset.name)")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section("Операция") {
                    Picker("Тип", selection: $isWithdrawal) {
                        Text("Пополнить").tag(false)
                        Text("Снять").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section("Сумма") {
                    MoneyField(amountText: $amountText, currency: $currency)
                }

                Section("Откуда / куда") {
                    TextField(isWithdrawal ? "Например: на ремонт" : "Например: подарок", text: $source)
                }

                Section("Дата") {
                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Отмена") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isWithdrawal ? "Снять" : "Пополнить", action: save)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding()
        }
        .frame(minWidth: 460, minHeight: 460)
    }

    private func save() {
        guard let raw = CurrencyFormatter.parsePositive(amountText) else { return }
        let signed = isWithdrawal ? -raw : raw
        let movement = AssetMovement(
            assetId: asset.id,
            delta: Money(signed, currency),
            date: date,
            source: source.trimmingCharacters(in: .whitespaces),
            paycheckId: nil
        )
        onSave(movement)
        dismiss()
    }
}

#Preview("Добавить актив") {
    AssetEditorSheet(mode: .add) { _ in }
        .environmentObject(BudgetStore.preview)
}
