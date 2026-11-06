---
status: Draft
owner: "Nikita Sydorenko"
updated_at: "2026-11-06"
depth: "medium"
---

# Idea brief — personal-budget-app

## 1. Raw idea

> Я хочу приложение для учета личных средств. Я хочу иметь возможность записать свою текщую ЗП, сколько денег у меня на обязательные рассходы (квартира/бензин/кредит и тд), сколько я могу отложить (просто так или на цель). Я использую монобанк, и каждый раз фасую всю зп по банкам, когда что то нужно то снимаю. То есть хотелось бы интеграцию. Также хочу ИИ, к примеру "эй ассистент я сейчас коплю на дом но хотелось бы поехать в отпуск, как мне рассчитать бюджет". Я хочу видеть сколько и в каком месяце я заработал/отложил. То что сейчас в репо BudgetApp это просто набросок

## 2. Problem

The owner splits each salary across Monobank jars by hand and withdraws from them when needed (owner-reported). Of the pains named, the main one is **planning goals**: it is unclear how to combine several goals (e.g. saving for a house and also a vacation), how much to set aside, and when each goal will be reached (owner-reported, chosen over "no monthly history", "manual salary split", "unclear free money").

Secondary wishes (owner-reported, priority not yet set): record salary / mandatory expenses (rent, fuel, loan) / savings; see earned and saved amounts per month; a Monobank integration; an AI assistant that answers planning questions in natural language.

Monobank integration means **seeing in the app where money was spent** (read-only view of spending), not moving money. The manual jar split is how the owner works today, not something the app must automate (owner-reported, correcting the interviewer's misreading).

Desired outcome (owner-reported): for a question like "saving for a house, want a vacation", the app first **compares scenarios** (how each choice shifts goal dates, with amounts and dates), then turns the chosen scenario into a **monthly salary-split plan** (how much goes to each goal per month).

## 3. Users

- **Owner** — a Monobank customer in Ukraine, paid a salary, keeps money in jars, saves for a house and wants a vacation (owner-reported).
- **Owner's partner** — will use the app together with the owner for the first month to half a year (owner-reported). Whether they share one budget, keep separate ones, or both is **not decided**; the owner would like both a personal and a family budget (owner-reported).
- **Future paying customers** — after that period the owner wants to sell the app as a product (owner-reported). Who they are is not established.
- Devices: Mac and iPhone, data in sync between them (owner-reported). The current sketch targets macOS only (source-verified: `BudgetApp.xcodeproj/project.pbxproj`, `SDKROOT = macosx`, `MACOSX_DEPLOYMENT_TARGET = 15.2`).

## 4. Why now

No external trigger established. The repo holds a sketch the owner calls "just a draft" (owner-reported); it keeps all data in memory and saves nothing (source-verified: no persistence code found under `BudgetApp/`, commit `bc07369`).

## 5. Out of scope

- **Automatic money movement** (card ↔ jars) — the owner never asked for it (owner-reported); it also appears unsupported by the Monobank API (assumption, see §6).
- **AI assistant in the first version** — owner accepted: calculations (scenario comparison + monthly plan) come first; a conversational AI on top of them comes later (owner-accepted recommendation, 2026-11-06). Reason: sending financial data to an external model and per-request cost are deferred.

## 6. Risks

Weakest consequential assumption first. Critique: independent `sdd:devils-advocate` pass (interview mode, 3 findings); each code claim re-checked by the interviewer against `BudgetApp/Stores/BudgetStore.swift` at commit `bc07369`.

1. **The sketch's planning logic cannot show goal trade-offs.** The forecast adds each goal's own fixed monthly plan (`progress + monthlyPlan × n`) and doesn't tie goals to income or a shared surplus, so adding a vacation never moves the house date (source-verified, `BudgetStore.swift` `forecast(months:)` ~L478–500). Saving ("Отложить") is seeded as an expense (source-verified, ~L551). A single exchange rate is applied to all future months, so USD-priced goals funded from UAH salary get dates that look precise but can't be trusted (source-verified, `forecast` uses one `exchangeRate.uahPerUsd`). Consequence: reusing this logic leaves the main pain unsolved. It needs rework, not polish.
2. **Data model vs sync and two users.** Balances are mutated in place (`applyDelta` L168–172) and the double-allocation guard is a local flag (`isAllocated`) (source-verified). With Mac + iPhone sync and two people, offline edits could double-count or drift (hypothetical failure, not observed). The owner chose personal + shared budgets from the first version (owner-accepted), so the storage/sharing model has to support both from the start. Signal to watch: totals that differ between devices or don't equal the sum of history entries.
3. **Monobank access for a sold product.** Personal per-user tokens are likely fine for the owner and partner. For a commercial app it is unknown whether personal tokens are allowed, or whether a corporate API (requirements unknown) and a server for webhooks are needed (unknown). History import is slow under the reported limits (assumption, secondary sources). Reversible as long as integration stays read-only and personal until this is checked.
4. **Monobank API capabilities themselves are unverified.** Official docs returned HTTP 403 on 2026-11-06. All API claims come from secondary sources.

Evidence ledger:

| Claim / question | Class | Source / origin | Finding / limit |
|---|---|---|---|
| Main pain is goal planning | owner-reported | interview 2026-11-06 | chosen from 4 options |
| Integration = read-only view of spending | owner-reported | interview 2026-11-06 | owner corrected interviewer |
| Sketch is macOS-only | source-verified | `BudgetApp.xcodeproj/project.pbxproj` | `SDKROOT = macosx`, target 15.2 |
| Sketch has no persistence | source-verified | `BudgetApp/` grep, `BudgetStore.swift` @ `bc07369` | in-memory store only |
| Forecast is per-goal, no trade-off | source-verified | `BudgetStore.swift` ~L478–500 | fixed `monthlyPlan × n` |
| Monobank API is read-only (no transfers/jar creation) | assumption | jentic.com/apis/monobank.ua/monobank (secondary), 2026-11-06 | absence in a third-party list is not proof; official docs 403 |
| Personal X-Token per user; ~1 statement req/60 s; ~31-day window; one webhook per token | assumption | secondary sources + search snippets, 2026-11-06 | not checked against official docs |
| Corporate API / third-party commercial terms | unknown | — | not found |

## 7. Recommendation

Direction (owner-accepted, 2026-11-06), in this order:

1. **Goal planner.** The owner enters salary and mandatory expenses by hand. The free remainder is shared across goals, and scenarios are compared by how they shift goal dates. The chosen scenario becomes a monthly salary-split plan. Monthly history shows earned / saved / spent. Runs on Mac and iPhone with sync, with **personal and shared budgets** for the owner and partner from the first version.
2. **Monobank, read-only.** Show where money was spent via each user's personal token. No money movement.
3. **AI assistant** as a conversational layer on top of the planner's calculations.
4. **Selling the product** only after Monobank's terms for third-party commercial use are clarified.

Intended observable result: for "saving for a house, want a vacation", the owner sees how each option moves the house date and gets per-goal monthly amounts to put into jars.

Main trade-off: personal + shared budgets from day one make the start more complex, but avoid a data migration later and are closer to a sellable product (owner chose this over personal-only).

Rejected alternatives: patching the sketch's forecast (it cannot express trade-offs, §6.1); AI first (deferred by owner: data privacy and cost, calculations first); personal-only first (owner rejected because of migration risk).

Outcome: ready-for-roadmap

Next action: turn the four ordered steps into a roadmap. Stage 1 then goes to `specify`. Check Monobank's official terms before planning stages 2 and 4 in detail.

## 8. Open questions

- **Monobank official API capabilities** (jar fields, statement for jar IDs, history depth, any write methods) | consequence: shapes stage 2 | nonblocking for stage 1, blocking for stage 2 detail | verification: open https://api.monobank.ua/docs/ in a browser (it returned 403 to automated fetch) | owner: Nikita Sydorenko
- **Third-party commercial use of Monobank data** (personal tokens vs corporate API, server/webhook needs) | consequence: may force rebuilding the integration for the product | nonblocking for stages 1–2, blocking for stage 4 | verification: read official terms or ask Monobank directly | owner: Nikita Sydorenko
- **What is personal and what is shared between partners** (which goals, incomes, expenses; who sees what) | consequence: data and sharing model | nonblocking for the roadmap, must be settled in `specify` for stage 1 | verification: decide with the partner | owner: Nikita Sydorenko
- **Exchange-rate handling for USD goals in forecasts** | consequence: trustworthiness of goal dates | nonblocking | verification: decide in `specify` | owner: unassigned
- **Who future paying customers are** | consequence: product scope and pricing | nonblocking now | verification: not established | owner: Nikita Sydorenko
