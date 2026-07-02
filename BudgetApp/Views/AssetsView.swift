import SwiftUI

struct AssetsView: View {
    @EnvironmentObject private var store: BudgetStore

    @State private var editingAsset: Asset?
    @State private var isAddingAsset = false
    @State private var assetPendingDeletion: Asset?
    @State private var topUpAsset: Asset?
    @State private var detailAsset: Asset?

    var body: some View {
        VStack(spacing: 16) {
            header

            if store.assets.isEmpty {
                ContentUnavailableView(
                    "Активов пока нет",
                    systemImage: "wallet.pass",
                    description: Text("Добавьте кошельки, копилку, имущество, долги")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(AssetKind.allCases) { kind in
                            let items = store.assets(of: kind)
                            if !items.isEmpty {
                                AssetGroup(
                                    kind: kind,
                                    assets: items,
                                    onTopUp: { topUpAsset = $0 },
                                    onEdit: { editingAsset = $0 },
                                    onDelete: { assetPendingDeletion = $0 },
                                    onOpen: { detailAsset = $0 }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .navigationTitle(AppSection.assets.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingAsset = true
                } label: {
                    Label("Добавить", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingAsset) {
            AssetEditorSheet(mode: .add) { asset in
                store.addAsset(asset)
            }
        }
        .sheet(item: $editingAsset) { asset in
            AssetEditorSheet(mode: .edit(asset)) { updated in
                store.updateAsset(updated)
            }
        }
        .sheet(item: $topUpAsset) { asset in
            AssetMovementSheet(asset: asset) { movement in
                store.addAssetMovement(movement)
            }
        }
        .sheet(item: $detailAsset) { asset in
            AssetDetailSheet(asset: asset)
        }
        .confirmationDialog(
            "Удалить актив?",
            isPresented: Binding(
                get: { assetPendingDeletion != nil },
                set: { if !$0 { assetPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: assetPendingDeletion
        ) { asset in
            Button("Удалить", role: .destructive) {
                store.deleteAsset(asset)
                assetPendingDeletion = nil
            }
            Button("Отмена", role: .cancel) {
                assetPendingDeletion = nil
            }
        } message: { _ in
            Text("Все движения по активу будут удалены, категории распределения зарплаты с этим активом — переключены на расход.")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(AppSection.assets.emoji) \(AppSection.assets.title)")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            HStack(spacing: 12) {
                summaryCard(
                    title: "Кошельки",
                    money: store.liquidBalance,
                    color: AssetKind.cash.color
                )
                summaryCard(
                    title: "Копилка",
                    money: store.savingsTotal,
                    color: AssetKind.savings.color
                )
                summaryCard(
                    title: "Реальный net worth",
                    money: store.netWorthReal,
                    color: .green
                )
            }
            HStack(spacing: 12) {
                summaryCard(
                    title: "Потенциально (продам / вернут)",
                    money: store.potentialTotal,
                    color: .purple
                )
                summaryCard(
                    title: "Net worth с потенциалом",
                    money: store.netWorthFull,
                    color: .indigo
                )
            }
        }
        .padding()
        .background(AppSection.assets.color.opacity(0.1))
        .cornerRadius(10)
    }

    private func summaryCard(title: String, money: Money, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            MoneyView(money: money, primaryFont: .title3, primaryWeight: .bold, primaryColor: color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

private struct AssetGroup: View {
    @EnvironmentObject private var store: BudgetStore
    let kind: AssetKind
    let assets: [Asset]
    let onTopUp: (Asset) -> Void
    let onEdit: (Asset) -> Void
    let onDelete: (Asset) -> Void
    let onOpen: (Asset) -> Void

    private var total: Money {
        let amount = assets.reduce(0.0) { acc, asset in
            acc + store.convert(asset.money, to: store.displayCurrency).amount
        }
        return Money(amount, store.displayCurrency)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(kind.title, systemImage: kind.icon)
                    .foregroundStyle(kind.color)
                    .font(.headline)
                if kind.isPotential {
                    Text("потенциально")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(kind.color.opacity(0.15))
                        .foregroundStyle(kind.color)
                        .cornerRadius(4)
                }
                Spacer()
                MoneyView(money: total, primaryFont: .headline, primaryWeight: .semibold, primaryColor: kind.color)
            }

            VStack(spacing: 8) {
                ForEach(assets) { asset in
                    AssetCard(
                        asset: asset,
                        onOpen: { onOpen(asset) },
                        onTopUp: { onTopUp(asset) },
                        onEdit: { onEdit(asset) },
                        onDelete: { onDelete(asset) }
                    )
                }
            }
        }
    }
}

private struct AssetCard: View {
    let asset: Asset
    let onOpen: () -> Void
    let onTopUp: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(asset.emoji)
                .font(.title2)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(asset.name)
                    .fontWeight(.medium)
                if !asset.note.isEmpty {
                    Text(asset.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if asset.monthlyPlan.amount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                        Text("план/мес:")
                        MoneyView(money: asset.monthlyPlan, primaryFont: .caption2, primaryColor: .secondary, showConversion: false)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                if let expected = asset.expectedDate {
                    Label("к \(expected.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                        .labelStyle(.titleAndIcon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                MoneyView(money: asset.money, primaryFont: .title3, primaryWeight: .bold, primaryColor: asset.kind.color)
                HStack(spacing: 6) {
                    Button("История", systemImage: "list.bullet.rectangle", action: onOpen)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("Пополнить", systemImage: "plus.circle", action: onTopUp)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Menu {
                        Button("Изменить", systemImage: "pencil", action: onEdit)
                        Button("Удалить", systemImage: "trash", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onOpen() }
    }
}

#Preview {
    NavigationStack {
        AssetsView()
            .environmentObject(BudgetStore.preview)
    }
}
