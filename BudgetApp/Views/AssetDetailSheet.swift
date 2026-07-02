import SwiftUI

struct AssetDetailSheet: View {
    let asset: Asset

    @EnvironmentObject private var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    @State private var movementPendingDeletion: AssetMovement?

    private var movements: [AssetMovement] {
        store.movements(for: asset)
    }

    private var liveAsset: Asset {
        store.asset(id: asset.id) ?? asset
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text(liveAsset.emoji)
                    .font(.system(size: 40))
                VStack(alignment: .leading, spacing: 4) {
                    Text(liveAsset.name)
                        .font(.title)
                        .fontWeight(.bold)
                    MoneyView(money: liveAsset.money, primaryFont: .title3, primaryWeight: .semibold, primaryColor: liveAsset.kind.color)
                    if liveAsset.monthlyPlan.amount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.clock")
                            Text("план/мес:")
                            MoneyView(money: liveAsset.monthlyPlan, primaryFont: .caption, primaryColor: .secondary, showConversion: false)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("Закрыть") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("История движений")
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top, 8)

                if movements.isEmpty {
                    ContentUnavailableView(
                        "Пока пусто",
                        systemImage: "tray",
                        description: Text("Распределите зарплату или пополните вручную")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(movements) { movement in
                            MovementRow(movement: movement, category: movement.categoryId.flatMap(store.category(id:)))
                                .contextMenu {
                                    if movement.paycheckId == nil {
                                        Button("Удалить", systemImage: "trash", role: .destructive) {
                                            movementPendingDeletion = movement
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
        .confirmationDialog(
            "Удалить движение?",
            isPresented: Binding(
                get: { movementPendingDeletion != nil },
                set: { if !$0 { movementPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: movementPendingDeletion
        ) { movement in
            Button("Удалить", role: .destructive) {
                store.deleteAssetMovement(movement)
                movementPendingDeletion = nil
            }
            Button("Отмена", role: .cancel) {
                movementPendingDeletion = nil
            }
        }
    }
}

private struct MovementRow: View {
    let movement: AssetMovement
    let category: ExpenseCategory?

    private var isPositive: Bool { movement.delta.amount >= 0 }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(movement.source)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(movement.date.formatted(date: .abbreviated, time: .omitted))
                    if let category {
                        Text("·")
                        Label("\(category.emoji) \(category.name)", systemImage: "tag")
                            .labelStyle(.titleAndIcon)
                    }
                    if movement.paycheckId != nil && movement.categoryId == nil {
                        Text("·")
                        Label("остаток зарплаты", systemImage: "tray.fill")
                            .labelStyle(.titleAndIcon)
                    } else if movement.paycheckId != nil {
                        Text("·")
                        Label("из зарплаты", systemImage: "link")
                            .labelStyle(.titleAndIcon)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            MoneyView(
                money: movement.delta,
                primaryFont: .body,
                primaryWeight: .bold,
                primaryColor: isPositive ? .green : .red
            )
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AssetDetailSheet(asset: Asset(name: "У Маши (USD)", emoji: "💵", kind: .cash, money: .usd(7000), monthlyPlan: .usd(550)))
        .environmentObject(BudgetStore.preview)
}
