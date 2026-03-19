# InvestQuest – Agent Context

## Project Overview

**InvestQuest** is a Flutter investment learning game for younger audiences. The goal is to make investing engaging through a card-based game. Current state: character selection → store (buy assets/knowledge) → simulation (yearly portfolio run).

## Tech Stack

- **Flutter** (Dart 3.11+)
- **Provider** – state
- **go_router** – navigation
- **fl_chart** – simulation chart
- **google_fonts**, **widget_tooltip**

## Architecture

```
lib/
├── app.dart              # MultiProvider, GoRouter
├── main.dart
├── core/                 # Theme, widgets, constants
├── domain/               # Entities (Character, StoreItem, SimulationEvent, etc.)
├── data/                 # Repositories, JSON loaders
├── engine/               # GameEngine, SimulationEngine, CalculationEngine
├── modules/              # Controllers (GameController, StoreController, SimulationController)
└── features/             # Screens (home, character_selection, store, simulation, achievements, leaderboard)
```

## Key Concepts

### Game Flow

1. **Home** → New Game / Achievements / Leaderboard
2. **Character Selection** → Pick character with initial stats + unique skill
3. **Store** → Buy knowledge items, buy/sell assets, combine items (L1+L1→L2)
4. **Simulation** → Run 12-month simulation, see portfolio + events

### Stats (Real-World Factors)

- **monthlySavings** – Amount saved and invested each month (paid at end of month)
- **riskTolerance** – Affects forced selling during volatility
- **return**, **volatility** – Portfolio metrics from holdings
- Other: financialKnowledge, assetSlots, knowledgeSlots (item capacity per character), emotionalReaction, knowledge, savingsRate, behavioralBias

### Data (JSON in `assets/data/`)

- `characters.json` – initialStats, uniqueSkill
- `items.json` – Knowledge items (statEffects, level, price)
- `assets.json` – Financial assets (expectedReturn, volatility, liquidity, managementCost)
- `events.json` – Market events: `marketImpact`, `riskyAssetImpact`, `safeAssetImpact`, `probability` (relative weight), optional `durationMonthsRange` `[min,max]`, optional `descriptions` (random headline per trigger; falls back to `description`)
- `stats_schema.json` – Stat metadata (displayName, min, max, category)

### Engines

- **GameEngine** – Game state, purchases, combine, sell, completeSimulation; holds `AssetCalculationEngine`
- **AssetCalculationEngine** – Single source for all asset calculations: totalValue, costBasis, totalReturnPercent, applyReturnFactor, portfolioValue, generateRandomReturn
- **SimulationEngine** – Runs monthly simulation, yields `SimulationResult` (portfolioValue, activeEvents, event); uses AssetCalculationEngine
- **CalculationEngine** – Portfolio stats, item effects, PortfolioAsset entity

### Simulation Details

- 12 months, 4 ticks/month, 48 ticks total
- Monthly savings added at end of month (`(tick + 1) % ticksPerMonth == 0`)
- Events: market/world/character, duration, impact on risky vs safe assets (volatility ≥ 12 = risky)
- Events: master trigger roll per tick after cooldown, then weighted pick by `probability`; ~80% avoid repeating the same `id` as the previous event (repeats still possible, with a new random `descriptions` line); 2-month cooldown
- `getActiveEvents()` – current active events and their impact

## UI Conventions

- **GameTheme** – cream background, primary dark, stat positive/negative
- **GameCard**, **GameButton**, **GameKeyFactorsBar** – shared widgets
- **GameKeyFactorsBar** – Shows monthlySavings, riskTolerance, return, volatility at top of Store and Simulation
- Chart: `_SimulationChart` – event markers on line, hover/touch tooltips for event details

## Routes

| Path | Screen |
|------|--------|
| `/` | HomeScreen |
| `/character-selection` | CharacterSelectionScreen |
| `/store` | StoreScreen |
| `/simulation` | SimulationScreen |
| `/achievements` | AchievementsScreen (placeholder) |
| `/leaderboard` | LeaderboardScreen (placeholder) |

## Future Direction

- Card-based game for younger players
- Short rounds, strong feedback, meta progression
- Possible: deck/hand mechanics, event cards, win conditions

## Gotchas

- **monthlySavings** must be in stats for display and simulation; fallbacks exist in `getDisplayStats` and `startSimulation`
- Events use `durationMonths`, `marketImpact`, `riskyAssetImpact`, `safeAssetImpact` – no string-based detection
- `completeSimulation` preserves holdings (with updated values) and itemSlots; only `startNewGame` resets them
