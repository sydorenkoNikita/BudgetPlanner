import SwiftUI

struct ForecastView: View {
    @EnvironmentObject private var store: BudgetStore

    @State private var horizon = 12
    @State private var selectedSnapshot: ForecastSnapshot?

    private var snapshots: [ForecastSnapshot] {
        store.forecast(months: horizon)
    }

    private var nothingToProject: Bool {
        let goalsHavePlan = store.goals.contains { $0.monthlyPlan.amount > 0 }
        let assetsHavePlan = store.assets.contains { !$0.kind.isPotential && $0.monthlyPlan.amount > 0 }
        return !goalsHavePlan && !assetsHavePlan && store.assets.isEmpty && store.goals.isEmpty
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            if nothingToProject {
                ContentUnavailableView(
                    "Нечего прогнозировать",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Создайте цель или актив и укажите сколько откладывать каждый месяц")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(snapshots) { snapshot in
                            ForecastMonthRow(snapshot: snapshot)
                                .onTapGesture { selectedSnapshot = snapshot }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding()
        .navigationTitle(AppSection.forecast.title)
        .sheet(item: $selectedSnapshot) { snapshot in
            ForecastDetailSheet(snapshot: snapshot)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(AppSection.forecast.emoji) \(AppSection.forecast.title)")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }

            HStack(spacing: 10) {
                summaryCard(title: "Сейчас на руках", money: store.liquidBalance, color: .green)
                summaryCard(title: "В копилке", money: store.savingsTotal, color: .blue)
                summaryCard(title: "В целях", money: store.goalsTotal, color: .indigo)
            }
            if store.potentialTotal.amount > 0 {
                HStack(spacing: 10) {
                    summaryCard(title: "Потенциально (продам/вернут)", money: store.potentialTotal, color: .purple)
                    summaryCard(title: "Net worth с потенциалом", money: store.netWorthFull, color: .pink)
                }
            }

            HStack {
                Text("Горизонт:")
                    .foregroundStyle(.secondary)
                Picker("Горизонт", selection: $horizon) {
                    Text("6 мес").tag(6)
                    Text("12 мес").tag(12)
                    Text("24 мес").tag(24)
                    Text("36 мес").tag(36)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .padding()
        .background(AppSection.forecast.color.opacity(0.1))
        .cornerRadius(10)
    }

    private func summaryCard(title: String, money: Money, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            MoneyView(money: money, primaryFont: .title3, primaryWeight: .bold, primaryColor: color, showConversion: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.gray.opacity(0.07))
        .cornerRadius(8)
    }
}

private struct ForecastMonthRow: View {
    let snapshot: ForecastSnapshot

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(snapshot.date.formatted(.dateTime.month(.wide).year()).capitalized)
                        .fontWeight(.semibold)
                    if snapshot.isCurrentMonth {
                        Text("сейчас")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .cornerRadius(4)
                    }
                }
                HStack(spacing: 4) {
                    Text("активы:")
                    MoneyView(money: snapshot.totalActiveAssets, primaryFont: .caption, primaryColor: .secondary, showConversion: false)
                    Text("·")
                    Text("цели:")
                    MoneyView(money: snapshot.totalGoals, primaryFont: .caption, primaryColor: .secondary, showConversion: false)
                    if snapshot.totalArrivedPotential.amount > 0 {
                        Text("·")
                        Text("потенциально:")
                        MoneyView(money: snapshot.totalArrivedPotential, primaryFont: .caption, primaryColor: .secondary, showConversion: false)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Net worth")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                MoneyView(money: snapshot.netWorth, primaryFont: .title3, primaryWeight: .bold, primaryColor: .indigo)
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .contentShape(Rectangle())
    }
}

struct ForecastDetailSheet: View {
    let snapshot: ForecastSnapshot

    @EnvironmentObject private var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    private var goalRows: [(goal: Goal, projected: Money)] {
        store.sortedGoals.compactMap { goal in
            guard let projected = snapshot.goalProjections[goal.id] else { return nil }
            return (goal, projected)
        }
    }

    private var assetRows: [(asset: Asset, projected: Money)] {
        store.sortedAssets
            .filter { !$0.kind.isPotential }
            .compactMap { asset in
                guard let projected = snapshot.assetProjections[asset.id] else { return nil }
                return (asset, projected)
            }
    }

    private var potentialRows: [(asset: Asset, amount: Money)] {
        store.sortedAssets
            .filter { $0.kind.isPotential }
            .compactMap { asset in
                guard let projected = snapshot.arrivedPotential[asset.id] else { return nil }
                return (asset, projected)
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.isCurrentMonth ? "Сейчас" : "Прогноз на")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(snapshot.date.formatted(.dateTime.month(.wide).year()).capitalized)
                        .font(.title)
                        .fontWeight(.bold)
                }
                Spacer()
                Button("Закрыть") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryBlock(
                        title: "К этому моменту net worth составит",
                        money: snapshot.netWorth,
                        color: .indigo
                    )

                    if !assetRows.isEmpty {
                        section("Активы") {
                            ForEach(assetRows, id: \.asset.id) { row in
                                assetRow(asset: row.asset, projected: row.projected)
                            }
                        }
                    }

                    if !goalRows.isEmpty {
                        section("Цели") {
                            ForEach(goalRows, id: \.goal.id) { row in
                                goalRow(goal: row.goal, projected: row.projected)
                            }
                        }
                    }

                    if !potentialRows.isEmpty {
                        section("«Пришло» к этому моменту") {
                            ForEach(potentialRows, id: \.asset.id) { item in
                                HStack {
                                    Text(item.asset.emoji)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.asset.name)
                                            .fontWeight(.medium)
                                        Text(item.asset.kind.title)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    MoneyView(money: item.amount, primaryFont: .body, primaryWeight: .semibold, primaryColor: .purple)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 640, minHeight: 580)
    }

    private func summaryBlock(title: String, money: Money, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            MoneyView(money: money, primaryFont: .title, primaryWeight: .bold, primaryColor: color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func assetRow(asset: Asset, projected: Money) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(asset.emoji)
                VStack(alignment: .leading, spacing: 2) {
                    Text(asset.name)
                        .fontWeight(.medium)
                    Text(asset.kind.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                MoneyView(money: projected, primaryFont: .body, primaryWeight: .semibold, primaryColor: asset.kind.color, showConversion: false)
            }
            if asset.monthlyPlan.amount > 0 && !snapshot.isCurrentMonth {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.green)
                    Text("за счёт")
                    MoneyView(money: asset.monthlyPlan, primaryFont: .caption2, primaryColor: .secondary, showConversion: false)
                    Text("/мес")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private func goalRow(goal: Goal, projected: Money) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(goal.emoji)
                Text(goal.name)
                    .fontWeight(.medium)
                Spacer()
                MoneyView(money: projected, primaryFont: .body, primaryWeight: .semibold, primaryColor: .blue, showConversion: false)
                Text("/")
                    .foregroundStyle(.secondary)
                MoneyView(money: goal.target, primaryFont: .body, primaryColor: .secondary, showConversion: false)
            }
            ProgressView(value: min(projected.amount / max(goal.target.amount, 1), 1))
                .tint(.blue)
            if goal.monthlyPlan.amount > 0 && !snapshot.isCurrentMonth {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.green)
                    Text("за счёт")
                    MoneyView(money: goal.monthlyPlan, primaryFont: .caption2, primaryColor: .secondary, showConversion: false)
                    Text("/мес")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        ForecastView()
            .environmentObject(BudgetStore.preview)
    }
}
