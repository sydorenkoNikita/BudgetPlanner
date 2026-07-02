# Task 5: Create GenericFormField Component

## Overview
Create reusable form field components for handling common input patterns (strings, dates, etc.) in editor sheets.

## Exact Deliverable

Create file: `BudgetApp/Views/Components/GenericFormField.swift` with:

1. **GenericFormField<Value>** - Generic wrapper accepting custom content closure
2. **StringFormField** - Variant for text input
3. **DateFormField** - Variant for date picker

Implementation from plan lines 418-476. All exact code must match.

Key aspects:
- Generics for reusability
- Label + content structure
- Uses eraseToAnyView() for type erasure
- StringFormField with TextField
- DateFormField with DatePicker(.graphical)
- Include preview in #if DEBUG block

## Success Criteria
- File created at correct path
- All three components compile without errors
- Single commit: "feat: add generic form field components"

## Dependencies
- Task 1 (folder structure) complete

## Steps from Plan
See lines 418-476 of the implementation plan.
