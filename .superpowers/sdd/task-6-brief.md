# Task 6: Move and Refactor AssetRowView

## Overview
This is the template task for Phase 2. Move Assets views to the feature folder and refactor them to use the new architecture (ListViewContainer, Strings, AppConfig).

## Exact Modifications

### 1. Create AssetRowView.swift
Create file: `BudgetApp/Views/Features/Assets/AssetRowView.swift`

Exact content from plan lines 520-554.

### 2. Move these files into Features/Assets/:
- `BudgetApp/Views/AssetEditorSheet.swift` → `BudgetApp/Views/Features/Assets/AssetEditorSheet.swift`
- `BudgetApp/Views/AssetDetailSheet.swift` → `BudgetApp/Views/Features/Assets/AssetDetailSheet.swift`
- `BudgetApp/Views/AssetsView.swift` → `BudgetApp/Views/Features/Assets/AssetsView.swift`

### 3. Replace AssetsView.swift
New content from plan lines 535-549:
```swift
struct AssetsView: View {
    @EnvironmentObject private var store: BudgetStore
    
    var body: some View {
        ListViewContainer(
            items: $store.assets,
            rowContent: { asset in
                AssetRowView(asset: asset)
                    .eraseToAnyView()
            },
            // ... rest from plan
        )
    }
}
```

### 4. Update AssetDetailSheet & AssetEditorSheet
Replace all hardcoded strings with `Strings.Forms.*` and `Strings.Common.*`

Examples:
- "Название" → `Strings.Forms.name`
- "Эмодзи" → `Strings.Forms.emoji`
- "Сохранить" → `Strings.Common.save`

Replace any hardcoded padding/spacing with `AppConfig.UI.*`

## Success Criteria
- AssetRowView.swift created and compiles
- Three files moved to Features/Assets/
- AssetsView.swift uses ListViewContainer
- No hardcoded Russian strings in any of these files
- Single commit: "refactor: move Assets views to feature folder and use Strings/AppConfig"
- App builds successfully

## Dependencies
- Task 1 (folder structure) complete
- Task 2 (Strings.swift) complete
- Task 3 (AppConfig.swift) complete
- Task 4 (ListViewContainer) complete

## Steps from Plan
See lines 479-536 of the implementation plan.
