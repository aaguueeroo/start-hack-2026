# start_hack_2026

A simulator to learn investments.

## Overview

This is a Flutter-based investment learning game where you build a portfolio, acquire knowledge, and run simulations to see how your choices play out over time. Your character's traits, the knowledge you gain, and the assets you hold all shape your financial journey.

## Features

### Choose a Character

At the start of each game, you pick a character. Each character has **initial stats** and a **unique skill** that affect the development of the whole game:

- **Initial stats** include money, risk tolerance, financial knowledge, asset slots, annual income, emotional reaction, knowledge, investment horizon, savings rate, and behavioral bias.
- **Unique skills** define a character's edge—for example: "Thrives on volatility", "Extra asset slots", "Lower volatility impact", "Higher annual income growth", "Better market timing", or "Steady returns".

Your choice shapes how you can invest, how you react to market swings, and how your portfolio evolves.

### Knowledge

Knowledge is obtained through store items (e.g. "Read a Book", "Take an Online Course", "Consult a Financial Advisor"). Once acquired, **knowledge cannot be removed**—it permanently improves your stats.

Knowledge items can be **combined to increase their level** (up to level 3). When you own two identical items of the same level, you can merge them into a single higher-level item with stronger stat effects. This lets you deepen your expertise over time.

### Assets

Financial assets (stocks, bonds, funds, etc.) can be **bought and sold at any time** in the store. Each asset has properties such as expected return, volatility, liquidity, and management cost. You can adjust your portfolio freely as your strategy or market conditions change.

### Simulations

Simulations run your portfolio through time and **show events** as they occur. Events fall into three types:

- **Market** — e.g. market crash, rally, tech boom (affect asset returns)
- **Character** — personal events that influence your decisions
- **World** — macroeconomic events like interest rate hikes, inflation surge, recession fears

Each event displays a title, description, and your portfolio value at that moment. The simulation illustrates how your choices and external events interact over the years.

### Achievements

Players are encouraged to test different strategies and see how the market reacts.  
Here is a sample list of potential achievements:

- **Panic Seller**  
  Sell an asset right before it goes up in value.

- **Bookworm Investor**  
  Buy your first knowledge item.

- **MBA**  
  Merge knowledge items to reach level 3.

- **Don’t Put All Eggs in One Basket**  
  Reach a high diversification score with a balanced portfolio.

- **Buy High, Cry Later**  
  Purchase an asset and end the same simulation year at a loss.

- **Hands in Pockets**  
  Start a store phase and buy absolutely nothing.

- **Instant Noodle to IPO**  
  Finish a simulation with portfolio value at least 2x your starting money.

- **Crash Test Investor**  
  Survive a market crash event and still end the year positive.

- **Grip of Steel**  
  Hold a volatile asset through a full simulation without selling.

## Project setup

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) installed and on your `PATH` (stable channel is fine).
- This app targets **Dart SDK ^3.11.1** (see `pubspec.yaml`). Run `flutter --version` and upgrade Flutter if `dart --version` is too old.

### 1. Install dependencies

Open a terminal in the project root (the folder that contains `pubspec.yaml`), then:

```bash
flutter pub get
```

If you are cloning fresh:

```bash
git clone <REPOSITORY_URL>
cd start-hack-2026
flutter pub get
```

### 2. Environment (optional — Supabase / leaderboard)

The app runs without Supabase; leaderboard features fall back to local data when credentials are missing.

To enable Supabase, create a `.env` file in the project root (same folder as `pubspec.yaml`). It is gitignored:

```bash
touch .env
```

Add your project URL and anon key:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Alternatively, pass them at build/run time:

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### 3. Run the app

List devices, then run on one of them:

```bash
flutter devices
flutter run
```

Examples for a specific target:

```bash
flutter run -d chrome
flutter run -d macos
flutter run -d ios
```

### 4. Checks (optional)

```bash
flutter analyze
flutter test
```

### Further reading

- [Flutter documentation](https://docs.flutter.dev/)
- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
