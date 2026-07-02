# Task 12: Final String Replacements Across All Views

## Overview
Scan all remaining Swift files for any hardcoded Russian strings or hardcoded UI constants that weren't caught in earlier tasks, and replace them with `Strings.*` or `AppConfig.*` equivalents.

## Exact Process

1. Use Xcode Find to search for these patterns across BudgetApp/:
   - Search for Russian strings not yet replaced (e.g., "Расход", "Остаток", "Отмена", etc.)
   - Search for hardcoded numbers like 760, 600, 8, 12, 16, 50 (UI constants)
   - Search for hardcoded padding/spacing values

2. For each occurrence:
   - If it's a UI string that has a Strings.* entry, replace with Strings.[category].[key]
   - If it's a UI constant (width, height, padding), replace with AppConfig.UI.[constant]

3. Common replacements:
   - "Выберите раздел" → Strings.ContentView.selectSection
   - "Откройте раздел в боковой панели" → Strings.ContentView.selectSectionDescription
   - "Расход" → Strings.AllocationDestination.expense
   - "→" → Strings.AllocationDestination.assetPrefix
   - "🎯" → Strings.AllocationDestination.goalPrefix
   - minWidth: 760 → minWidth: AppConfig.UI.windowMinWidth
   - minHeight: 600 → minHeight: AppConfig.UI.windowMinHeight
   - Padding values 8, 12, 16 → AppConfig.UI.listItemSpacing, listItemPadding, sectionSpacing

## Success Criteria
- No hardcoded Russian strings remain in Swift code
- No hardcoded UI constants remain (all use AppConfig)
- App builds without errors
- Single commit: "refactor: replace remaining hardcoded strings and constants with Strings and AppConfig"

## Dependencies
- All prior tasks complete (Tasks 1-11)
