# Task 2: Create Localization System (Strings.swift)

## Overview
Extract all hardcoded Russian strings from the codebase into a centralized `Strings` enum. This is the foundation for supporting multiple languages in the future.

## Exact Deliverable
Create file: `BudgetApp/Localization/Strings.swift` with complete content provided in the plan.

The file contains these nested enums with static string properties:
- `Common` (save, cancel, delete, add, edit, close, noData)
- `ContentView` (selectSection, selectSectionDescription)
- `AllocationDestination` (expense, assetPrefix, goalPrefix, deletedAsset, deletedGoal)
- `PaycheckAllocation` (remainder, allocationComplete)
- `Assets` (title, add, totalLiquid, totalSavings, totalPotential)
- `Goals` (title, add, progress)
- `Expenses` (title, add, categories, total)
- `Categories` (title, add, planned, spent, reserve, apartment, mom, foodAndOutings, loans, savings)
- `Paychecks` (title, add, allocate, reallocate, allocated, notAllocated)
- `Forecast` (title, goals, activeAssets, arrivedPotential, netWorth)
- `Settings` (title, currency, exchangeRate)
- `Forms` (name, emoji, amount, currency, date, note, target, monthlyPlan, kind, destination)

All values are in Russian (see plan lines 120-232 for exact strings).

## Success Criteria
- File created at correct path
- Compiles without errors in Xcode
- Single commit: "feat: add localization strings system"

## Dependencies
- Task 1 must be complete (folder structure exists)

## Steps from Plan
See lines 107-246 of the implementation plan.
