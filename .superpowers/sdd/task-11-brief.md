# Task 11: Move Shared Components

## Overview
Move MoneyField and MoneyView to the Components folder (they're already reusable, just need relocation).

## Exact Changes

Move these two files to `BudgetApp/Views/Components/`:
- `BudgetApp/Views/MoneyField.swift` → `BudgetApp/Views/Components/MoneyField.swift`
- `BudgetApp/Views/MoneyView.swift` → `BudgetApp/Views/Components/MoneyView.swift`

No code changes needed in these files — just move them.

## Success Criteria
- Both files moved to Components folder
- No code changes
- Xcode project auto-updates file references
- App builds without errors
- Single commit: "chore: move money components to Components folder"

## Dependencies
- All prior tasks complete (Tasks 1-10)
