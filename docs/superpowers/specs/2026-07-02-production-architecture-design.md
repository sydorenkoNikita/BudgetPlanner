# BudgetApp Production Architecture Design

**Date:** 2026-07-02  
**Status:** Design Phase  
**Goal:** Transform BudgetApp into a production-ready, reusable, hardcode-free codebase

---

## 1. Localization System

### Problem
All UI strings are hardcoded in Russian throughout Views. Adding another language requires grep-and-replace across the codebase.

### Solution
Create a centralized localization system:

```swift
// Localization/Strings.swift
enum Strings {
    enum Common {
        static let save = "Сохранить"
        static let cancel = "Отмена"
        static let delete = "Удалить"
    }
    
    enum ContentView {
        static let selectSection = "Выберите раздел"
        static let selectSectionDescription = "Откройте раздел в боковой панели"
    }
    
    enum AllocationSheet {
        static let expenseLabel = "Расход"
        static let assetPrefix = "→"
        static let goalPrefix = "🎯"
    }
    // ... more sections
}
```

### Implementation
- Single source of truth: `Strings.swift` enum with all UI text
- Add `LocalizationManager` to switch language at runtime (prepared for future)
- Update all Views to use `Strings.*` instead of inline strings
- Future: Support `.strings` files or JSON for each language

---

## 2. Reusable Component Architecture

### 2.1 Generic List Container
Create `ListViewContainer<Item>` to eliminate duplicate list boilerplate:

```swift
struct ListViewContainer<Item: Identifiable>: View {
    @Binding var items: [Item]
    @State private var selectedItem: Item?
    @State private var isEditorShowing = false
    
    let rowContent: (Item) -> AnyView
    let detailContent: (Item) -> AnyView
    let editorContent: (Item?) -> AnyView
    let onAdd: (Item) -> Void
    let onUpdate: (Item) -> Void
    let onDelete: (Item) -> Void
    
    // Standard list UI with add/edit/delete actions
}
```

**Usage:**
```swift
struct AssetsView: View {
    @EnvironmentObject var store: BudgetStore
    @State private var selectedAsset: Asset?
    @State private var isEditorShowing = false
    
    var body: some View {
        ListViewContainer(
            items: $store.assets,
            rowContent: { asset in
                AssetRowView(asset: asset).eraseToAnyView()
            },
            detailContent: { asset in
                AssetDetailSheet(asset: asset).eraseToAnyView()
            },
            editorContent: { asset in
                AssetEditorSheet(asset: asset).eraseToAnyView()
            },
            onAdd: store.addAsset,
            onUpdate: store.updateAsset,
            onDelete: store.deleteAsset
        )
    }
}
```

### 2.2 Form Field Components
Eliminate repetitive form patterns with `GenericFormField`:

```swift
struct GenericFormField<Value>: View {
    let label: String
    @Binding var value: Value
    let formatter: (Value) -> String
    let parser: (String) -> Value?
    
    // Handles text input, validation, formatting
}
```

### 2.3 Keep Existing Components
- `MoneyField` — already reusable, no changes needed
- `MoneyView` — already reusable, no changes needed
- Move to `Components/` folder for clarity

---

## 3. Feature-Based Folder Structure

```
BudgetApp/
├── Models/
│   ├── Asset.swift
│   ├── Goal.swift
│   ├── Expense.swift
│   ├── Paycheck.swift
│   ├── Money.swift
│   ├── Currency.swift
│   ├── ExchangeRate.swift
│   ├── ExpenseCategory.swift
│   └── AppSection.swift
│
├── Stores/
│   └── BudgetStore.swift
│
├── Views/
│   ├── Components/
│   │   ├── ListViewContainer.swift
│   │   ├── GenericFormField.swift
│   │   ├── MoneyField.swift
│   │   ├── MoneyView.swift
│   │   └── LabeledSection.swift
│   │
│   ├── Features/
│   │   ├── Assets/
│   │   │   ├── AssetsView.swift
│   │   │   ├── AssetRowView.swift
│   │   │   ├── AssetDetailSheet.swift
│   │   │   └── AssetEditorSheet.swift
│   │   │
│   │   ├── Goals/
│   │   │   ├── GoalsView.swift
│   │   │   ├── GoalRowView.swift
│   │   │   ├── GoalDetailSheet.swift
│   │   │   └── GoalEditorSheet.swift
│   │   │
│   │   ├── Expenses/
│   │   │   ├── ExpensesView.swift
│   │   │   ├── ExpenseRowView.swift
│   │   │   ├── ExpenseEditorSheet.swift
│   │   │   └── CategoriesView.swift
│   │   │   └── CategoryEditorSheet.swift
│   │   │
│   │   ├── Paychecks/
│   │   │   ├── PaychecksView.swift
│   │   │   ├── PaycheckRowView.swift
│   │   │   ├── PaycheckEditorSheet.swift
│   │   │   └── AllocatePaycheckSheet.swift
│   │   │
│   │   ├── Forecast/
│   │   │   ├── ForecastView.swift
│   │   │   └── ForecastRowView.swift
│   │   │
│   │   └── Settings/
│   │       └── SettingsView.swift
│   │
│   ├── Shared/
│   │   ├── SidebarView.swift
│   │   └── ContentView.swift
│   │
│   └── Modifiers/
│       └── ViewModifiers.swift (if needed)
│
├── Localization/
│   └── Strings.swift
│
├── Utilities/
│   ├── CurrencyFormatter.swift
│   └── DateFormatter.swift (new, if needed)
│
├── Config/
│   └── AppConfig.swift (new)
│
├── BudgetAppApp.swift
│
└── docs/
    └── superpowers/
        └── specs/
            └── 2026-07-02-production-architecture-design.md
```

---

## 4. Configuration System (No Hardcodes)

Create `AppConfig.swift` for all configurable values:

```swift
struct AppConfig {
    // Defaults
    struct Defaults {
        static let displayCurrency: Currency = .uah
        static let defaultCategories: [ExpenseCategory] = [
            ExpenseCategory(name: Strings.Categories.reserve, emoji: "🛡", ...),
            ExpenseCategory(name: Strings.Categories.apartment, emoji: "🏠", ...),
        ]
    }
    
    // UI Constants
    struct UI {
        static let minWindowWidth: CGFloat = 760
        static let minWindowHeight: CGFloat = 600
        static let listItemSpacing: CGFloat = 8
    }
    
    // Formatting
    struct Formatting {
        static let currencyDecimalPlaces = 2
        static let dateFormat = "dd.MM.yyyy"
    }
}
```

**Usage in code:**
```swift
// Before
.frame(minWidth: 760, minHeight: 600)

// After
.frame(minWidth: AppConfig.UI.minWindowWidth, minHeight: AppConfig.UI.minWindowHeight)
```

---

## 5. ViewModel Pattern (Lightweight)

Keep ViewModels thin — only for presentation logic, not business logic:

```swift
// Features/Assets/AssetsViewModel.swift
@MainActor
class AssetsViewModel: ObservableObject {
    @EnvironmentObject private var store: BudgetStore
    
    var displayedAssets: [Asset] {
        store.sortedAssets
    }
    
    var totalAssets: Money {
        store.liquidBalance
    }
    
    func add(_ asset: Asset) {
        store.addAsset(asset)
    }
}
```

**Why lightweight:**
- Business logic stays in `BudgetStore`
- ViewModel only handles display/filtering/sorting
- Makes testing easier

---

## 6. Data Flow

```
BudgetStore (source of truth)
    ↓
Features/XxxViewModel (presentation queries)
    ↓
Features/XxxView (renders UI)
    ↓
User interaction
    ↓
Store methods (add/update/delete)
    ↓
BudgetStore updates @Published properties
    ↓
SwiftUI re-renders
```

---

## 7. Migration Path

### Phase 1: Setup (this task)
1. Create folder structure
2. Extract `Strings.swift`
3. Create `ListViewContainer` generic
4. Create `AppConfig.swift`

### Phase 2: Refactor Views
1. Move existing views to feature folders
2. Replace hardcoded strings with `Strings.*`
3. Replace hardcoded UI constants with `AppConfig.*`
4. Simplify list views using `ListViewContainer`

### Phase 3: Polish (future)
1. Add ViewModels where presentation logic gets complex
2. Add tests for ViewModels
3. Prepare localization infrastructure for new languages

---

## 8. No Breaking Changes

- `BudgetStore` interface stays the same
- Existing Models unchanged
- Views refactored internally, same external contracts
- All changes are internal restructuring + additions

---

## 9. Testing Strategy

- Unit tests for `AppConfig` values exist (no crashes on config access)
- Unit tests for lightweight ViewModels (filtering, sorting)
- UI tests remain the same (views have same behavior)

---

## Success Criteria

✅ No hardcoded strings in Swift code  
✅ No hardcoded UI constants (minWidth, spacing, etc.)  
✅ 50%+ reduction in duplicate list view code  
✅ New features can reuse existing components without modification  
✅ Changing a UI string requires edit in one place only  
✅ Easy to add new language in the future  
