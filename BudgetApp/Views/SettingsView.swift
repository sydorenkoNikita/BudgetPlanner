import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: BudgetStore

    @State private var rateText: String = ""
    @State private var selectedCurrency: Currency = .uah

    var body: some View {
        VStack(spacing: 16) {
            header

            Form {
                Section("Курс валют") {
                    HStack {
                        Text("1 $ =")
                        TextField("44,93", text: $rateText)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                        Text("₴")
                            .foregroundStyle(.secondary)
                    }
                    Text("Курс используется для конвертации всех сумм и расчёта общего net worth.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Валюта отображения") {
                    Picker("Основная валюта", selection: $selectedCurrency) {
                        ForEach(Currency.allCases) { currency in
                            Text("\(currency.symbol) \(currency.title)").tag(currency)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("В этой валюте показываются сводки. Каждый актив/цель остаются в своей родной валюте.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Превью") {
                    HStack {
                        Text("100 $ ≈")
                        MoneyView(money: .usd(100), primaryFont: .body, primaryWeight: .semibold, showConversion: false)
                        Text("→")
                            .foregroundStyle(.secondary)
                        MoneyView(money: Money(100, .usd).converted(to: .uah, uahPerUsd: CurrencyFormatter.parse(rateText) ?? store.exchangeRate.uahPerUsd), primaryFont: .body, primaryWeight: .semibold, showConversion: false)
                    }
                }
            }
            .formStyle(.grouped)

            Spacer()
        }
        .padding()
        .navigationTitle(AppSection.settings.title)
        .onAppear {
            rateText = String(format: "%.2f", store.exchangeRate.uahPerUsd)
            selectedCurrency = store.displayCurrency
        }
        .onChange(of: rateText) { _, newValue in
            if let value = CurrencyFormatter.parse(newValue), value > 0 {
                store.exchangeRate.uahPerUsd = value
            }
        }
        .onChange(of: selectedCurrency) { _, newValue in
            store.displayCurrency = newValue
        }
    }

    private var header: some View {
        HStack {
            Text("\(AppSection.settings.emoji) \(AppSection.settings.title)")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(BudgetStore.preview)
    }
}
