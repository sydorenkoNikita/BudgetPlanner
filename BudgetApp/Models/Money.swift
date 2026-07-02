import Foundation

struct Money: Hashable {
    var amount: Double
    var currency: Currency

    init(_ amount: Double, _ currency: Currency) {
        self.amount = amount
        self.currency = currency
    }

    static let zeroUAH = Money(0, .uah)
    static func uah(_ amount: Double) -> Money { Money(amount, .uah) }
    static func usd(_ amount: Double) -> Money { Money(amount, .usd) }
}

extension Money {
    /// Конвертация в произвольную валюту по курсу uahPerUsd
    func converted(to target: Currency, uahPerUsd: Double) -> Money {
        guard currency != target, uahPerUsd > 0 else { return Money(amount, target) }
        switch (currency, target) {
        case (.uah, .usd):
            return Money(amount / uahPerUsd, .usd)
        case (.usd, .uah):
            return Money(amount * uahPerUsd, .uah)
        case (.uah, .uah), (.usd, .usd):
            return self
        }
    }
}

extension Money {
    static func + (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currency == rhs.currency, "Складывать можно только одинаковые валюты — конвертируйте сначала")
        return Money(lhs.amount + rhs.amount, lhs.currency)
    }

    static func - (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currency == rhs.currency, "Вычитать можно только одинаковые валюты")
        return Money(lhs.amount - rhs.amount, lhs.currency)
    }

    static prefix func - (value: Money) -> Money {
        Money(-value.amount, value.currency)
    }
}
