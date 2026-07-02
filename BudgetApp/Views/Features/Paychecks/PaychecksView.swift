import SwiftUI

struct PaychecksView: View {
    @EnvironmentObject private var store: BudgetStore

    @State private var editingPaycheck: Paycheck?
    @State private var allocatingPaycheck: Paycheck?
    @State private var editingAllocationPaycheck: Paycheck?
    @State private var isAddingPaycheck = false
    @State private var paycheckPendingDeletion: Paycheck?
    @State private var quickSendPaycheck: Paycheck?

    var body: some View {
        VStack(spacing: 16) {
            header

            if store.paychecks.isEmpty {
                ContentUnavailableView(
                    "Зарплат пока нет",
                    systemImage: "dollarsign.circle",
                    description: Text("Добавьте поступление — аванс или зарплату")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.sortedPaychecks) { paycheck in
                            PaycheckCard(
                                paycheck: paycheck,
                                onAllocate: { allocatingPaycheck = paycheck },
                                onEditAllocation: { editingAllocationPaycheck = paycheck },
                                onSendAll: { quickSendPaycheck = paycheck },
                                onDeallocate: { store.deallocate(paycheckId: paycheck.id) },
                                onEdit: { editingPaycheck = paycheck },
                                onDelete: { paycheckPendingDeletion = paycheck }
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding()
        .navigationTitle(AppSection.paychecks.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingPaycheck = true
                } label: {
                    Label("Добавить", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingPaycheck) {
            PaycheckEditorSheet(mode: .add) { paycheck in
                store.addPaycheck(paycheck)
            }
        }
        .sheet(item: $editingPaycheck) { paycheck in
            PaycheckEditorSheet(mode: .edit(paycheck)) { updated in
                store.updatePaycheck(updated)
            }
        }
        .sheet(item: $allocatingPaycheck) { paycheck in
            AllocatePaycheckSheet(paycheck: paycheck)
        }
        .sheet(item: $editingAllocationPaycheck) { paycheck in
            AllocatePaycheckSheet(paycheck: paycheck, isEditingExisting: true)
        }
        .sheet(item: $quickSendPaycheck) { paycheck in
            QuickSendSheet(paycheck: paycheck)
        }
        .confirmationDialog(
            "Удалить зарплату?",
            isPresented: Binding(
                get: { paycheckPendingDeletion != nil },
                set: { if !$0 { paycheckPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: paycheckPendingDeletion
        ) { paycheck in
            Button("Удалить", role: .destructive) {
                store.deletePaycheck(paycheck)
                paycheckPendingDeletion = nil
            }
            Button("Отмена", role: .cancel) {
                paycheckPendingDeletion = nil
            }
        } message: { paycheck in
            if paycheck.isAllocated {
                Text("Связанные расходы, пополнения активов и целей тоже будут удалены.")
            } else {
                Text("Это действие нельзя отменить.")
            }
        }
    }

    private var header: some View {
        HStack {
            Text("\(AppSection.paychecks.emoji) \(AppSection.paychecks.title)")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Всего пришло")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MoneyView(money: store.totalIncome, primaryFont: .title2, primaryWeight: .bold, primaryColor: .green)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct PaycheckCard: View {
    let paycheck: Paycheck
    let onAllocate: () -> Void
    let onEditAllocation: () -> Void
    let onSendAll: () -> Void
    let onDeallocate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(paycheck.kind.emoji)
                        Text(paycheck.kind.title)
                            .fontWeight(.semibold)
                        if paycheck.isAllocated {
                            Label("распределено", systemImage: "checkmark.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    if !paycheck.note.isEmpty {
                        Text(paycheck.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(paycheck.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                MoneyView(money: paycheck.amount, primaryFont: .title3, primaryWeight: .bold, primaryColor: .green)
                Menu {
                    Button("Изменить", systemImage: "pencil", action: onEdit)
                    Button("Удалить", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            HStack(spacing: 8) {
                if paycheck.isAllocated {
                    Button {
                        onEditAllocation()
                    } label: {
                        Label("Изменить распределение", systemImage: "pencil.and.list.clipboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        onDeallocate()
                    } label: {
                        Label("Откатить", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        onAllocate()
                    } label: {
                        Label("Распределить", systemImage: "rectangle.3.group")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        onSendAll()
                    } label: {
                        Label("Всё в актив / цель", systemImage: "banknote")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

private struct QuickSendSheet: View {
    let paycheck: Paycheck

    @EnvironmentObject private var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    @State private var selection: String = ""

    private struct Option: Hashable, Identifiable {
        let id: String
        let title: String
        let destination: AllocationDestination
    }

    private var options: [Option] {
        var result: [Option] = []
        for goal in store.sortedGoals {
            result.append(Option(id: "goal-\(goal.id)", title: "🎯 Цель: \(goal.name)", destination: .goal(goal.id)))
        }
        for asset in store.sortedAssets where !asset.kind.isPotential {
            result.append(Option(id: "asset-\(asset.id)", title: "\(asset.emoji) Актив: \(asset.name)", destination: .asset(asset.id)))
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Куда отправить всю зарплату?")
                        .font(.title3)
                        .fontWeight(.bold)
                    HStack(spacing: 6) {
                        Text(paycheck.kind.emoji)
                        Text(paycheck.kind.title)
                        MoneyView(money: paycheck.amount, primaryFont: .body, primaryWeight: .bold, primaryColor: .green)
                    }
                }
                Spacer()
            }
            .padding()

            Divider()

            if options.isEmpty {
                ContentUnavailableView(
                    "Нет целей или активов",
                    systemImage: "tray",
                    description: Text("Сначала создайте цель или актив-копилку")
                )
                .padding()
            } else {
                Form {
                    Picker("Назначение", selection: $selection) {
                        ForEach(options) { option in
                            Text(option.title).tag(option.id)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                .formStyle(.grouped)
            }

            Divider()

            HStack {
                Button("Отмена") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Отправить") {
                    if let dest = options.first(where: { $0.id == selection })?.destination {
                        store.sendAll(paycheckId: paycheck.id, to: dest)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(options.first(where: { $0.id == selection }) == nil)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 460)
        .onAppear {
            selection = options.first?.id ?? ""
        }
    }
}

#Preview {
    NavigationStack {
        PaychecksView()
            .environmentObject(BudgetStore.preview)
    }
}
