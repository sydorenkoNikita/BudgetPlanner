import Foundation

struct ExchangeRate: Hashable {
    /// Сколько гривен за один доллар
    var uahPerUsd: Double

    static let `default` = ExchangeRate(uahPerUsd: 44.93)
}
