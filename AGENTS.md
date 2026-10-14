# AGENTS.md

## Project and precedence
- Market List is an offline Flutter app for Android and iOS. Users write food shopping lists (name, quantity, unit, unit price), see totals, and share a list as PDF or text through the system share sheet.
- Spec: `docs/PRD.md`. If this file does not exist, stop and ask the user. Do not build from memory.
- Where this file and the PRD differ, this file wins.
- Before each milestone, read that milestone in PRD section 15 and every PRD section it names.
- ID prefixes: FR is a functional requirement. NFR is a non-functional requirement. AS is an assumption, AD is an addition, CO is a correction. Cite IDs in commits and test names.
- Placeholders: app name "Market List", package ID `com.example.marketlist`. Use them everywhere until the user gives final values.
- When a fact is missing or the PRD is unclear: if PRD section 18 has a default for that question (it covers 13 questions only), use it and record it in `DECISIONS.md`. Otherwise stop and ask the user in chat, then record the answer in `DECISIONS.md`.

## Approvals and scope
- Before M0, ask the user to approve or reject each row of PRD section 2. Record the answers in `DECISIONS.md`.
- If the user rejects a row, stop and ask how the PRD changes. Do not improvise a replacement.
- Follow the milestone order in Workflow. Inside a milestone, build Must requirements first, then Should, then Could.
- Build only what PRD sections 4 and 5 require. Do not build PRD section 17.
- Do not build accounts, cloud sync, price lookup, barcode scan, payments, direct WhatsApp chat sending, tablet layouts, or web or desktop builds.

## Stack (locked)
- Flutter and Dart. Use the Flutter stable version installed on this machine. Do not change it. Write its `flutter --version` output in `README.md`.
- State: `flutter_bloc`. One Bloc: `ListDetailBloc`. Four Cubits: `SettingsCubit`, `ListsCubit`, `ItemFormCubit`, `ShareCubit`.
- Database: Drift on SQLite (`drift`, `drift_flutter`; dev: `drift_dev`, `build_runner`).
- Other runtime packages: `bloc_concurrency`, `equatable`, `fpdart`, `get_it`, `path_provider`, `path`, `pdf`, `share_plus`, `intl`, `uuid`.
- Other dev packages: `bloc_test`, `mocktail`, `integration_test`, `flutter_lints`, `flutter_launcher_icons`, `flutter_native_splash`.
- Routing: plain `Navigator` with `onGenerateRoute` in `lib/core/router/app_router.dart`. Routes: `/`, `/settings`, `/list`, `/item-form`.
- Add only the packages listed above, with `flutter pub add <name>` or `flutter pub add --dev <name>`. Let pub resolve versions. Record resolved versions in `README.md`.
- If a package API differs from the PRD, follow the installed package's documentation and record the difference in `DECISIONS.md`.
- If a task needs a package outside this list, stop that task and ask the user. Never use `go_router`, `printing`, `shared_preferences`, `url_launcher`, any WhatsApp plugin, or any analytics or crash package.

## Commands
- `flutter analyze` must return no issues.
- `flutter test`
- `flutter test --coverage`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter build apk --debug`
- `flutter test integration_test` needs an emulator or device. If none exists, do not run it. Write "integration test not run: no device" in the milestone commit message.

## Structure
- `lib/core/`: `constants`, `domain`, `error`, `usecase`, `di`, `database`, `platform`, `formatting`, `router`, `theme`, `widgets`.
- `lib/features/`: `shopping_lists`, `items`, `export`, `settings`. Each has `domain`, `data`, `presentation`.
- `test/` mirrors `lib/`. Integration tests live in `integration_test/app_flow_test.dart`.
- Create only the files and folders in PRD section 9.1. Files made by `flutter create` and `build_runner` are exempt. Ask before adding any other file or folder.

## Import rules
- `domain`: pure Dart. May import `fpdart`, `equatable`, `intl` (to format only), `core/domain`, `core/error`, `core/formatting`, `core/usecase`, `core/constants`, `core/platform`. Never imports `flutter`, `drift`, `pdf`, `share_plus`, `path_provider`, `data`, or `presentation`.
- `data`: implements domain interfaces. May import `core/database`. May import `flutter/services.dart` only to load font assets. Never imports `presentation`.
- Only `data` and `core/database` import `drift`. Only `data` imports `pdf`, `share_plus`, and `path_provider`.
- `presentation`: calls use cases only. May import `domain`, `core`, `flutter`, `flutter_bloc`, `bloc_concurrency`, `equatable`, `fpdart`, `get_it`. Never imports `data`, `drift`, `pdf`, `share_plus`, `path_provider`.
- `core/di` and `core/router` may import all layers.
- Cross-feature imports allowed, and no others:
  - `export` may import `items`, `shopping_lists`, and `settings` domain.
  - `items` may import `shopping_lists` domain.
  - `settings` may import `shopping_lists` domain (`CompleteOnboarding` returns a `ShoppingList`).
  - `shopping_lists/presentation` may read `SettingsCubit` state to get the default currency. It imports nothing else from `settings`.
  - `items/presentation` may import `ShareCubit` and the share sheet from `export/presentation`.
- Pages reach other pages only through `core/router`.
- Add `test/architecture_test.dart` in M9. It fails when an `import` line breaks these rules. Before M9, check imports by hand at each milestone.

## Use cases and errors
- One use case per class. One public class per file.
- `UseCase<Output, Params>` returns `Future<Either<Failure, Output>>`. `StreamUseCase` returns `Stream<Either<Failure, Output>>`. `ValidateItemDraft` is synchronous.
- Use cases, Blocs, and Cubits do not throw. Repositories catch exceptions and return `Left(Failure)`. Each repository test includes a case where the data source throws and the repository returns a `Left`.
- `Failure` is a sealed class in `core/error/failures.dart`. Cases: `ValidationFailure`, `NotFoundFailure`, `LimitFailure`, `StorageFullFailure`, `SchemaTooNewFailure`, `DatabaseFailure`, `ExportFailure`, `ShareFailure`, `UnexpectedFailure`.
- Exception mapping: a `SqliteException` with result code SQLITE_FULL maps to `StorageFullFailure`. A schema version above the app's maps to `SchemaTooNewFailure`. Any other `SqliteException` maps to `DatabaseFailure`. Any other exception maps to `UnexpectedFailure`.
- The domain returns `Failure` values, not text. `presentation/failure_messages.dart` maps each `Failure` to its text.
- Copy every message in PRD section 12 character for character. Other screen text follows PRD section 6.
- Never show a raw exception to the user.

## Money and data rules
- Never use `double` for money or quantity.
- A minor unit is one hundredth of the currency. 1,500.50 is stored as 150050. A quantity of 2.5 is stored as 2500 (thousandths).
- Supported currencies: NGN, GHS, KES, ZAR, USD, GBP, EUR. All use 2 decimals. Symbols: ₦, GH₵, KSh, R, $, £, €.
- Parse input text with string operations, not `double.parse`.
- Line total: `(quantityMilli * unitPriceMinor + 500) ~/ 1000`. List total: the sum of line totals.
- The Lists DAO sums totals in SQL with `SUM((quantity_milli * unit_price_minor + 500) / 1000)`. The Dart formula is the source of truth. A parity test on 1,000 random rows must pass.
- Format money by grouping the whole part with `intl` and appending a dot and the two-digit fraction. Never pass the amount through `double`. The formatter takes the currency as a parameter and reads no global state. Locale is `en_US`.
- Currency is stored per list (`shopping_lists.currency_code`). Settings holds only the default for new lists. Changing a currency never converts amounts.
- Quantity must be greater than 0. Price may be 0.
- Normalize item name, unit, and list name in this order: replace each run of whitespace (spaces, tabs, line breaks) with one space, remove Unicode control characters, trim both ends. An empty unit becomes `null`.
- Limits: 100 lists, 500 items per list, item name 80 characters, list name 60, unit 20, quantity 0.001 to 9,999.999, price 0 to 99,999,999.99. Count characters as Unicode code points (`runes.length`). Never use `String.length` for limits.

## Database lock
- The database has exactly three tables: `shopping_lists`, `shopping_items`, `app_settings`. Columns, types, and constraints are in PRD section 8.2.
- Do not add, rename, or drop a table, column, index, or constraint. Schema version stays 1. If a requirement seems to need a schema change, stop and ask the user.
- File: `market_list.sqlite`. Set `PRAGMA foreign_keys = ON` and `PRAGMA synchronous = FULL`. Do not enable WAL. Add a test that reads `PRAGMA journal_mode` and expects `delete`. If it returns another value, stop and ask the user.
- Ids are UUID v4. `created_at` and `updated_at` are INTEGER UTC epoch milliseconds.
- Every write is one transaction.
- Adding, editing, deleting, restoring, or ticking an item, and renaming or changing the currency of a list, set `updated_at` on the parent list in the same transaction.
- Item read order: `created_at ASC, id ASC`.
- If the database cannot open, or its schema is newer than the app, show the error from PRD section 12.2 and stop. Do not migrate, write to, or delete the file.
- In M3, dump schema version 1 with the Drift schema tools into `drift_schemas/` (PRD section 8.7).

## First run
- On first launch (`onboarding_done` = 0), show the "Choose your currency" sheet. The sheet closes only through Continue.
- Continue runs one transaction: save the default currency, create the list "Market list" in that currency, set `onboarding_done` to 1. Then open that list.
- Details: PRD FR-092 and section 6.0.

## State and routes
- Holders, events, states, and transitions: PRD section 10. Routes, arguments, and results: PRD section 6. Follow them exactly.
- Deleting from the Item Form pops with the deleted `ShoppingItem`.
- Initial status is `loading` in `SettingsCubit`, `ListsCubit`, `ListDetailBloc`, and `ItemFormCubit` in edit mode.
- Empty is derived (`success` with an empty collection). It is never a status.
- One-time effects (snackbar, navigation, dialog) use a nullable state field and a `BlocListener`. A "handled" call clears the field.
- States extend `Equatable` and have `copyWith`. Events extend `Equatable`.
- Check `isClosed` before emitting after an `await`.
- Widgets read state only. They call no repository or use case.
- A field is touched after the user moves focus away from it. Item form errors show for a field only when it is touched or after submit.
- Undo after deleting an item lasts 5 seconds. It clears when the user leaves List Detail or opens the Item Form. Restore obeys the 500 item limit.
- Business logic means validation, money math, limits, normalization, and duplicate checks. It lives in `domain`. Blocs and Cubits call it and may filter data for display.

## UI rules
- Material 3. Build each `ColorScheme` with `ColorScheme.fromSeed(seedColor: Color(0xFFF57C00), brightness: ...)` then `copyWith` every token in PRD section 7.
- Light primary `#F57C00`. On-primary `#1A1A1A`. Orange text and focus borders on light surfaces use `#B45200`.
- Flutter UI code takes colors from `Theme.of(context).colorScheme` or the `AppColors` extension. Never hard-code a color in a widget. The PDF generator uses the hex values in PRD section 11.1.
- Money text uses tabular figures. The summary total sits in `FittedBox(fit: BoxFit.scaleDown)`.
- Minimum touch target 48 x 48 dp. No overflow at 320 x 568 dp or at text scale 2.0.

## PDF and sharing
- PDF layout, file name, share flow, and text format: PRD section 11. Follow them exactly. Share is disabled for an empty list.
- Build the PDF with `pdf`. Use `assets/fonts/NotoSans-Regular.ttf` and `NotoSans-Bold.ttf`. If a file is missing, stop and ask the user for it. Do not download fonts.
- Load font bytes with `rootBundle` on the main isolate. Pass the bytes and plain data into `Isolate.run`.
- Share with `share_plus` through the system share sheet. Do not detect WhatsApp. Do not add a WhatsApp SDK.
- Generate a PDF with the symbols ₦, GH₵, £, and €. Inspect the output and state the result in the commit message. If you cannot inspect it, write "glyphs not verified". If a glyph is missing, add a fallback font.

## Platform
- Minimum OS: Android 7.0 (API 24) and iOS 13. Check them against the Flutter minimums and record the result in `DECISIONS.md`.
- Android: `allowBackup="true"` with rules that include only the database file (PRD section 8.6).
- The release app requests no permissions.

## Conventions
- Files use `snake_case`. Classes use `PascalCase`.
- Use case file and class: verb and noun (`add_item.dart`, `AddItem`). Implementations end with `Impl`.
- Bloc files come in threes (`_bloc`, `_event`, `_state`). Cubit files come in pairs.
- No widget class is longer than 150 lines. Use `const` constructors.
- Test names include the requirement ID, for example `FR-061 rounds half up`.
- Coverage targets: domain 95 percent, blocs and cubits 90, data 85, overall 80. After each milestone, read `coverage/lcov.info` per folder and write the four numbers in the commit message.
- Do not edit `*.g.dart` files. Add the line `*.g.dart` to `.gitignore`. Regenerate with `build_runner`.

## Workflow
- Milestone order: M0 setup, M1 core, M2 domain, M3 data, M4 settings and first run, M5 lists screen, M6 list detail, M7 item form, M8 PDF and share, M9 quality, M10 release. Tasks and done criteria are in PRD section 15.
- Do not start a milestone until its Verify command in PRD section 15 passes, plus `flutter analyze` and `flutter test`.
- Stop after M9. Start M10 only when the user says so. Never create or commit signing keys.
- Commit after each milestone. Example message: `M3: data layer (FR-080 to FR-083)`. If the folder is not a git repository, ask the user before committing.
- List each device-only check in the milestone commit message under "Manual checks: not run". Write "passed" only after the user confirms.

## Never
- Never add network code, analytics, or a crash SDK.
- Never add the `INTERNET` permission to the main Android manifest.
- Never print or log list names, item names, units, quantities, or prices.
- Never put validation, money math, limits, normalization, or duplicate checks in widgets, Blocs, or Cubits.
- Never continue past a missing fact. Stop and ask the user in chat.
