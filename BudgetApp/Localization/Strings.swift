import Foundation

enum Strings {
    // MARK: - Common
    enum Common {
        static let save = "Сохранить"
        static let cancel = "Отмена"
        static let delete = "Удалить"
        static let add = "Добавить"
        static let edit = "Редактировать"
        static let close = "Закрыть"
        static let noData = "Нет данных"
    }

    // MARK: - ContentView
    enum ContentView {
        static let selectSection = "Выберите раздел"
        static let selectSectionDescription = "Откройте раздел в боковой панели"
    }

    // MARK: - AllocationDestination
    enum AllocationDestination {
        static let expense = "Расход"
        static let assetPrefix = "→"
        static let goalPrefix = "🎯"
        static let deletedAsset = "Удалённый актив"
        static let deletedGoal = "Удалённая цель"
    }

    // MARK: - PaycheckAllocation
    enum PaycheckAllocation {
        static let remainder = "Остаток"
        static let allocationComplete = "Распределение целиком"
    }

    // MARK: - Assets
    enum Assets {
        static let title = "Активы"
        static let add = "Добавить актив"
        static let totalLiquid = "Наличные"
        static let totalSavings = "Сбережения"
        static let totalPotential = "Потенциальные"
    }

    // MARK: - Goals
    enum Goals {
        static let title = "Цели"
        static let add = "Добавить цель"
        static let progress = "Прогресс"
    }

    // MARK: - Expenses
    enum Expenses {
        static let title = "Расходы"
        static let add = "Добавить расход"
        static let categories = "Категории"
        static let total = "Всего потрачено"
    }

    // MARK: - Categories
    enum Categories {
        static let title = "Категории расходов"
        static let add = "Добавить категорию"
        static let planned = "Запланировано"
        static let spent = "Потрачено"
        static let reserve = "Бронь"
        static let apartment = "Квартира"
        static let mom = "Маме"
        static let foodAndOutings = "Еда / гульки"
        static let loans = "Кредиты"
        static let savings = "Отложить"
    }

    // MARK: - Paychecks
    enum Paychecks {
        static let title = "Зарплаты"
        static let add = "Добавить зарплату"
        static let allocate = "Распределить"
        static let reallocate = "Пересчитать"
        static let allocated = "Распределено"
        static let notAllocated = "Не распределено"
    }

    // MARK: - Forecast
    enum Forecast {
        static let title = "Прогноз"
        static let goals = "Цели"
        static let activeAssets = "Активные активы"
        static let arrivedPotential = "Прибывшие потенциальные"
        static let netWorth = "Чистое состояние"
    }

    // MARK: - Settings
    enum Settings {
        static let title = "Параметры"
        static let currency = "Валюта по умолчанию"
        static let exchangeRate = "Курс обмена USD → UAH"
    }

    // MARK: - Forms
    enum Forms {
        static let name = "Название"
        static let emoji = "Эмодзи"
        static let amount = "Сумма"
        static let currency = "Валюта"
        static let date = "Дата"
        static let note = "Заметка"
        static let target = "Цель"
        static let monthlyPlan = "Месячный план"
        static let kind = "Вид"
        static let destination = "Направление"
    }
}
