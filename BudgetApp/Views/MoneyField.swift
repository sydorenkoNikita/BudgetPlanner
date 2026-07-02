import SwiftUI

/// Поле для ввода Money: текстовое поле + пикер валюты, плюс мелким шрифтом конвертация.
struct MoneyField: View {
    @EnvironmentObject private var store: BudgetStore

    @Binding var amountText: String
    @Binding var currency: Currency
    var placeholder: String = "0"
    var showConversionHint: Bool = true

    private var parsedAmount: Double? {
        CurrencyFormatter.parse(amountText)
    }

    private var conversionCurrency: Currency {
        currency == .uah ? .usd : .uah
    }

    private var converted: Money? {
        guard let amount = parsedAmount else { return nil }
        return Money(amount, currency).converted(
            to: conversionCurrency,
            uahPerUsd: store.exchangeRate.uahPerUsd
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                TextField(placeholder, text: $amountText)
                    .textFieldStyle(.roundedBorder)
                Picker("", selection: $currency) {
                    ForEach(Currency.allCases) { item in
                        Text(item.symbol).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 80)
            }
            if showConversionHint, let converted {
                Text("≈ \(CurrencyFormatter.string(converted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    @Previewable @State var amount = "1500"
    @Previewable @State var currency: Currency = .uah
    return MoneyField(amountText: $amount, currency: $currency)
        .padding()
        .environmentObject(BudgetStore.preview)
}
