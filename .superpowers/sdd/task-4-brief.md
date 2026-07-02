# Task 4: Create ListViewContainer Generic Component

## Overview
Create a reusable generic component for standard list UI with add/edit/delete functionality. This eliminates duplicate list view boilerplate across Assets, Goals, Expenses, and Paychecks views.

## Exact Deliverable

Create file: `BudgetApp/Views/Components/ListViewContainer.swift` with complete implementation from plan (lines 395-461).

Key aspects:
- Generic over `Item: Identifiable`
- Provides NavigationSplitView with List on left (sidebar), detail on right
- Supports row content rendering via closure
- Supports optional detail view via closure
- Supports optional editor sheet via closure
- Has add/edit/delete actions with swipe actions
- Includes delete confirmation dialog
- Uses `Strings.Common.*` for all button labels
- Uses `AppConfig.UI.*` for spacing/layout values

## Exact Signature

```swift
struct ListViewContainer<Item: Identifiable>: View {
    @Binding var items: [Item]
    @State private var selectedItem: Item?
    @State private var editingItem: Item?
    @State private var isEditorShowing = false
    @State private var itemToDelete: Item?
    
    let rowContent: (Item) -> AnyView
    let detailContent: ((Item) -> AnyView)?
    let editorContent: ((Item?) -> AnyView)?
    let onAdd: ((Item) -> Void)?
    let onUpdate: ((Item) -> Void)?
    let onDelete: ((Item) -> Void)?
    
    var body: some View { ... }
}
```

Include preview in #if DEBUG block.

## Success Criteria
- File created at correct path
- Compiles without errors in Xcode
- Uses Strings.Common for all text
- Single commit: "feat: add generic ListViewContainer component"

## Dependencies
- Task 1 (folder structure) complete
- Task 2 (Strings.swift) complete and compiles

## Steps from Plan
See lines 361-416 of the implementation plan.
