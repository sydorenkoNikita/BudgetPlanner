import Foundation

enum CurrencyFormatter {
    static func string(_ money: Money, decimals: Int = 0) -> String {
        let formatter = formatter(decimals: decimals)
        let value = formatter.string(from: NSNumber(value: money.amount)) ?? "0"
        return "\(value) \(money.currency.symbol)"
    }

    static func string(_ amount: Double, currency: Currency, decimals: Int = 0) -> String {
        string(Money(amount, currency), decimals: decimals)
    }

    static func parse(_ input: String) -> Double? {
        let normalized = input
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
        guard let value = Double(normalized), value >= 0 else { return nil }
        return value
    }

    static func parsePositive(_ input: String) -> Double? {
        guard let value = parse(input), value > 0 else { return nil }
        return value
    }

    private static func formatter(decimals: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = " "
        return formatter
    }
}
