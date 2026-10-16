# Market List

Market List is an offline Flutter app for Android and iOS. Users create food shopping lists with quantities and prices, see total costs, and share lists as PDF documents or plain text. All data stays on the device in a local SQLite database.

## Status

Milestone M10 (release preparation) is complete.

### Built
- M0: Project setup, color theme, dependency injection, and router.
- M1: Core domain models for money, quantity, currency codes, normalization, and formatters.
- M2: Domain entities, repository interfaces, and use cases.
- M3: SQLite database tables, DAOs, schema snapshot version 1, and repositories.
- M4: Settings persistence, first-run currency sheet, and theme mode integration.
- M5: Lists screen with list creation, renaming, currency selection, duplication, and deletion.
- M6: List detail screen with summary card, item rows, bought status toggle, item deletion, and undo snackbar.
- M7: Item form with input validation, unit chips, line total preview, and duplicate name checks.
- M8: PDF document generation, plain text export, temp file cleanup, and share sheet integration.
- M9: Accessibility labels, search inside lists, large text support, 320 dp layout support, and architecture tests.
- M10: App launcher icons, splash screen, and Android backup configuration.

### Not built yet
- Physical device testing across Android and iOS devices.
- Manual backup and restore verification using the Android bmgr tool.
- Release signing keys and production store distribution builds.
- App store developer accounts and store listing submissions.
- Integration tests execution on a physical device or emulator.
- Roadmap items from PRD section 17.

## Features

- Manage multiple shopping lists with custom names and currencies.
- Fast item entry with name, quantity, unit, and unit price.
- Automatic line total calculation with half-up rounding.
- Real-time list total and bought item counter.
- Mark items as bought or pending.
- Delete items with a five-second undo snackbar.
- Duplicate warning when saving an item name that already exists in the list.
- Rename lists, change list currency, duplicate lists, and delete lists.
- Export lists as PDF documents or plain text via the system share sheet.
- First-run currency confirmation sheet based on device locale.
- App settings to change default currency and select light, dark, or system theme.
- Local SQLite database storage that requires no network access.

## Screens

- First-run sheet: Prompts new users to confirm their currency and creates their first list.
- Lists screen (`/`): Displays all shopping lists with item counts, totals, and management menus.
- List Detail screen (`/list`): Displays items in a list, summary totals, search, and actions to add, tick, edit, or delete items.
- Item Form screen (`/item-form`): Allows adding or editing an item with live total preview and input validation.
- Settings screen (`/settings`): Configures the default currency, theme mode, and displays app information.
- Share sheet: Bottom sheet on List Detail offering export as PDF or plain text.

## Tech stack

### Flutter environment

```
Flutter 3.38.3 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 19074d12f7 (11 months ago) • 2025-11-20 17:53:13 -0500
Engine • hash 8bf2090718fea3655f466049a757f823898f0ad1 (revision 13e658725d) (10 months ago) • 2025-11-20 20:19:23.000Z
Tools • Dart 3.10.1 • DevTools 2.51.1
```

### Dependencies

| Package | Type | Resolved version | Purpose |
| --- | --- | --- | --- |
| `flutter_bloc` | Runtime | 9.1.1 | State management using Bloc and Cubit |
| `bloc_concurrency` | Runtime | 0.3.0 | Event transformers for stream subscriptions |
| `equatable` | Runtime | 3.0.0 | Value equality for states, events, and entities |
| `fpdart` | Runtime | 1.2.0 | Functional types including Either and Unit |
| `get_it` | Runtime | 9.3.0 | Service locator for dependency injection |
| `drift` | Runtime | 2.31.0 | Typed SQLite queries, migrations, and reactive streams |
| `drift_flutter` | Runtime | 0.2.8 | SQLite database initialization on Android and iOS |
| `path_provider` | Runtime | 2.1.6 | Access to temporary directories for export files |
| `path` | Runtime | 1.9.1 | File path manipulations |
| `pdf` | Runtime | 3.12.0 | PDF document generation in pure Dart |
| `share_plus` | Runtime | 13.3.1 | Opens the system share sheet for files and text |
| `intl` | Runtime | 0.20.3 | Number grouping and date formatting |
| `uuid` | Runtime | 4.6.0 | UUID v4 generation |
| `flutter_test` | Dev (SDK) | SDK flutter | Unit and widget testing framework |
| `integration_test` | Dev (SDK) | SDK flutter | Device integration test framework |
| `flutter_lints` | Dev | 6.0.0 | Recommended lint rules for Flutter apps |
| `drift_dev` | Dev | 2.31.0 | Code generator and schema tooling for Drift |
| `build_runner` | Dev | 2.15.1 | Code generation runner |
| `bloc_test` | Dev | 10.0.0 | Testing tools for Bloc and Cubit |
| `mocktail` | Dev | 1.0.5 | Mocking library without code generation |
| `flutter_launcher_icons` | Dev | 0.14.4 | Generates launcher icons for Android and iOS |
| `flutter_native_splash` | Dev | 2.4.7 | Generates and manages the native splash screen |

## Prerequisites

- Flutter SDK (stable channel, version 3.38.3 with Dart 3.10.1).
- Android SDK and platform tools for Android builds.
- Xcode and a macOS machine for iOS builds (PRD section 18, question 8).
- A connected physical device or running emulator for running the app.

## Getting started

Run these commands in order:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Running tests

Run static analysis:

```bash
flutter analyze
```

Run unit and widget tests:

```bash
flutter test
```

Run tests with coverage collection:

```bash
flutter test --coverage
```

Run integration tests:

```bash
flutter test integration_test
```

Note: `flutter test integration_test` requires an emulator or a connected device.

### Test coverage

Milestone M10 commit reported coverage:
- Domain: 100.0%
- Blocs/Cubits: 90.9%
- Data: 98.4%
- Overall: 91.0%

## Project structure

```
lib/
  app.dart
  main.dart
  core/
    constants/
    database/
    di/
    domain/
    error/
    formatting/
    platform/
    router/
    theme/
    usecase/
    widgets/
  features/
    export/
    items/
    settings/
    shopping_lists/
```

The codebase follows clean architecture across three distinct layers: domain, data, and presentation. Domain contains business rules and entities without framework dependencies, data implements persistence and external services, and presentation handles UI and state management. See [AGENTS.md](AGENTS.md) (Import rules) and [PRD.md](docs/PRD.md) section 9.1.

## How totals work

Money is stored as whole integer minor units, representing hundredths of a currency unit. Quantity is stored as thousandths, allowing decimal quantities up to three decimal places. Each line total is calculated with integer arithmetic and rounds half up using `(quantityMilli * unitPriceMinor + 500) ~/ 1000` (PRD section 8.5).

## Limits

| Field | Limit |
| --- | --- |
| Quantity | 0.001 to 9,999.999 |
| Unit price | 0.00 to 99,999,999.99 |
| Item name | 1 to 80 characters after normalization |
| Unit | 0 to 20 characters after normalization |
| List name | 1 to 60 characters after normalization |
| Lists | 100 |
| Items per list | 500 |

## Data and privacy

- Local database: Stored locally in SQLite using Drift (`market_list.sqlite`).
- Network access: The codebase in `lib/` makes no network calls and uses no HTTP clients.
- Permissions: The Android manifest (`android/app/src/main/AndroidManifest.xml`) does not request the `INTERNET` permission.
- Phone backup: Android backup rules exist in `android/app/src/main/res/xml/backup_rules.xml` and include only the SQLite database file.

## Sharing

Sharing opens the system share sheet via `share_plus`. The user picks WhatsApp or any other application. The PDF generator requires two font files: `assets/fonts/NotoSans-Regular.ttf` and `assets/fonts/NotoSans-Bold.ttf`. Both font files exist in `assets/fonts/`.

## Known limitations

- Sharing relies on the system share sheet; direct messaging to a selected WhatsApp contact is not supported (CO-03).
- Supported currencies are limited to NGN, GHS, KES, ZAR, USD, GBP, and EUR (AS-05).
- Input allows at most two decimals for price and three decimals for quantity (PRD section 8.5).
- Maximum storage limits are 100 lists and 500 items per list (PRD section 8.3).
- The Undo action after deleting an item expires after five seconds and dismisses if the user leaves the screen (AS-16, PRD section 6.2).
- Restoring an item with Undo fails if the list has already reached 500 items (PRD section 12.1).
- Physical device testing and automated backup/restore verification have not been executed on physical hardware.

## Documentation map

| File or folder | What it holds | Who edits it |
| --- | --- | --- |
| `docs/PRD.md` | Product requirements, acceptance criteria, and system specification | Product owner |
| `AGENTS.md` | Core constraints, stack rules, and instructions for AI agents | Product owner |
| `DECISIONS.md` | Permanent log of user approvals and architectural decisions | AI agent |
| `.agents/rules/` | Safety constraints and protected file rules for AI agents | Product owner |
| `.agents/skills/` | Specialized agent workflows and task guides | Product owner |
| `analysis_options.yaml` | Static analysis rules and linter configurations | Product owner |
| `test/architecture_test.dart` | Automated tests verifying layer isolation and import rules | AI agent during M9; protected afterwards |

## Building with the AI agent

Development proceeds through milestones in order from M0 setup to M10 release preparation. Every milestone commit uses the prefix `M<number>:` to record progress and test coverage. [DECISIONS.md](DECISIONS.md) acts as the permanent record for approved choices and defaults. See [AGENTS.md](AGENTS.md) for full project rules and workflow requirements.

## Roadmap

- Backup and restore (v1.1, not built): Export all lists to a JSON file and import them on a new phone.
- Categories with subtotals (v1.2, not built): Group items by category and show subtotals per group.
- Item memory (v1.2, not built): Suggest names, units, and past prices during item entry.
- PDF options (v1.3, not built): Toggle prices on or off in the PDF and display remaining to buy totals.
- More languages and number formats (v2.0, not built): Localize the user interface, support comma decimals, and add zero-decimal currencies.
