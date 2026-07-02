import SwiftUI

/// Отображение суммы с автоматической конвертацией в скобках.
struct MoneyView: View {
    @EnvironmentObject private var store: BudgetStore

    let money: Money
    var primaryFont: Font = .body
    var primaryWeight: Font.Weight = .regular
    var primaryColor: Color = .primary
    var showConversion: Bool = true
    var conversionColor: Color = .secondary

    private var conversionCurrency: Currency {
        money.currency == .uah ? .usd : .uah
    }

    private var converted: Money {
        money.converted(to: conversionCurrency, uahPerUsd: store.exchangeRate.uahPerUsd)
    }

    private var preciseTooltip: String {
        let mainPrecise = CurrencyFormatter.string(money, decimals: 2)
        let convPrecise = CurrencyFormatter.string(converted, decimals: 2)
        return "\(mainPrecise) ≈ \(convPrecise) (курс 1 $ = \(CurrencyFormatter.string(Money(store.exchangeRate.uahPerUsd, .uah), decimals: 2)))"
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(CurrencyFormatter.string(money))
                .font(primaryFont)
                .fontWeight(primaryWeight)
                .foregroundStyle(primaryColor)
            if showConversion {
                Text("(≈ \(CurrencyFormatter.string(converted)))")
                    .font(.caption)
                    .foregroundStyle(conversionColor)
            }
        }
        .help(preciseTooltip)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        MoneyView(money: .usd(7000), primaryFont: .title, primaryWeight: .bold)
        MoneyView(money: .uah(89600), primaryFont: .title, primaryWeight: .bold)
        MoneyView(money: .uah(25000), primaryFont: .body)
        MoneyView(money: .usd(550), primaryFont: .body)
    }
    .padding()
    .environmentObject(BudgetStore.preview)
}
