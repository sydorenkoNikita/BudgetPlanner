import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: BudgetStore
    @Binding var selectedSection: AppSection?

    private let financeSections: [AppSection] = [.paychecks, .expenses]
    private let assetSections: [AppSection] = [.assets, .goals, .forecast]
    private let settingSections: [AppSection] = [.categories, .settings]

    var body: some View {
        List(selection: $selectedSection) {
            Section("💰 Net worth") {
                BalanceCard()
            }

            Section("Финансы") {
                ForEach(financeSections) { section in
                    NavigationLink(value: section) {
                        SidebarRow(section: section, subtitle: subtitle(for: section))
                    }
                }
            }

            Section("Активы и цели") {
                ForEach(assetSections) { section in
                    NavigationLink(value: section) {
                        SidebarRow(section: section, subtitle: subtitle(for: section))
                    }
                }
            }

            Section("Настройки") {
                ForEach(settingSections) { section in
                    NavigationLink(value: section) {
                        SidebarRow(section: section, subtitle: subtitle(for: section))
                    }
                }
            }
        }
        .navigationTitle("Меню")
        .frame(minWidth: 280)
    }

    private func subtitle(for section: AppSection) -> String {
        switch section {
        case .paychecks: return CurrencyFormatter.string(store.totalIncome)
        case .expenses: return CurrencyFormatter.string(store.totalExpenses)
        case .assets: return CurrencyFormatter.string(store.netWorthReal)
        case .goals: return CurrencyFormatter.string(store.goalsTotal)
        case .forecast: return "на \(12) мес вперёд"
        case .categories: return "\(store.categories.count) шт."
        case .settings: return "курс 1 $ = \(String(format: "%.2f", store.exchangeRate.uahPerUsd)) ₴"
        }
    }
}

private struct BalanceCard: View {
    @EnvironmentObject private var store: BudgetStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Реальный net worth")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MoneyView(money: store.netWorthReal, primaryFont: .title2, primaryWeight: .bold, primaryColor: .green)
            }

            if store.potentialTotal.amount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(.purple)
                    Text("потенциально:")
                        .foregroundStyle(.secondary)
                    MoneyView(money: store.potentialTotal, primaryFont: .caption, primaryColor: .purple, showConversion: false)
                }
                .font(.caption)
            }

            Divider()

            breakdown(title: "На руках", money: store.liquidBalance, icon: "creditcard.fill", color: .green)
            breakdown(title: "В копилке", money: store.savingsTotal, icon: "banknote.fill", color: .blue)
            breakdown(title: "В целях", money: store.goalsTotal, icon: "target", color: .indigo)
        }
        .padding(.vertical, 6)
    }

    private func breakdown(title: String, money: Money, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 14)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            MoneyView(money: money, primaryFont: .caption, primaryWeight: .medium, primaryColor: .primary, showConversion: false)
        }
    }
}

private struct SidebarRow: View {
    let section: AppSection
    let subtitle: String

    var body: some View {
        HStack {
            Image(systemName: section.icon)
                .foregroundStyle(section.color)
                .font(.title3)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(selectedSection: .constant(.paychecks))
            .environmentObject(BudgetStore.preview)
    } detail: {
        EmptyView()
    }
}
