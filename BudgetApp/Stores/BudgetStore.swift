import Foundation

struct AllocationItem: Identifiable, Hashable {
    let id = UUID()
    let categoryId: UUID
    var amount: Double
    var currency: Currency
}

@MainActor
final class BudgetStore: ObservableObject {
    @Published var exchangeRate: ExchangeRate = .default
    @Published var displayCurrency: Currency = .uah

    @Published var paychecks: [Paycheck] = []
    @Published var categories: [ExpenseCategory] = []
    @Published var expenses: [Expense] = []
    @Published var assets: [Asset] = []
    @Published var assetMovements: [AssetMovement] = []
    @Published var goals: [Goal] = []
    @Published var goalContributions: [GoalContribution] = []

    init() {
        seedDefaults()
    }

    // MARK: - Конвертация

    func convert(_ money: Money, to currency: Currency) -> Money {
        money.converted(to: currency, uahPerUsd: exchangeRate.uahPerUsd)
    }

    func display(_ money: Money) -> Money {
        convert(money, to: displayCurrency)
    }

    private func sum(_ items: [Money], in currency: Currency) -> Money {
        let amount = items.reduce(0.0) { partial, money in
            partial + convert(money, to: currency).amount
        }
        return Money(amount, currency)
    }

    // MARK: - Сводки

    var totalIncome: Money {
        sum(paychecks.map(\.amount), in: displayCurrency)
    }

    var totalExpenses: Money {
        sum(expenses.map(\.amount), in: displayCurrency)
    }

    var liquidBalance: Money {
        sum(assets.filter { $0.kind == .cash }.map(\.money), in: displayCurrency)
    }

    var savingsTotal: Money {
        sum(assets.filter { $0.kind == .savings }.map(\.money), in: displayCurrency)
    }

    var goalsTotal: Money {
        sum(goalContributions.map(\.amount), in: displayCurrency)
    }

    var potentialTotal: Money {
        sum(assets.filter { $0.kind.isPotential }.map(\.money), in: displayCurrency)
    }

    var netWorthReal: Money {
        Money(liquidBalance.amount + savingsTotal.amount + goalsTotal.amount, displayCurrency)
    }

    var netWorthFull: Money {
        Money(netWorthReal.amount + potentialTotal.amount, displayCurrency)
    }

    // MARK: - Категории

    var sortedCategories: [ExpenseCategory] {
        categories.sorted { $0.sortOrder < $1.sortOrder }
    }

    func category(id: UUID) -> ExpenseCategory? {
        categories.first { $0.id == id }
    }

    func addCategory(_ category: ExpenseCategory) {
        var newCategory = category
        newCategory.sortOrder = (categories.map(\.sortOrder).max() ?? -1) + 1
        categories.append(newCategory)
    }

    func updateCategory(_ category: ExpenseCategory) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[index] = category
    }

    func deleteCategory(_ category: ExpenseCategory) {
        categories.removeAll { $0.id == category.id }
        expenses.removeAll { $0.categoryId == category.id }
    }

    func expenses(in category: ExpenseCategory) -> [Expense] {
        expenses
            .filter { $0.categoryId == category.id }
            .sorted { $0.date > $1.date }
    }

    func totalSpent(in category: ExpenseCategory) -> Money {
        let items = expenses.filter { $0.categoryId == category.id }.map(\.amount)
        let currency = category.plannedAmount.currency
        return sum(items, in: currency)
    }

    func destinationLabel(_ dest: AllocationDestination) -> String {
        switch dest {
        case .expense:
            return "Расход"
        case .asset(let id):
            return asset(id: id).map { "→ \($0.emoji) \($0.name)" } ?? "Удалённый актив"
        case .goal(let id):
            return goal(id: id).map { "🎯 \($0.name)" } ?? "Удалённая цель"
        }
    }

    // MARK: - Активы

    var sortedAssets: [Asset] {
        assets.sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
    }

    func asset(id: UUID) -> Asset? {
        assets.first { $0.id == id }
    }

    func assets(of kind: AssetKind) -> [Asset] {
        sortedAssets.filter { $0.kind == kind }
    }

    func addAsset(_ asset: Asset) {
        var newAsset = asset
        newAsset.sortOrder = (assets.map(\.sortOrder).max() ?? -1) + 1
        assets.append(newAsset)
    }

    func updateAsset(_ asset: Asset) {
        guard let index = assets.firstIndex(where: { $0.id == asset.id }) else { return }
        assets[index] = asset
    }

    func deleteAsset(_ asset: Asset) {
        assets.removeAll { $0.id == asset.id }
        assetMovements.removeAll { $0.assetId == asset.id }
        for i in categories.indices {
            if case .asset(let id) = categories[i].destination, id == asset.id {
                categories[i].destination = .expense
            }
        }
    }

    func movements(for asset: Asset) -> [AssetMovement] {
        assetMovements
            .filter { $0.assetId == asset.id }
            .sorted { $0.date > $1.date }
    }

    private func applyDelta(_ delta: Money, to assetId: UUID) {
        guard let index = assets.firstIndex(where: { $0.id == assetId }) else { return }
        let converted = convert(delta, to: assets[index].money.currency)
        assets[index].money.amount += converted.amount
    }

    // MARK: - Цели

    var sortedGoals: [Goal] {
        goals.sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
    }

    func goal(id: UUID) -> Goal? {
        goals.first { $0.id == id }
    }

    func addGoal(_ goal: Goal) {
        var newGoal = goal
        newGoal.sortOrder = (goals.map(\.sortOrder).max() ?? -1) + 1
        goals.append(newGoal)
    }

    func updateGoal(_ goal: Goal) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[index] = goal
    }

    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        goalContributions.removeAll { $0.goalId == goal.id }
        for i in categories.indices {
            if case .goal(let id) = categories[i].destination, id == goal.id {
                categories[i].destination = .expense
            }
        }
    }

    func contributions(for goal: Goal) -> [GoalContribution] {
        goalContributions
            .filter { $0.goalId == goal.id }
            .sorted { $0.date > $1.date }
    }

    func progress(for goal: Goal) -> Money {
        let items = goalContributions.filter { $0.goalId == goal.id }.map(\.amount)
        return sum(items, in: goal.target.currency)
    }

    func progressPercent(for goal: Goal) -> Double {
        let target = goal.target.amount
        guard target > 0 else { return 0 }
        return min(progress(for: goal).amount / target, 1)
    }

    // MARK: - Зарплаты

    var sortedPaychecks: [Paycheck] {
        paychecks.sorted { $0.date > $1.date }
    }

    func paycheck(id: UUID) -> Paycheck? {
        paychecks.first { $0.id == id }
    }

    func addPaycheck(_ paycheck: Paycheck) {
        paychecks.append(paycheck)
    }

    func updatePaycheck(_ paycheck: Paycheck) {
        guard let index = paychecks.firstIndex(where: { $0.id == paycheck.id }) else { return }
        paychecks[index] = paycheck
    }

    func deletePaycheck(_ paycheck: Paycheck) {
        deallocate(paycheckId: paycheck.id)
        paychecks.removeAll { $0.id == paycheck.id }
    }

    // MARK: - Расходы

    func addExpense(_ expense: Expense) {
        expenses.append(expense)
    }

    func updateExpense(_ expense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
    }

    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }

    // MARK: - Распределение зарплаты

    func allocate(
        paycheckId: UUID,
        items: [AllocationItem],
        remainderDestination: AllocationDestination?
    ) {
        guard let paycheck = paycheck(id: paycheckId), !paycheck.isAllocated else { return }
        let sourceLabel = label(for: paycheck)

        for item in items where item.amount > 0 {
            guard let category = category(id: item.categoryId) else { continue }
            let money = Money(item.amount, item.currency)
            apply(
                money: money,
                destination: category.destination,
                sourceLabel: "\(sourceLabel) — \(category.name)",
                date: paycheck.date,
                paycheckId: paycheck.id,
                categoryId: category.id,
                fallbackCategory: category
            )
        }

        let allocatedInPaycheckCurrency = items.reduce(0.0) { acc, item in
            acc + Money(item.amount, item.currency)
                .converted(to: paycheck.amount.currency, uahPerUsd: exchangeRate.uahPerUsd)
                .amount
        }
        let remainder = paycheck.amount.amount - allocatedInPaycheckCurrency

        if remainder > 0.5, let destination = remainderDestination {
            apply(
                money: Money(remainder, paycheck.amount.currency),
                destination: destination,
                sourceLabel: "\(sourceLabel) — Остаток",
                date: paycheck.date,
                paycheckId: paycheck.id,
                categoryId: nil,
                fallbackCategory: nil
            )
        }

        markAllocated(paycheckId: paycheck.id, value: true)
    }

    /// Редактирование распределения: откатывает текущее и применяет новое.
    func reallocate(
        paycheckId: UUID,
        items: [AllocationItem],
        remainderDestination: AllocationDestination?
    ) {
        deallocate(paycheckId: paycheckId)
        allocate(paycheckId: paycheckId, items: items, remainderDestination: remainderDestination)
    }

    /// Восстанавливает суммы распределения и куда уходил остаток для существующей зарплаты.
    func extractAllocation(paycheckId: UUID) -> (items: [UUID: Double], remainderDestination: AllocationDestination?) {
        guard let paycheck = paycheck(id: paycheckId) else { return ([:], nil) }
        let paycheckCurrency = paycheck.amount.currency
        var itemsByCategory: [UUID: Double] = [:]

        for expense in expenses where expense.paycheckId == paycheckId {
            let inPaycheck = convert(expense.amount, to: paycheckCurrency).amount
            itemsByCategory[expense.categoryId, default: 0] += inPaycheck
        }

        for movement in assetMovements where movement.paycheckId == paycheckId {
            guard let categoryId = movement.categoryId else { continue }
            let inPaycheck = convert(movement.delta, to: paycheckCurrency).amount
            itemsByCategory[categoryId, default: 0] += inPaycheck
        }

        for contribution in goalContributions where contribution.paycheckId == paycheckId {
            guard let categoryId = contribution.categoryId else { continue }
            let inPaycheck = convert(contribution.amount, to: paycheckCurrency).amount
            itemsByCategory[categoryId, default: 0] += inPaycheck
        }

        // Остаток без categoryId — берём destination из первого подходящего движения
        var remainderDestination: AllocationDestination? = nil
        if let movement = assetMovements.first(where: { $0.paycheckId == paycheckId && $0.categoryId == nil }) {
            remainderDestination = .asset(movement.assetId)
        } else if let contribution = goalContributions.first(where: { $0.paycheckId == paycheckId && $0.categoryId == nil }) {
            remainderDestination = .goal(contribution.goalId)
        }

        return (itemsByCategory, remainderDestination)
    }

    func sendAll(paycheckId: UUID, to destination: AllocationDestination) {
        guard let paycheck = paycheck(id: paycheckId), !paycheck.isAllocated else { return }
        apply(
            money: paycheck.amount,
            destination: destination,
            sourceLabel: "\(label(for: paycheck)) — целиком",
            date: paycheck.date,
            paycheckId: paycheck.id,
            categoryId: nil,
            fallbackCategory: nil
        )
        markAllocated(paycheckId: paycheck.id, value: true)
    }

    func deallocate(paycheckId: UUID) {
        let related = assetMovements.filter { $0.paycheckId == paycheckId }
        for movement in related {
            applyDelta(-movement.delta, to: movement.assetId)
        }
        assetMovements.removeAll { $0.paycheckId == paycheckId }
        expenses.removeAll { $0.paycheckId == paycheckId }
        goalContributions.removeAll { $0.paycheckId == paycheckId }
        markAllocated(paycheckId: paycheckId, value: false)
    }

    private func apply(
        money: Money,
        destination: AllocationDestination,
        sourceLabel: String,
        date: Date,
        paycheckId: UUID,
        categoryId: UUID?,
        fallbackCategory: ExpenseCategory?
    ) {
        switch destination {
        case .expense:
            guard let category = fallbackCategory else { return }
            expenses.append(
                Expense(
                    categoryId: category.id,
                    name: category.name,
                    amount: money,
                    date: date,
                    paycheckId: paycheckId
                )
            )

        case .asset(let assetId):
            guard let assetCurrency = asset(id: assetId)?.money.currency else { return }
            let convertedMoney = convert(money, to: assetCurrency)
            let displayLabel = money.currency == assetCurrency
                ? sourceLabel
                : "\(sourceLabel) (из \(CurrencyFormatter.string(money)))"
            assetMovements.append(
                AssetMovement(
                    assetId: assetId,
                    delta: convertedMoney,
                    date: date,
                    source: displayLabel,
                    paycheckId: paycheckId,
                    categoryId: categoryId
                )
            )
            applyDelta(convertedMoney, to: assetId)

        case .goal(let goalId):
            guard let goalCurrency = goal(id: goalId)?.target.currency else { return }
            let convertedMoney = convert(money, to: goalCurrency)
            let displayLabel = money.currency == goalCurrency
                ? sourceLabel
                : "\(sourceLabel) (из \(CurrencyFormatter.string(money)))"
            goalContributions.append(
                GoalContribution(
                    goalId: goalId,
                    amount: convertedMoney,
                    date: date,
                    source: displayLabel,
                    paycheckId: paycheckId,
                    categoryId: categoryId
                )
            )
        }
    }

    private func markAllocated(paycheckId: UUID, value: Bool) {
        guard let index = paychecks.firstIndex(where: { $0.id == paycheckId }) else { return }
        paychecks[index].isAllocated = value
    }

    private func label(for paycheck: Paycheck) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL"
        let month = formatter.string(from: paycheck.date).capitalized
        let dateString = paycheck.date.formatted(date: .numeric, time: .omitted)
        let base = "\(paycheck.kind.title) \(month) (\(dateString))"
        return paycheck.note.isEmpty ? base : "\(base) [\(paycheck.note)]"
    }

    // MARK: - Ручное пополнение активов и целей

    func addAssetMovement(_ movement: AssetMovement) {
        assetMovements.append(movement)
        applyDelta(movement.delta, to: movement.assetId)
    }

    func deleteAssetMovement(_ movement: AssetMovement) {
        applyDelta(-movement.delta, to: movement.assetId)
        assetMovements.removeAll { $0.id == movement.id }
    }

    func addGoalContribution(_ contribution: GoalContribution) {
        goalContributions.append(contribution)
    }

    func updateGoalContribution(_ contribution: GoalContribution) {
        guard let index = goalContributions.firstIndex(where: { $0.id == contribution.id }) else { return }
        goalContributions[index] = contribution
    }

    func deleteGoalContribution(_ contribution: GoalContribution) {
        goalContributions.removeAll { $0.id == contribution.id }
    }

    // MARK: - Прогноз

    /// Прогнозные значения по целям + активам на N месяцев вперёд.
    func forecast(months: Int) -> [ForecastSnapshot] {
        let calendar = Calendar.current
        var result: [ForecastSnapshot] = []

        for monthOffset in 0...max(months, 1) {
            guard let date = calendar.date(byAdding: .month, value: monthOffset, to: Date()) else { continue }

            // Цели — прогресс + n * monthlyPlan
            var goalProgress: [UUID: Money] = [:]
            var totalGoals = 0.0
            for goal in sortedGoals {
                let base = progress(for: goal)
                let added = goal.monthlyPlan
                    .converted(to: goal.target.currency, uahPerUsd: exchangeRate.uahPerUsd)
                    .amount * Double(monthOffset)
                let projected = Money(base.amount + added, goal.target.currency)
                goalProgress[goal.id] = projected
                totalGoals += convert(projected, to: displayCurrency).amount
            }

            // Активы (cash + savings): текущая сумма + n * monthlyPlan
            var assetProjections: [UUID: Money] = [:]
            var totalActiveAssets = 0.0
            for asset in sortedAssets where !asset.kind.isPotential {
                let added = asset.monthlyPlan
                    .converted(to: asset.money.currency, uahPerUsd: exchangeRate.uahPerUsd)
                    .amount * Double(monthOffset)
                let projected = Money(asset.money.amount + added, asset.money.currency)
                assetProjections[asset.id] = projected
                totalActiveAssets += convert(projected, to: displayCurrency).amount
            }

            // Потенциальные активы — включаются если их expectedDate <= snapshot.date
            var arrivedPotential: [UUID: Money] = [:]
            var totalArrived = 0.0
            for asset in sortedAssets where asset.kind.isPotential {
                if let expected = asset.expectedDate, expected <= date {
                    arrivedPotential[asset.id] = asset.money
                    totalArrived += convert(asset.money, to: displayCurrency).amount
                }
            }

            let netWorth = Money(
                totalGoals + totalActiveAssets + totalArrived,
                displayCurrency
            )

            result.append(
                ForecastSnapshot(
                    date: date,
                    isCurrentMonth: monthOffset == 0,
                    goalProjections: goalProgress,
                    assetProjections: assetProjections,
                    arrivedPotential: arrivedPotential,
                    totalGoals: Money(totalGoals, displayCurrency),
                    totalActiveAssets: Money(totalActiveAssets, displayCurrency),
                    totalArrivedPotential: Money(totalArrived, displayCurrency),
                    netWorth: netWorth
                )
            )
        }
        return result
    }

    // MARK: - Дефолты

    private func seedDefaults() {
        categories = [
            ExpenseCategory(name: "Бронь", emoji: "🛡", plannedAmount: .uah(13200), destination: .expense, sortOrder: 0),
            ExpenseCategory(name: "Квартира", emoji: "🏠", plannedAmount: .uah(20000), destination: .expense, sortOrder: 1),
            ExpenseCategory(name: "Маме", emoji: "👩", plannedAmount: .uah(5000), destination: .expense, sortOrder: 2),
            ExpenseCategory(name: "Еда / гульки", emoji: "🍔", plannedAmount: .uah(14000), destination: .expense, sortOrder: 3),
            ExpenseCategory(name: "Кредиты", emoji: "💳", plannedAmount: .uah(12000), destination: .expense, sortOrder: 4),
            ExpenseCategory(name: "Отложить", emoji: "🏦", plannedAmount: .uah(25000), destination: .expense, sortOrder: 5)
        ]
    }
}

struct ForecastSnapshot: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
    let goalProjections: [UUID: Money]
    let assetProjections: [UUID: Money]
    let arrivedPotential: [UUID: Money]
    let totalGoals: Money
    let totalActiveAssets: Money
    let totalArrivedPotential: Money
    let netWorth: Money
}

// MARK: - Превью

extension BudgetStore {
    static var preview: BudgetStore {
        let store = BudgetStore()
        let mariaUSD = Asset(
            name: "У Маши (USD)",
            emoji: "💵",
            kind: .cash,
            money: .usd(7000),
            monthlyPlan: .usd(550),
            note: "Долгосрочные сбережения",
            sortOrder: 0
        )
        let card = Asset(
            name: "Карта",
            emoji: "💳",
            kind: .cash,
            money: .uah(0),
            sortOrder: 1
        )
        let oldCar = Asset(
            name: "Старая машина",
            emoji: "🚗",
            kind: .sellable,
            money: .uah(250_000),
            sortOrder: 2
        )
        store.assets = [mariaUSD, card, oldCar]

        let newCar = Goal(
            name: "Новая машина",
            emoji: "🚙",
            target: .uah(800_000),
            monthlyPlan: .uah(25_000),
            sortOrder: 0
        )
        store.goals = [newCar]

        let advance = Paycheck(
            kind: .advance,
            amount: .uah(89_200),
            date: .now.addingTimeInterval(-86400 * 14),
            note: "Июнь"
        )
        store.paychecks = [advance]
        return store
    }
}
