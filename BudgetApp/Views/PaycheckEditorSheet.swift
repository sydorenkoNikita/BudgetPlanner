import SwiftUI

struct PaycheckEditorSheet: View {
    enum Mode {
        case add
        case edit(Paycheck)
    }

    let mode: Mode
    let onSave: (Paycheck) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var kind: PaycheckKind
    @State private var amountText: String
    @State private var currency: Currency
    @State private var date: Date
    @State private var note: String

    private let editingId: UUID?
    private let isAllocated: Bool

    init(mode: Mode, onSave: @escaping (Paycheck) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add:
            _kind = State(initialValue: .advance)
            _amountText = State(initialValue: "")
            _currency = State(initialValue: .uah)
            _date = State(initialValue: Date())
            _note = State(initialValue: "")
            editingId = nil
            isAllocated = false
        case .edit(let paycheck):
            _kind = State(initialValue: paycheck.kind)
            _amountText = State(initialValue: String(format: "%.0f", paycheck.amount.amount))
            _currency = State(initialValue: paycheck.amount.currency)
            _date = State(initialValue: paycheck.date)
            _note = State(initialValue: paycheck.note)
            editingId = paycheck.id
            isAllocated = paycheck.isAllocated
        }
    }

    private var isValid: Bool {
        CurrencyFormatter.parsePositive(amountText) != nil
    }

    private var title: String {
        switch mode {
        case .add: return "Новая зарплата"
        case .edit: return "Редактировать зарплату"
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
                        ForEach(PaycheckKind.allCases) { kind in
                            Text("\(kind.emoji) \(kind.title)").tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .disabled(isAllocated)
                }

                Section("Сумма") {
                    MoneyField(amountText: $amountText, currency: $currency)
                        .disabled(isAllocated)
                }

                Section("Дата") {
                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                }

                Section("Заметка") {
                    TextField("Например: Июнь", text: $note)
                }

                if isAllocated {
                    Section {
                        Label(
                            "Сумму, валюту и тип нельзя изменить — зарплата уже распределена. Откатите распределение, если нужно.",
                            systemImage: "info.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .frame(minWidth: 500, minHeight: 520)
    }

    private func save() {
        guard let amount = CurrencyFormatter.parsePositive(amountText) else { return }
        let paycheck = Paycheck(
            id: editingId ?? UUID(),
            kind: kind,
            amount: Money(amount, currency),
            date: date,
            note: note.trimmingCharacters(in: .whitespaces),
            isAllocated: isAllocated
        )
        onSave(paycheck)
        dismiss()
    }
}

#Preview("Добавление") {
    PaycheckEditorSheet(mode: .add) { _ in }
        .environmentObject(BudgetStore.preview)
}
