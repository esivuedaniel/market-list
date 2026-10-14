# PRD v2: Market List (Flutter shopping list app)

**Status:** Revised after a live review. Appendix A maps every change to a review finding (R1 to R28).

**Note for the AI agent:** Read section 19 first, then follow sections 4 to 15 in order. Every requirement has an ID. Cite the ID in commit messages and test names.

## 1. Overview

**Product summary.** Market List is an offline Flutter app for Android and iOS. Users build shopping lists of food items with a quantity and a price, see the total cost, and share a list as a PDF through WhatsApp. All data stays on the device in a local SQLite database.

**Problem.** People who plan a market trip write items and prices on paper or in chat notes. They add up totals by hand, make mistakes, and cannot send a clean list to the person who will buy.

**Target users**

- Household shoppers who plan a weekly food budget.
- Small food sellers and caterers who send a buy list to a runner.
- Anyone who asks another person to shop for them.

**Main use case.** The user opens a list, adds items with quantity and price, checks the total, then shares the list as a PDF on WhatsApp.

**Business stance.** Version 1.0 is free. It has no ads, no purchases, and no revenue goal. If you plan to sell the app, answer Open Question 11 before the build.

**Goals and how to test them**

| ID | Goal | Test |
| --- | --- | --- |
| G1 | Fast entry | 4 of 5 test users add an item (name, quantity, price) in 15 seconds or less, timed from tapping Add item to seeing the row. No help given. |
| G2 | Correct totals | The list total equals an independent BigInt calculation on 500 random items. PDF rows add up exactly to the PDF total. |
| G3 | Data safety | 0 lost or partial items across 20 force-stop cycles during adds, edits and deletes. |
| G4 | Easy sharing | 4 of 5 test users reach WhatsApp with the PDF attached in 60 seconds or less from opening a list. At most 3 taps from the share icon on Android and 4 on iOS (iOS may need More). |
| G5 | Brand | The light theme uses orange as the primary color (section 7). |
| G6 | Post-launch health | Crash-free users at 99 percent or more, read from Play Console and App Store Connect. Track day 7 retention and uninstall rate. Set their targets after the first 200 installs. |

**Non-goals (MVP)**

- No user accounts, cloud sync, or backend.
- No online price lookup, barcode scan, payments, or delivery.
- No ads, analytics SDKs, or crash SDKs. The app sends no data off the device.
- No web, desktop, or tablet-optimized layouts.
- No direct message to a chosen WhatsApp contact. The app uses the system share sheet (CO-03).

## 2. Assumptions, Additions, and Corrections

This table holds 39 decisions beyond your original brief. Approve or reject each one before the build starts. The rest of the PRD uses these IDs.

| Tag | ID | Description | Reason | Impact if rejected |
| --- | --- | --- | --- | --- |
| [CORRECTION] | CO-01 | "Safe in the local database" means saved on the device and crash-safe. It does not mean backed up. | A local database is lost with the phone unless the phone backup restores it. | None. This sets expectations. The app says so in About. |
| [CORRECTION] | CO-02 | The "input field" becomes one form with separate fields: name, quantity, unit, price. | One text field cannot validate numbers well. | Parsing free text adds errors and rework. |
| [CORRECTION] | CO-03 | Sharing uses the system share sheet. The user picks WhatsApp, then a contact. | Flutter cannot send a file to a chosen contact without unofficial hacks. | Direct send needs platform channels and breaks when WhatsApp changes. |
| [CORRECTION] | CO-04 | "Orage" is read as Orange. Primary is #F57C00 with dark on-primary text. | White text on this orange fails contrast rules. | White text on orange is hard to read outdoors. |
| [ASSUMPTION] | AS-01 | Price is the unit price. Line total = quantity x unit price. | Market prices are usually per kg, piece, or bag. | The data model and total formula change. |
| [ASSUMPTION] | AS-02 | Quantity may be a decimal with up to 3 places (for example 1.5 kg). | Food is often bought by weight. | Quantity becomes a whole number only. |
| [ASSUMPTION] | AS-03 | Price may be 0 (unknown price). Quantity must be greater than 0. | The user may not know a price yet. | Price must be greater than 0. |
| [ASSUMPTION] | AS-04 | Money is stored as integer minor units. Quantity is stored as integer thousandths. Each line total rounds half up. | Avoids floating point errors. PDF rows then sum exactly to the total. | Totals can drift by one minor unit. |
| [ASSUMPTION] | AS-05 | Supported currencies: NGN, GHS, KES, ZAR, USD, GBP, EUR. All use 2 decimals. The first-run sheet preselects from the device locale, else USD. | A small fixed list keeps formatting and PDF fonts safe. | Other currencies need new rules. |
| [ASSUMPTION] | AS-06 | Numbers display as 1,250.50. Number input accepts digits and one dot. | Keeps parsing simple and predictable. | Comma-decimal locales need locale-aware parsing. |
| [ASSUMPTION] | AS-07 | The app is English only in the MVP. | You did not ask for other languages. | Add localization setup now. |
| [ASSUMPTION] | AS-08 | Minimum OS: Android 7.0 (API 24) and iOS 13. The agent checks these against current Flutter minimums. | Covers nearly all active phones. | Higher minimums drop some users. |
| [ASSUMPTION] | AS-09 | Limits: 100 lists, 500 items per list, item name 80 characters, list name 60, unit 20. | Keeps the UI and PDF fast. | Limits need new numbers. |
| [ASSUMPTION] | AS-10 | The database is Drift on SQLite. | Typed queries, migrations, reactive streams, in-memory tests. | Another database needs a new data layer spec. |
| [ASSUMPTION] | AS-11 | A dark palette exists. It follows the system setting by default. | Standard on modern phones. | Light mode only. |
| [ASSUMPTION] | AS-12 | Android Auto Backup stays on with explicit rules (section 8.6). iOS keeps its default iCloud backup. | Free protection against phone loss. | Data never restores automatically. |
| [ASSUMPTION] | AS-13 | Build with the latest stable Flutter and Dart. The agent records the exact version in README. | I cannot confirm the version from here. | None. |
| [ASSUMPTION] | AS-14 | Items sort oldest first. New items appear at the bottom. Bought items stay in place. | Matches a paper list. | Newest first is a one-line change. |
| [ASSUMPTION] | AS-15 | Saving an item whose normalized name already exists in the list shows a warning and lets the user continue. Applies to add mode, and to edit mode when the name changes. | Two lines of one food can be valid (two markets). | Duplicates are blocked or allowed silently. |
| [ASSUMPTION] | AS-16 | The Undo window after deleting an item is 5 seconds. | Long enough to react, short enough to avoid stale state. | Pick another number. |
| [ASSUMPTION] | AS-17 | Unit quick-pick chips: kg, g, pcs, bag, bunch, litre, crate. | Common market units. | Other chips need a new list. |
| [ASSUMPTION] | AS-18 | Export files in the temp folder are deleted after 24 hours. | Avoids clutter. The OS also clears temp storage. | Files stay until the OS clears them. |
| [ASSUMPTION] | AS-19 | The share text "Shopping list: <name>" is a best-effort caption. WhatsApp may ignore it. | Caption behavior depends on OS and app version. | No caption text. |
| [ASSUMPTION] | AS-20 | List totals on the Lists screen come from a SQL sum that mirrors the Dart formula. A parity test guards it. | Summing 50,000 rows in Dart is too slow. | Slower Lists screen with large data. |
| [ADDITION] | AD-01 | Multiple lists with a Lists screen. Priority: Must. | One list per trip, and each PDF is per list. | One implicit list. Sections 4 and 6 change. |
| [ADDITION] | AD-02 | Optional unit label per item. Priority: Should. | "2" alone is unclear to a buyer. | Quantity has no unit in the PDF. |
| [ADDITION] | AD-03 | Bought checkbox per item. Priority: Should. | Users tick items off in the market. | No progress tracking. |
| [ADDITION] | AD-04 | Undo after deleting an item. Priority: Should. | Prevents accidental data loss. | Add a confirm dialog on every delete. |
| [ADDITION] | AD-05 | Currency is stored per list. Settings holds the default for new lists. Priority: Must. | A saved list is a record. A global switch would relabel old lists and old PDFs. | One global currency that rewrites history. |
| [ADDITION] | AD-06 | Share the list as plain text. Priority: Should. | Works when a PDF is too heavy. | PDF only. |
| [ADDITION] | AD-07 | Search items inside a list. Priority: Could. | Helps with long lists. | No search. |
| [ADDITION] | AD-08 | Duplicate a list. Priority: Could. | Weekly lists repeat. | Users retype lists. |
| [ADDITION] | AD-09 | "Save and add another" button on the add form. Priority: Should. | Speeds up entering many items. | Users reopen the form each time. |
| [ADDITION] | AD-10 | Theme setting: System, Light, Dark. Priority: Should. | Pairs with AS-11. | Follows the system only. |
| [ADDITION] | AD-11 | A tick box column in the PDF, filled for bought items. Priority: Should. | The buyer can tick items on screen or print. | No tick column. |
| [ADDITION] | AD-12 | Live line total preview in the item form. Priority: Should. | Catches typing mistakes before saving. | No preview. |
| [ADDITION] | AD-13 | First-run setup: a currency confirm sheet, then a default list named "Market list". Priority: Must. | A wrong currency on a shared list is the worst bug. A new user needs a list to start. | Silent currency guess and an empty first screen. |
| [ADDITION] | AD-14 | Swipe left on an item row to delete. Priority: Should. | Fast delete, covered by Undo. | Menu delete only. |
| [ADDITION] | AD-15 | Change the currency of an existing list. Priority: Should. | The user may pick the wrong currency. | The user must recreate the list. |

Left out on purpose: categories, manual sort, price history, and in-app backup. They live in section 17.

## 3. User Personas and User Stories

**Personas**

| Persona | Who they are | What they need |
| --- | --- | --- |
| Ada, the planner | Household shopper. Plans a weekly food budget on her phone. | A fast list, a reliable total, and a way to check spend before she leaves home. |
| Musa, the food seller | Runs a small kitchen. Sends a buy list to a runner each morning. | A clean PDF with quantities, units, and prices that the runner opens in WhatsApp. |
| Ife, the runner | Buys items in the market for someone else. Receives the PDF. | A readable list with a tick box for each item. Ife does not need the app. |

**User stories**

| ID | Story | Covered by |
| --- | --- | --- |
| US-01 | As Ada, I want to create a named list, so that I can keep one list per trip. | FR-001, FR-092 |
| US-02 | As Ada, I want to add an item with quantity and price, so that I see what it costs. | FR-010, FR-011 |
| US-03 | As Ada, I want to see all items with quantity, price, and line total, so that I can review the list. | FR-020, FR-021 |
| US-04 | As Ada, I want to edit an item, so that I can fix a wrong price or quantity. | FR-030 |
| US-05 | As Ada, I want to delete an item and undo the delete, so that a wrong tap costs me nothing. | FR-040, FR-041 |
| US-06 | As Ada, I want to see the total for the whole list, so that I know how much money to carry. | FR-060, FR-061, FR-063 |
| US-07 | As Musa, I want to share the list as a PDF on WhatsApp, so that my runner gets a clean list. | FR-070, FR-072, FR-073 |
| US-08 | As Musa, I want to share the list as text, so that I can send it fast. | FR-071 |
| US-09 | As Ada, I want to tick items as bought, so that I track progress in the market. | FR-050 |
| US-10 | As Ada, I want my lists saved on my phone with no internet, so that I never lose them. | FR-080 to FR-083 |
| US-11 | As Musa, I want each list to keep its own currency, so that old lists never change symbol. | FR-007, FR-090, FR-092 |
| US-12 | As Ife, I want a tick box next to each item in the PDF, so that I can mark items as I buy them. | FR-070 (AD-11) |

## 4. Functional Requirements

Priority key: Must = ships in v1.0. Should = ships in v1.0 unless time runs out. Could = ships after Must and Should are done. Limits are in section 8.3. Messages are in section 12. Each list has its own currency (AD-05). Examples below use plain numbers for that reason.

### 4.1 Lists (AD-01)

- **FR-001 (Must) Create a list.** The new list takes the default currency from Settings.
    - Given the Lists screen is open, when the user taps New list, keeps or edits the default name "Market list", and taps Create, then the app saves the list with the default currency and opens its List Detail screen in the empty state.
- **FR-002 (Must) Show all lists.** Each card shows name, item count, total in the list's currency, and last updated date. Order: last updated first.
    - Given 3 lists exist, when the Lists screen opens, then 3 cards appear with correct counts and totals.
- **FR-003 (Must) Rename a list.**
    - Given a list named "Market list", when the user chooses Rename, types "Sunday market", and taps Save, then the card and the List Detail title show "Sunday market".
- **FR-004 (Must) Delete a list.** A confirm dialog shows first. Deleting a list deletes its items.
    - Given a list with 5 items, when the user chooses Delete and confirms, then the list and its 5 items disappear for good.
- **FR-005 (Could) Duplicate a list.** The copy is named "<name> (copy)". It keeps the currency. Items copy over with bought set to false.
    - Given a list with 4 items where 2 are bought, when the user chooses Duplicate, then the new list has 4 items and 0 bought.
- **FR-006 (Must) List limit.** The app allows at most 100 lists.
    - Given 100 lists exist, when the user taps New list or Duplicate, then the app shows the limit message and creates nothing.
- **FR-007 (Should) Change a list's currency.** The list menu offers Change currency. A dialog lists the 7 currencies and says "Prices are not converted." Amounts stay the same. AD-15.
    - Given a list in USD, when the user picks NGN, then every amount in that list shows the NGN symbol, no number changes, and other lists keep their currency.

### 4.2 Add item

- **FR-010 (Must) Add an item.** Fields: Item name (required), Quantity (required), Unit (optional), Unit price (required). Save writes the item to the open list.
    - Given the Add item screen, when the user enters "Tomatoes", "2.5", "kg", "1500" and taps Save, then the app returns to the list and shows the item with line total 3,750.00.
- **FR-011 (Must) Validate input.** Rules and messages are in section 12.1. A field shows its error after the user leaves it, or after the user taps Save.
    - Given the name field is empty and untouched, when the user taps Save, then the app shows "Enter an item name." and saves nothing.
- **FR-012 (Should) Save and add another.** The add form has a second button. It saves, clears the form, and focuses the name field. AD-09.
    - Given a valid form, when the user taps Save and add another, then the item saves and the form is empty with the name field focused.
- **FR-013 (Should) Line total preview.** The form shows the live line total under the price field. AD-12.
    - Given quantity 2.5 and price 1500, when the user types the price, then the preview shows 3,750.00.
- **FR-014 (Must) Item limit.** At most 500 items per list.
    - Given a list has 500 items, when the user taps Add item, then the app shows the limit message and does not open the form.
- **FR-015 (Should) Duplicate name warning.** The check uses the normalized name (section 8.4) and ignores case. It runs in add mode, and in edit mode when the normalized name differs from the saved name. AS-15.
    - Given "Tomatoes" exists, when the user saves a new item named "tomatoes " then a dialog asks Add anyway or Cancel.
    - Given an item "Onions" is open for edit, when the user renames it to "Tomatoes" and taps Save, then the same dialog shows.
- **FR-016 (Should) Unit suggestions.** Chips from AS-17 fill the Unit field when tapped. The user may type any text.
    - Given the Unit field is empty, when the user taps the kg chip, then the field shows "kg".

### 4.3 View list

- **FR-020 (Must) Show items.** Each row shows a bought checkbox, name, "quantity unit x unit price", and line total. Order: oldest first.
    - Given Tomatoes, 2.5 kg, 1,500.00, when the list opens, then the row reads "Tomatoes", "2.5 kg x 1,500.00", and "3,750.00".
- **FR-021 (Must) Empty state.**
    - Given a list has no items, when it opens, then the screen shows the empty message and an Add item button, and the total reads 0.00.
- **FR-022 (Could) Search.** A search icon filters items by name, case-insensitive. The total always covers all items. AD-07.
    - Given items Tomatoes and Onions, when the user types "tom", then only Tomatoes shows and the total is unchanged.
- **FR-023 (Must) Load failure.**
    - Given the database read fails, when the screen opens, then the error state shows, and Retry reloads the data.

### 4.4 Edit item

- **FR-030 (Must) Edit an item.** The user taps the row or chooses Edit. The form opens with current values. Save keeps the item's position.
    - Given Tomatoes at 1,500.00, when the user changes the price to 1,800.00 and saves, then the row shows line total 4,500.00 and the list total updates at once.
- **FR-031 (Must) Discard guard.**
    - Given the user changed a field, when the user taps Back, then a dialog asks Discard or Keep editing.

### 4.5 Delete item

- **FR-040 (Must) Delete an item.** The user chooses Delete from the row menu, swipes the row left (AD-14), or taps Delete in the edit form. No confirm dialog shows because FR-041 covers mistakes.
    - Given an item exists, when the user chooses Delete, then the item leaves the list and the total drops by its line total.
- **FR-041 (Should) Undo delete.** A snackbar shows "Item deleted" with Undo for 5 seconds (AS-16). Undo restores the same id, values, and position. The snackbar clears when the user leaves List Detail or opens the Item Form. Restore obeys the 500 item limit.
    - Given the user just deleted an item, when the user taps Undo within 5 seconds, then the item returns to its old position and the total rises again.
    - Given a list had 500 items and the user deleted one and then added another, when the user returns to List Detail, then no Undo is offered.
    - Given a restore would make 501 items, when it runs, then it fails with the message in section 12.2 and the list is unchanged.

### 4.6 Bought status (AD-03)

- **FR-050 (Should) Mark bought.** Tapping the checkbox toggles bought. Bought rows show struck-through text and stay in place. The total does not change. The summary shows "<bought> of <count> bought".
    - Given 4 items, when the user ticks 1, then the summary reads "1 of 4 bought" and the total is unchanged.

### 4.7 Total calculation

- **FR-060 (Must) Show the total.** The List Detail summary card shows "Total (<currency code>)" and the amount. It updates after every add, edit, delete, restore, and currency change.
    - Given line totals 3,750.00 and 500.00, when the list shows, then the total reads 4,250.00.
- **FR-061 (Must) Line total rule.** Line total = round half up (quantity x unit price) to the minor unit. List total = sum of rounded line totals (section 8.5).
    - Given quantity 0.333 and price 10.00, when the app calculates, then the line total is 3.33.
- **FR-062 (Must) Empty total.**
    - Given an empty list, when it opens, then the total reads 0.00 with the currency.
- **FR-063 (Must) List totals on the Lists screen.** The Lists DAO computes each total with the SQL formula in section 8.5. The domain formula stays the source of truth.
    - Given 1,000 random items across lists, when both calculations run, then each list total from SQL equals the total from Dart.

### 4.8 PDF export and WhatsApp share

- **FR-070 (Must) Share as PDF.** The Share action offers Share as PDF. The app builds the PDF (section 11) and opens the system share sheet with the file. The user picks WhatsApp and a contact. CO-03.
    - Given a list with items, when the user taps Share then Share as PDF, then the share sheet opens with a PDF named like "Sunday-market-20261012.pdf".
- **FR-071 (Should) Share as text.** Format in section 11.6. AD-06.
    - Given a list with items, when the user taps Share as text, then the share sheet opens with the plain text list.
- **FR-072 (Must) Block empty share.**
    - Given an empty list, when the user taps the disabled Share icon, then a tooltip says "Add at least one item to share."
- **FR-073 (Must) Export failure.**
    - Given PDF generation throws, when the user taps Share as PDF, then the snackbar shows "Could not create the PDF. Try again." and no share sheet opens.
- **FR-074 (Should) Temp file cleanup.** AS-18.
    - Given an export file is 25 hours old, when the app starts, then the file is deleted.

### 4.9 Local storage

- **FR-080 (Must) Save every change at once.** Each add, edit, delete, restore, toggle, rename, and currency change commits in one database transaction before the UI shows success. The same transaction sets `updated_at` on the parent list.
    - Given the user ticks an item, when the Lists screen opens, then that list is first in the order.
    - Given the user adds an item and force-closes the app right after the list updates, when the app restarts, then the item is still there.
- **FR-081 (Must) Survive restart and update.**
    - Given data in schema version 1, when the app updates to version 2, then all lists and items remain.
- **FR-082 (Must) Versioned schema.** Migrations are tested (section 8.7). If the database schema is newer than the app, the app shows the message in section 12.2 and never changes or deletes the file.
    - Given a database with a newer schema version, when the app opens it, then the error screen shows and the file is untouched.
- **FR-083 (Must) Storage full.**
    - Given the database returns a disk full error, when the user taps Save, then the app shows the storage message and the form stays open with the typed values.

### 4.10 Settings and first run

- **FR-090 (Must) Default currency.** Settings offers the 7 currencies as the default for new lists. Changing it never changes an existing list. AD-05.
    - Given a list in NGN and a new default of USD, when the user opens the list, then it still shows NGN.
- **FR-091 (Should) Choose theme.** System, Light, Dark. Default System. AD-10.
    - Given the user selects Dark, when the app rebuilds, then the dark palette applies and persists after restart.
- **FR-092 (Must) First-run setup.** On first launch the app shows the "Choose your currency" sheet. It is preselected from the device locale if supported, else USD. The sheet closes only through Continue. On Continue, one transaction saves the default currency, creates the list "Market list" with that currency, and marks setup done. The app then opens that list. AD-13.
    - Given a fresh install on a device with locale region NG, when the app starts, then the sheet shows NGN preselected.
    - Given the user taps Continue with NGN, when the transaction ends, then the list "Market list" in NGN is open.
    - Given the user kills the app while the sheet shows, when the app restarts, then the sheet shows again.

## 5. Non-Functional Requirements

| ID | Area | Requirement | How to verify |
| --- | --- | --- | --- |
| NFR-001 | Performance | Cold start to first usable screen in under 2 seconds on a mid-range Android phone with 4 GB RAM (release build). | Manual timing. |
| NFR-002 | Performance | A saved item appears in the list within 100 ms. | Widget test plus manual check. |
| NFR-003 | Performance | A list of 500 items scrolls at 60 fps. The list uses `ListView.builder`. | Profile mode check in DevTools. |
| NFR-004 | Performance | PDF for 200 items builds in under 3 seconds. Build runs off the UI thread. | Integration test with timer. |
| NFR-005 | Offline | Every feature works with no network. The release app does not request the INTERNET permission. | Airplane mode test. Check the release manifest. |
| NFR-006 | Data safety | All writes use database transactions. The database uses the SQLite default journal with `synchronous = FULL`. A killed app never leaves a half-saved row. | Test: a thrown error inside a transaction leaves no partial row. 20 force-stop cycles (G3). |
| NFR-007 | Data safety | The database sits in app-private storage. The app sends no data off the device. | Code review and manifest check. |
| NFR-008 | Data safety | Schema changes ship with a migration and a migration test. No destructive migration. | `flutter test` migration tests. |
| NFR-009 | Accessibility | Touch targets are at least 48 x 48 dp. No overflow at 320 x 568 dp. | Widget tests with the tap target guideline and a 320 x 568 surface. |
| NFR-010 | Accessibility | Text contrast is at least 4.5:1. Borders and focus indicators are at least 3:1 against their background. Orange used as text or border on a light surface uses `primaryText` (section 7). | Unit test that computes contrast for every pair in the palette. |
| NFR-011 | Accessibility | The UI works with system text scale up to 200 percent. Nothing overflows or hides. | Widget tests at text scale 2.0. |
| NFR-012 | Accessibility | Every icon button has a tooltip and a semantic label. Each item row reads aloud as: "Tomatoes, 2.5 kg, 1,500.00 each, total 3,750.00, not bought". | Widget test on semantics. |
| NFR-013 | Platforms | Android 7.0 (API 24) or newer. iOS 13 or newer. Phones only. Portrait is the main layout. Landscape must not break. | Run on one old and one new device or emulator. |
| NFR-014 | App size | Android download size under 25 MB. | `flutter build appbundle --analyze-size`. |
| NFR-015 | Quality | `flutter analyze` returns no issues. | CI command. |
| NFR-016 | Quality | Coverage: domain 95 percent, blocs and cubits 90 percent, data layer 85 percent, overall 80 percent. | `flutter test --coverage`. |
| NFR-017 | Privacy | The app collects no personal data. It has no analytics and no ads. | Dependency review. |
| NFR-018 | Reliability | The app never shows a raw exception. Every error maps to a Failure and a plain-English message. | Bloc tests on failure paths. |
| NFR-019 | Backup | Android backup rules include only the database file. Restoring an older schema upgrades it. Restoring a newer schema is blocked (FR-082). | Manual restore test with Android's `bmgr` tool. Newer-schema unit test. |

## 6. Screens and Navigation

The app has four screens and one first-run sheet. Navigation uses Flutter's `Navigator` with `onGenerateRoute`.

| Route name | Screen | Arguments | Result on pop |
| --- | --- | --- | --- |
| `/` | Lists | none | none |
| `/settings` | Settings | none | none |
| `/list` | List Detail | `ListDetailArgs(listId)` | none |
| `/item-form` | Item Form | `ItemFormArgs(listId, itemId?)` | the deleted `ShoppingItem?` when the user deletes from the form |

```text
/ (Lists)
|-- /settings
|-- /list (List Detail)
    |-- /item-form (add mode: itemId is null)
    |-- /item-form (edit mode: itemId is set)
```

Share opens a bottom sheet on List Detail. It is not a route. The first-run sheet shows over the splash handoff before the Lists screen (FR-092).

### 6.0 First-run sheet

- **Purpose.** Confirm the currency and create the first list. (FR-092)
- **UI elements.** Title "Choose your currency". A list of 7 currencies with symbol and code. One is preselected. A Continue button. The sheet has no close button and ignores swipe down.
- **Error state.** If the save fails, show "Something went wrong while saving. Try again." and keep the sheet open.

### 6.1 Lists screen (route `/`)

- **Purpose.** Show all lists and create new ones. (FR-001 to FR-007)
- **UI elements.** App bar with the title "My Lists" and a settings icon. Scrolling column of list cards. Floating action button "New list".
- **List card.** Name, "<n> items", total with the list's currency symbol, "Updated <d MMM y>", and a three-dot menu (Rename, Change currency, Duplicate, Delete).
- **User actions.** Tap a card to open it. Use the menu for the others. Tap the FAB to create a list (dialog with a name field, default "Market list").
- **Empty state.** Icon, "No lists yet", and a button "Create your first list". This shows only after the user deletes every list.
- **Loading state.** Centered progress indicator.
- **Error state.** "Could not load your lists." and a Retry button.

### 6.2 List Detail screen (route `/list`)

- **Purpose.** Show items, the total, and actions on items. (FR-020 to FR-063, FR-070 to FR-072)
- **UI elements.** App bar with the list name, a search icon, a share icon, and a three-dot menu (Rename list, Change currency, Delete list). Summary card with "Total (NGN)" style label, the amount in large text, and "<bought> of <count> bought". Item rows. Floating action button "Add item".
- **Item row.** Checkbox, name (bold), subtitle "2.5 kg x 1,500.00", line total at the right, and a three-dot menu (Edit, Delete). Swipe left deletes. Back returns to the Lists screen.
- **User actions.** Tap the row to edit. Tick the checkbox to mark bought. Tap the share icon to open the share bottom sheet with Share as PDF and Share as text.
- **Empty state.** Icon, "No items yet. Tap Add item to start." The total shows 0.00. The share icon is disabled.
- **Loading state.** Progress indicator under the app bar. The summary card shows a placeholder.
- **Error state.** "Could not load this list." and a Retry button.
- **Sharing state.** While the PDF builds, the share option shows a progress indicator and blocks a second tap.

### 6.3 Item Form screen (route `/item-form`)

- **Purpose.** Add or edit one item. (FR-010 to FR-016, FR-030, FR-031)
- **UI elements.** App bar titled "Add item" or "Edit item". Fields in order: Item name, Quantity, Unit (with chips), Unit price (the list's currency symbol as a prefix). Line total preview. Buttons: Save (filled, orange), Save and add another (outlined, add mode only), Cancel (text). In edit mode a Delete text button in the error color sits at the bottom.
- **Keyboards.** Name uses the text keyboard with sentence capitalization. Quantity and price use the decimal keyboard. Next moves to the next field. Done on the last field submits.
- **Loading state.** Edit mode shows a progress indicator until the item loads. Save shows a progress indicator on the button and disables both buttons.
- **Error state.** Field errors sit under each field. A save failure shows a snackbar and keeps the form open. A failed item load shows "Could not load this item." and a Back button.

### 6.4 Settings screen (route `/settings`)

- **Purpose.** Change the default currency and theme. Show app info. (FR-090, FR-091)
- **UI elements.** Rows: Default currency (opens a list of 7), Theme (System, Light, Dark), About. Under Default currency: "Applies to new lists only." The About text reads: "Your lists live on this phone. Phone backup may restore them on a new phone. The app collects no data." Version number below it.
- **Error state.** If saving a setting fails, show "Could not save your setting." and keep the old value.

## 7. UI and Design Specification

The app uses Material 3 (`useMaterial3: true`). Build each `ColorScheme` in two steps. First call `ColorScheme.fromSeed(seedColor: Color(0xFFF57C00), brightness: ...)`. Then call `copyWith` with every token in the tables below. Use the slot names of the installed Flutter version. Old names map like this: `surfaceVariant` becomes `surfaceContainerHighest`, and the Background token goes into `ThemeData.scaffoldBackgroundColor`. If a slot name differs, keep the intent of the table.

### 7.1 Light palette (orange primary)

| Token | Hex | Use |
| --- | --- | --- |
| primary | #F57C00 | Buttons, FAB, selected states |
| onPrimary | #1A1A1A | Text and icons on primary (about 6.4:1) |
| primaryContainer | #FFE0B2 | Summary card, chips, selected rows |
| onPrimaryContainer | #3E2000 | Text on primaryContainer |
| primaryText | #B45200 | Orange text, links, focus borders on light surfaces (at least 4.5:1) |
| secondary | #795548 | Secondary icons and accents |
| Background (scaffold) | #FFFBF7 | Screen background |
| surface | #FFFFFF | Cards, sheets, dialogs, item rows |
| surfaceContainerHighest | #F5EDE4 | Input fill |
| onSurface (text) | #1C1B1A | Main text |
| onSurfaceVariant | #5E5750 | Secondary text |
| outline | #85776A | Borders |
| error | #B3261E | Errors, Delete actions |
| onError | #FFFFFF | Text on error |
| inverseSurface | #322F2C | Snackbar background |
| onInverseSurface | #F6EFE8 | Snackbar text |
| inversePrimary | #FFB74D | Snackbar action (Undo) |
| success | #2E7D32 | Bought checkmark. Not a Material slot. Add a `ThemeExtension`. |

The FAB uses primary (#F57C00) for its fill. It is about 2.7:1 against the background, but its label meets 6.4:1, so the FAB stays readable. Every other orange border or text uses `primaryText`.

### 7.2 Dark palette (AS-11)

| Token | Hex |
| --- | --- |
| primary | #FFB74D |
| onPrimary | #3E2000 |
| primaryContainer | #7A3E00 |
| onPrimaryContainer | #FFE0B2 |
| primaryText | #FFB74D |
| secondary | #BCAAA4 |
| Background (scaffold) | #141210 |
| surface | #1C1917 |
| surfaceContainerHighest | #2A2622 |
| onSurface (text) | #EAE1D9 |
| onSurfaceVariant | #C4B8AB |
| outline | #9C8F80 |
| error | #F2B8B5 |
| onError | #601410 |
| inverseSurface | #EAE1D9 |
| onInverseSurface | #1C1917 |
| inversePrimary | #8F4100 |
| success | #81C784 |

### 7.3 Typography

- Use the platform default font (Roboto on Android, SF on iOS) and the Material 3 type scale.
- Screen title: `titleLarge` (22 sp). Item name: `titleMedium` (16 sp, weight 600). Subtitle: `bodyMedium` (14 sp). Summary total: `headlineMedium` (28 sp, weight 700).
- All money text uses tabular figures: `fontFeatures: [FontFeature.tabularFigures()]`.
- The total sits in a `FittedBox(fit: BoxFit.scaleDown)` so large numbers never overflow.

### 7.4 Spacing, shape, components

- Spacing scale in dp: 4, 8, 12, 16, 24, 32. Screen side padding is 16.
- Corner radius: cards 12, input fields 12, dialogs 28, FAB 16, chips 8. Buttons use the Material 3 pill shape.
- Filled button: primary background, onPrimary text, height 48. Outlined button: 1 dp outline, `primaryText` label. Text button: `primaryText` label. Delete buttons use the error color.
- Input fields: filled style with `surfaceContainerHighest` fill, 12 dp radius, no underline. The focused border is 2 dp `primaryText`. The error border is 2 dp error. Labels float above. Error text sits below.
- Item rows are cards with elevation 0 and a 1 dp outline. Row padding 12 dp. Minimum height 72 dp.
- Snackbars float above the FAB. They use `inverseSurface`, `onInverseSurface`, and `inversePrimary` for the Undo action.
- Bought rows use `onSurfaceVariant` text with a line-through and a success-colored checkmark.

### 7.5 Material 3 rules

- Use no bottom navigation bar. The MVP has no multi-destination navigation.
- Use `FloatingActionButton.extended` with a label for the main action on Lists and List Detail.
- Use `showModalBottomSheet` for the share menu and the first-run sheet. Use `AlertDialog` for confirms.
- Use `Dismissible` for swipe to delete, with an error-colored background and a delete icon.
- Never hard-code a color in a widget. Read it from `Theme.of(context).colorScheme` or the `AppColors` extension.

### 7.6 Currency format rules

- Format with `intl` using locale `en_US`, with the symbol of the list's currency and 2 decimals. Output looks like "₦1,250.50".
- Symbols: NGN ₦, GHS GH₵, KES KSh, ZAR R, USD $, GBP £, EUR €.
- The formatter takes the currency as a parameter. It never reads global settings.
- A negative amount cannot occur. Do not format negatives.
- Quantity shows up to 3 decimals with no trailing zeros: 2.5, 2, 0.125.
- Dates in the UI and PDF use `d MMM y` (for example 12 Oct 2026).

## 8. Data Model

The app uses one SQLite database through Drift, named `market_list.sqlite`. Schema version starts at 1. The agent enables `PRAGMA foreign_keys = ON` and `PRAGMA synchronous = FULL` on every open. It keeps the default journal mode.

### 8.1 Domain entities

| Entity | Fields (Dart types) | Notes |
| --- | --- | --- |
| ShoppingList | `String id`, `String name`, `CurrencyCode currency`, `DateTime createdAt`, `DateTime updatedAt` | `id` is a UUID v4. Times are UTC. |
| ShoppingItem | `String id`, `String listId`, `String name`, `Quantity quantity`, `String? unit`, `Money unitPrice`, `bool isBought`, `DateTime createdAt`, `DateTime updatedAt` | Getter `Money get lineTotal` uses the rule in 8.5. |
| ListDetail | `ShoppingList list`, `List<ShoppingItem> items` | Getters: `total`, `boughtCount`, `itemCount`. |
| ListSummary | `ShoppingList list`, `int itemCount`, `Money total` | Used by the Lists screen. The total comes from SQL (8.5). |
| AppSettings | `CurrencyCode defaultCurrency`, `AppThemeMode themeMode`, `bool onboardingDone` | One row. |
| Money (value object) | `int minorUnits` | Never negative. Created only through `Money.fromMinor` or `Money.parse`. |
| Quantity (value object) | `int milli` | Thousandths. 2.5 is stored as 2500. Range 1 to 9,999,999. |
| CurrencyCode (enum) | `ngn, ghs, kes, zar, usd, gbp, eur` | Each has `symbol` and `code`. |

### 8.2 Database tables

**shopping_lists**

| Column | Type | Constraints |
| --- | --- | --- |
| id | TEXT | Primary key |
| name | TEXT | NOT NULL, length 1 to 60 |
| currency_code | TEXT | NOT NULL, one of NGN, GHS, KES, ZAR, USD, GBP, EUR |
| created_at | INTEGER | NOT NULL, UTC epoch milliseconds |
| updated_at | INTEGER | NOT NULL, UTC epoch milliseconds |

**shopping_items**

| Column | Type | Constraints |
| --- | --- | --- |
| id | TEXT | Primary key |
| list_id | TEXT | NOT NULL, foreign key to shopping_lists(id), ON DELETE CASCADE |
| name | TEXT | NOT NULL, length 1 to 80 |
| quantity_milli | INTEGER | NOT NULL, 1 to 9999999 |
| unit | TEXT | NULL allowed, length 1 to 20 when present. Never an empty string. |
| unit_price_minor | INTEGER | NOT NULL, 0 to 9999999999 |
| is_bought | INTEGER | NOT NULL, default 0, only 0 or 1 |
| created_at | INTEGER | NOT NULL |
| updated_at | INTEGER | NOT NULL |

Index: `idx_items_list_created` on (list_id, created_at). Read order: `ORDER BY created_at ASC, id ASC`. A duplicated list sets each copied item's `created_at` to the base time plus the item index in milliseconds, so order stays stable.

**app_settings**

| Column | Type | Constraints |
| --- | --- | --- |
| id | INTEGER | Primary key, CHECK (id = 1) |
| default_currency_code | TEXT | NOT NULL, one of the 7 codes |
| theme_mode | TEXT | NOT NULL, default 'system', one of system, light, dark |
| onboarding_done | INTEGER | NOT NULL, default 0, only 0 or 1 |

**Touch rule.** Every write to `shopping_items`, and every rename or currency change on `shopping_lists`, also sets `shopping_lists.updated_at` to now for the parent list. It happens inside the same transaction (FR-080).

### 8.3 Maximum values

| Field | Limit |
| --- | --- |
| Quantity | 0.001 to 9,999.999 |
| Unit price | 0.00 to 99,999,999.99 |
| Item name | 1 to 80 characters after normalization |
| Unit | 0 to 20 characters after normalization |
| List name | 1 to 60 characters after normalization |
| Lists | 100 |
| Items per list | 500 |

The largest line total is about 10^14 minor units. The largest list total is about 5 x 10^16. Both fit in a 64-bit `int`. The app targets Android and iOS only, so Dart `int` is 64-bit. SQLite integers are 64-bit too.

### 8.4 Text normalization

The domain applies these steps to item name, unit, and list name before it validates or saves:

1. Replace every run of whitespace (spaces, tabs, line breaks) with one space.
2. Remove control characters.
3. Trim both ends.
4. For unit only: an empty result becomes `null`.

Duplicate checks (FR-015) compare normalized names with case ignored.

### 8.5 Money and total rules

- Never use `double` for money or quantity. Store and calculate with `int` only.
- All supported currencies use 2 decimals, so 1 major unit = 100 minor units.
- Parse text with string operations, not `double.parse`. "1500.5" becomes 150050 minor units. "2.5" becomes 2500 milli.
- Reject more than 2 decimals for price and more than 3 for quantity.
- Line total, rounding half up:

```latex
lineTotalMinor = \lfloor (quantityMilli \times unitPriceMinor + 500) / 1000 \rfloor
```

- In Dart: `(quantityMilli * unitPriceMinor + 500) ~/ 1000`. Both inputs are never negative, so integer division rounds half up.
- List total = sum of rounded line totals. PDF rows and the total always agree.
- **SQL mirror.** The Lists DAO computes each list total with `SUM((quantity_milli * unit_price_minor + 500) / 1000)`. SQLite integer division truncates and inputs are never negative, so the result matches Dart. The Dart formula stays the source of truth. A parity test compares both on 1,000 random rows (FR-063).
- Format money from integer parts: group the whole part with `intl`, then add a dot and the 2-digit fraction. No `double` touches the amount.
- Currency is stored per list. Changing it does not convert amounts (FR-007).

**Rounding examples (the agent turns these into unit tests)**

| Quantity | Unit price | Line total | Reason |
| --- | --- | --- | --- |
| 2.5 | 1,500.00 | 3,750.00 | Exact. |
| 0.333 | 10.00 | 3.33 | 333 x 1000 = 333,000, plus 500, divided by 1000 = 333. |
| 0.005 | 1.00 | 0.01 | Exactly half, rounds up. |
| 0.004 | 1.00 | 0.00 | Below half, rounds down. |
| 3 | 0.99 | 2.97 | Exact. |
| 9,999.999 | 99,999,999.99 | 999,999,899,900.00 | Maximum check. No overflow. |

### 8.6 Backup and restore

- **Android.** Keep `android:allowBackup="true"` (AS-12). Add backup rules (`dataExtractionRules` and `fullBackupContent`) that include only the database file. The agent checks where `drift_flutter` places the file and writes the rule for that exact path.
- **iOS.** The documents folder is included in iCloud backup by default. The agent leaves that default.
- **Restore rules.** A restored database with an older schema runs the migrations. A restored database with a newer schema is never altered. The app shows the message in section 12.2 (FR-082).
- **Disclosure.** The About screen tells the user that phone backup may restore lists (section 6.4, CO-01).

### 8.7 Migrations

- `schemaVersion` starts at 1. Every schema change raises it by 1 and adds a migration step with `stepByStep`.
- The agent dumps each schema version with the Drift schema tools into `drift_schemas/` and writes a migration test per step.
- A migration never drops user data.

## 9. Clean Architecture Specification

The app is organized by feature. Each feature has three layers: `domain`, `data`, `presentation`. Shared code sits in `core`. Money, quantity, and currency value objects sit in `core/domain` because every feature uses them.

### 9.1 Folder and file structure

```text
market_list/
  pubspec.yaml
  analysis_options.yaml
  README.md  QUESTIONS.md  DECISIONS.md
  assets/fonts/NotoSans-Regular.ttf
  assets/fonts/NotoSans-Bold.ttf
  drift_schemas/                         (dumped schema versions)
  integration_test/app_flow_test.dart
  lib/
    main.dart
    app.dart                             (MaterialApp, theme, splash gate, SettingsCubit provider)
    core/
      constants/app_limits.dart
      domain/value_objects/money.dart, quantity.dart, currency_code.dart
      domain/text_normalizer.dart
      error/failures.dart
      usecase/usecase.dart               (UseCase, StreamUseCase, NoParams)
      di/injection.dart                  (get_it setup)
      database/app_database.dart, tables/*.dart, daos/lists_dao.dart, items_dao.dart, settings_dao.dart
      platform/clock.dart, id_generator.dart
      formatting/money_formatter.dart, quantity_formatter.dart, date_formatter.dart
      router/app_router.dart             (onGenerateRoute, route names, argument classes)
      theme/app_colors.dart, app_theme.dart
      widgets/empty_state.dart, error_view.dart, loading_view.dart
    features/
      shopping_lists/
        domain/entities/shopping_list.dart, list_summary.dart
        domain/repositories/shopping_list_repository.dart
        domain/usecases/watch_lists.dart, create_list.dart, rename_list.dart, set_list_currency.dart,
                         delete_list.dart, duplicate_list.dart
        data/mappers/shopping_list_mapper.dart
        data/datasources/shopping_list_local_data_source.dart
        data/repositories/shopping_list_repository_impl.dart
        presentation/cubit/lists_cubit.dart, lists_state.dart
        presentation/pages/lists_page.dart
        presentation/widgets/list_card.dart, list_name_dialog.dart, currency_picker_dialog.dart
      items/
        domain/entities/shopping_item.dart, list_detail.dart, item_draft.dart, item_validation_errors.dart
        domain/repositories/shopping_item_repository.dart
        domain/usecases/watch_list_detail.dart, get_list_detail.dart, get_item.dart, validate_item_draft.dart,
                         add_item.dart, update_item.dart, delete_item.dart, restore_item.dart,
                         set_item_bought.dart, has_duplicate_item_name.dart
        data/mappers/shopping_item_mapper.dart
        data/datasources/shopping_item_local_data_source.dart
        data/repositories/shopping_item_repository_impl.dart
        presentation/bloc/list_detail_bloc.dart, list_detail_event.dart, list_detail_state.dart
        presentation/cubit/item_form_cubit.dart, item_form_state.dart
        presentation/pages/list_detail_page.dart, item_form_page.dart
        presentation/widgets/item_tile.dart, summary_card.dart, unit_chips.dart
      export/
        domain/entities/exported_file.dart, share_outcome.dart, pdf_document_data.dart
        domain/services/list_pdf_generator.dart, share_service.dart, export_file_store.dart
        domain/usecases/build_list_pdf.dart, build_list_text.dart, share_file.dart, share_text.dart, cleanup_exports.dart
        data/services/pdf_list_generator.dart, share_plus_service.dart, temp_export_file_store.dart
        presentation/cubit/share_cubit.dart, share_state.dart
        presentation/widgets/share_sheet.dart
      settings/
        domain/entities/app_settings.dart, app_theme_mode.dart
        domain/repositories/settings_repository.dart, onboarding_repository.dart
        domain/usecases/ensure_settings.dart, watch_settings.dart, set_default_currency.dart,
                         set_theme_mode.dart, complete_onboarding.dart
        data/mappers/settings_mapper.dart
        data/datasources/settings_local_data_source.dart
        data/repositories/settings_repository_impl.dart, onboarding_repository_impl.dart
        presentation/cubit/settings_cubit.dart, settings_state.dart
        presentation/pages/settings_page.dart
        presentation/widgets/onboarding_sheet.dart
  test/                                  (mirrors lib/ one to one)
```

### 9.2 Layer rules

| Layer | Responsibility | May depend on | Must never depend on |
| --- | --- | --- | --- |
| domain | Entities, value objects, validation, business rules, use cases, repository and service interfaces. Pure Dart. | `dart:core`, `fpdart`, `equatable`, `intl` (formatting only), `core/domain`, `core/error`, `core/formatting` | `flutter`, `drift`, `pdf`, `share_plus`, `path_provider`, any `data` or `presentation` |
| data | Implements domain interfaces. Talks to Drift, `pdf`, `share_plus`, and the file system. Maps rows to entities. Maps exceptions to Failures. | `domain`, `core`, `drift`, `pdf`, `share_plus`, `path_provider`, `flutter/services.dart` (only to load font assets) | `presentation`, Flutter widgets, `flutter_bloc` |
| presentation | Pages, widgets, Blocs, Cubits, theme. Calls use cases only. Maps Failures to messages. | `domain`, `core`, `flutter`, `flutter_bloc` | `data`, `drift`, `pdf`, `share_plus`, `path_provider` |
| core/di, core/router | Wire everything together. | all layers | none |

**Feature dependency rule.** A feature may import another feature's `domain` layer only. It never imports another feature's `data` or `presentation`. The allowed direction is one way: `export` to `items` to `shopping_lists`. `export` may also use `settings` domain. `settings` and `shopping_lists` import no other feature. Pages reach other pages only through `core/router`.

Enforcement: the agent adds `test/architecture_test.dart`. It reads every Dart file under `lib/` and fails if an `import` line breaks the tables above.

### 9.3 Use cases

Every use case is one class with one `call` method. Plain use cases implement `UseCase<Output, Params>` and return `Future<Either<Failure, Output>>`. Stream use cases implement `StreamUseCase<Output, Params>` and return `Stream<Either<Failure, Output>>`. `ValidateItemDraft` is synchronous and returns `Either<ItemValidationErrors, ItemDraft>`. `Unit` is `fpdart`'s `Unit`.

| Use case | Input | Output | Enforces |
| --- | --- | --- | --- |
| WatchLists | NoParams | Stream of List&lt;ListSummary&gt; | Order by updated_at, newest first. Totals from the SQL mirror. |
| CreateList | CreateListParams(name, currency) | ShoppingList | Normalization, name rules, 100 list limit |
| RenameList | RenameListParams(listId, name) | Unit | Normalization, name rules |
| SetListCurrency | SetListCurrencyParams(listId, currency) | Unit | None. No conversion. |
| DeleteList | listId | Unit | Cascade delete |
| DuplicateList | listId | ShoppingList | Copy items and currency, bought = false, 100 list limit |
| WatchListDetail | listId | Stream of ListDetail | One join query. Item order. |
| GetListDetail | listId | ListDetail | One-shot read for export |
| GetItem | itemId | ShoppingItem | NotFoundFailure |
| ValidateItemDraft | RawItemInput(name, quantityText, unit, priceText) | ItemDraft or ItemValidationErrors | Normalization and all rules in 12.1 |
| AddItem | AddItemParams(listId, ItemDraft) | ShoppingItem | 500 item limit |
| UpdateItem | UpdateItemParams(itemId, ItemDraft) | ShoppingItem | NotFoundFailure |
| DeleteItem | itemId | ShoppingItem (for undo) | NotFoundFailure |
| RestoreItem | ShoppingItem | Unit | Same id and created_at. 500 item limit (LimitFailure). |
| SetItemBought | SetItemBoughtParams(itemId, isBought) | Unit | None |
| HasDuplicateItemName | DuplicateCheckParams(listId, name, excludeItemId?) | bool | Normalized, case-insensitive |
| BuildListPdf | listId | ExportedFile(path, fileName) | Empty list returns ValidationFailure |
| BuildListText | listId | String | Format in 11.6 |
| ShareFile | ShareFileParams(path, subject, text?) | ShareOutcome | None |
| ShareText | text | ShareOutcome | None |
| CleanupExports | NoParams | Unit | Delete files older than 24 hours |
| EnsureSettings | regionCode? | AppSettings and a suggested currency | Inserts the settings row if missing |
| WatchSettings | NoParams | Stream of AppSettings | None |
| SetDefaultCurrency | CurrencyCode | Unit | None |
| SetThemeMode | AppThemeMode | Unit | None |
| CompleteOnboarding | CurrencyCode | ShoppingList | One transaction: save default currency, create "Market list", set onboarding_done |

### 9.4 Repository and service interfaces (domain)

- `ShoppingListRepository`: `watchLists()`, `createList(name, currency)`, `renameList(id, name)`, `setCurrency(id, currency)`, `deleteList(id)`, `duplicateList(id)`, `listCount()`.
- `ShoppingItemRepository`: `watchListDetail(listId)`, `getListDetail(listId)`, `getItem(id)`, `addItem(listId, draft)`, `updateItem(id, draft)`, `deleteItem(id)`, `restoreItem(item)`, `setBought(id, isBought)`, `itemCount(listId)`, `hasDuplicateName(listId, name, excludeId)`.
- `SettingsRepository`: `ensureSettings(regionCode)`, `watchSettings()`, `setDefaultCurrency(code)`, `setThemeMode(mode)`.
- `OnboardingRepository`: `complete(currency) -> Either<Failure, ShoppingList>`.
- `ListPdfGenerator`: `generate(PdfDocumentData) -> Future<Either<Failure, ExportedFile>>`.
- `ShareService`: `shareFile(path, subject, text)`, `shareText(text)`. Both return `ShareOutcome`.
- `ExportFileStore`: `deleteOlderThan(Duration)`.
- `Clock` and `IdGenerator` (UUID v4) sit in `core/platform`. Tests use fakes.

### 9.5 Data layer pieces

- **Data sources.** Three local data sources wrap the Drift DAOs. They return Drift row classes and throw raw exceptions.
- **Models.** The Drift generated row classes are the data models. The agent adds no hand-written duplicates.
- **Mappers.** One mapper per feature converts rows to entities and entities to companions. Money, Quantity, and CurrencyCode convert here.
- **Repository implementations.** Each `*RepositoryImpl` calls its data source in `try/catch` and returns `Either<Failure, T>`. Multi-step writes (duplicate list, restore, onboarding, any item write plus the list touch) run in one Drift transaction.
- **Queries.** `ItemsDao.watchListWithItems(listId)` is one join query, so each emission holds a consistent list and item set. `ListsDao.watchSummaries()` returns list rows with item counts and the SQL mirror total.
- **Streams.** Repositories expose Drift `.watch()` streams mapped to `Right(value)`. A stream error maps to `Left(failure)`. The Bloc then shows the error state, and Retry restarts the stream.

### 9.6 Error handling

- `core/error/failures.dart` defines a sealed class `Failure` (extends `Equatable`) with: `ValidationFailure`, `NotFoundFailure`, `LimitFailure(kind)`, `StorageFullFailure`, `SchemaTooNewFailure`, `DatabaseFailure`, `ExportFailure`, `ShareFailure`, `UnexpectedFailure`.
- Repositories catch exceptions and return `Left(Failure)`. A `SqliteException` with the SQLITE_FULL result code maps to `StorageFullFailure`. Any other `SqliteException` maps to `DatabaseFailure`. A schema version above the app's maps to `SchemaTooNewFailure`. Anything else maps to `UnexpectedFailure`.
- Use cases and Blocs never throw. They pass `Failure` values along.
- `presentation/failure_messages.dart` is the only file that writes user-facing error strings (section 12).
- The app wraps `runApp` in `runZonedGuarded` and sets `FlutterError.onError`. Both log with `debugPrint` only. Nothing leaves the device.

### 9.7 Naming and style rules

- File names use `snake_case`. Class names use `PascalCase`. One public class per file.
- Use case file and class: verb and noun (`add_item.dart`, `AddItem`). Implementations end with `Impl`.
- Bloc files come in threes: `x_bloc.dart`, `x_event.dart`, `x_state.dart`. Cubit files come in pairs.
- States and events extend `Equatable` and are immutable.
- Tests mirror the `lib/` path and end with `_test.dart`.

## 10. State Management Specification

The app uses `flutter_bloc`. It has one Bloc and four Cubits. The Bloc fits List Detail because that screen has many named events and a live stream. Cubits fit the rest because their logic is plain method calls.

### 10.1 Screen to state holder map

| Screen | State holders | Scope |
| --- | --- | --- |
| App root and first-run sheet | `SettingsCubit` | Created at app start. Lives for the whole app. |
| Lists screen | `ListsCubit` | Created when the route opens. |
| List Detail screen | `ListDetailBloc`, `ShareCubit` | Created when the route opens. |
| Item Form screen | `ItemFormCubit` | Created when the route opens. |
| Settings screen | `SettingsCubit` (root instance) | Reused. |

All holders come from `get_it` as factories. The root `SettingsCubit` is a lazy singleton. Pages create the others in `BlocProvider(create: ...)`.

### 10.2 SettingsCubit (Cubit)

- **Methods:** `start(regionCode)`, `setDefaultCurrency(code)`, `setThemeMode(mode)`, `completeOnboarding(currency)`, `messageHandled()`, `firstListHandled()`.
- **State:** `SettingsState(status, settings, suggestedCurrency, firstListId, message)`. `status` is `loading`, `needsOnboarding`, `loaded`, or `failure`.
- **Transitions:**
    - `start` runs `EnsureSettings`. If `onboardingDone` is false, the status goes to `needsOnboarding` with `suggestedCurrency`. Otherwise it goes to `loaded` and listens to `WatchSettings`. An error goes to `failure` with Retry.
    - `completeOnboarding` runs `CompleteOnboarding`. On success the status goes to `loaded` and `firstListId` is set. The app opens that list, then calls `firstListHandled`. On failure `message` is set and the status stays `needsOnboarding`.
    - A failed `setDefaultCurrency` or `setThemeMode` keeps `loaded` and sets `message`.
- **Startup gate.** The app keeps the native splash (`flutter_native_splash` preserve) until the status is not `loading`. This stops a theme flash. `failure` shows a full-screen error with Retry.

### 10.3 ListsCubit (Cubit)

- **Methods:** `watch()`, `retry()`, `createList(name, defaultCurrency)`, `renameList(id, name)`, `setCurrency(id, currency)`, `deleteList(id)`, `duplicateList(id)`, `messageHandled()`, `createdListHandled()`.
- **State:** `ListsState(status, lists, message, createdListId)`. `status` is `loading`, `success`, or `failure`.
- **Transitions:**
    - `watch`: `loading` goes to `success` on the first `Right`. A `Left` goes to `failure`. `retry` goes back to `loading`.
    - `createList`: the page passes the default currency from `SettingsCubit`. On success the cubit sets `createdListId`. The page opens the new list, then calls `createdListHandled`. On failure it sets `message`.
    - `renameList`, `setCurrency`, `deleteList`, `duplicateList`: the stream updates `lists`. A failure sets `message` and keeps `lists`.

### 10.4 ListDetailBloc (Bloc)

| Event | Effect |
| --- | --- |
| `ListDetailStarted(listId)` | Status `loading`. Subscribe to `WatchListDetail` with `emit.forEach`. |
| `ListDetailRetried` | Status `loading`. Restart the subscription. |
| `ItemBoughtToggled(itemId, isBought)` | Call `SetItemBought`. On failure set `message`. |
| `ItemDeleted(itemId)` | Call `DeleteItem`. On success set `deletedItem`. On failure set `message`. |
| `ItemRestoreRequested(item)` | Call `RestoreItem`. Clear `deletedItem`. On failure set `message` (limit message when the limit blocks it). |
| `DeletedItemHandled` | Set `deletedItem` to null. The page sends it when the snackbar closes, when the user leaves the screen, and before it opens the Item Form. |
| `SearchQueryChanged(query)` | Set `query`. An empty string means no filter. |
| `ListRenamed(name)` | Call `RenameList`. On failure set `message`. |
| `ListCurrencyChanged(currency)` | Call `SetListCurrency`. On failure set `message`. |
| `ListDeleted` | Call `DeleteList`. On success set `listRemoved` to true. The page pops. |
| `MessageHandled` | Set `message` to null. |

- **State:** `ListDetailState(status, detail, query, deletedItem, message, listRemoved)`. `status` is `loading`, `success`, or `failure`.
- **Derived getters:** `visibleItems` (filtered by `query`), `total` (all items), `boughtCount`, `isEmpty` (success and no items), `canShare` (success and at least one item).
- **Transitions:** `loading` goes to `success` on the first `Right`. A `Left` goes to `failure`. A later stream value replaces `detail` and stays `success`. Stream events use `restartable()` so a retry never doubles the subscription.

### 10.5 ItemFormCubit (Cubit)

- **Constructor input:** `listId` and an optional `itemId` (edit mode). The cubit also reads the list currency for the price prefix and the preview.
- **Methods:** `load()`, `nameChanged`, `quantityChanged`, `unitChanged`, `unitChipSelected`, `priceChanged`, `fieldBlurred(field)`, `submit({addAnother})`, `confirmDuplicate()`, `cancelDuplicate()`, `delete()`, `messageHandled()`.
- **State:** `ItemFormState(status, isEdit, name, quantityText, unit, priceText, errors, touched, showErrors, linePreview, isDirty, message)`. `status` is one of: `loading`, `ready`, `submitting`, `duplicateWarning`, `saved`, `savedAndReset`, `deleted`, `failure`.
- **Error visibility.** A field shows its error when its name is in `touched` or when `showErrors` is true. `fieldBlurred` adds the field to `touched`. `submit` sets `showErrors`.
- **Transitions:**
    - Add mode starts at `ready`. Edit mode starts at `loading` and goes to `ready` after `GetItem`. A failed load goes to `failure` with "Could not load this item."
    - Each field method updates the text, recalculates `errors` through `ValidateItemDraft`, updates `linePreview` when both numbers are valid, and sets `isDirty`.
    - `submit`: set `showErrors`. If `errors` is not empty, stay `ready`. Otherwise run `HasDuplicateItemName` (add mode, or edit mode when the normalized name changed). A duplicate goes to `duplicateWarning`. No duplicate goes to `submitting`, then `AddItem` or `UpdateItem`.
    - `confirmDuplicate` continues to `submitting`. `cancelDuplicate` returns to `ready`.
    - After a successful save: `saved`, or `savedAndReset` when `addAnother` is true. `savedAndReset` clears all fields, `touched`, and `showErrors`, then returns to `ready` on the next field change.
    - A save failure goes to `failure` with `message`. The typed values stay.
    - `delete` runs `DeleteItem`, then goes to `deleted`. The page pops with the deleted item as the route result. List Detail then shows the Undo snackbar for that item.

### 10.6 ShareCubit (Cubit)

- **Methods:** `sharePdf(listId)`, `shareText(listId)`, `messageHandled()`.
- **State:** `ShareState(status, message)`. `status` is `idle`, `working`, `done`, or `failure`.
- **Transitions:** `idle` goes to `working`. For PDF: `BuildListPdf`, then `ShareFile`. For text: `BuildListText`, then `ShareText`. A `ShareOutcome` of shared or dismissed goes to `done`, then back to `idle`. A dismissed share sheet is not an error. Any `Left` goes to `failure` with the message from section 12. While `working`, both options are disabled.

### 10.7 State rules for every holder

- Initial status is `loading` where data loads. The UI never shows the empty state during `loading`.
- Empty is derived: `status == success` and the collection is empty. It is never its own status.
- One-time effects (snackbar, navigation, dialog) use a nullable state field plus a `BlocListener` with `listenWhen`. A matching "handled" call clears the field. No effects run inside `build`.
- States and events extend `Equatable` and have `copyWith`.
- Handlers check `isClosed` before they emit after an `await`.
- Widgets read state only. They hold no business logic and call no repository or use case directly.
- Use `BlocSelector` or `buildWhen` for the summary card and the list.

## 11. PDF and Sharing Specification

The `pdf` package builds the file. `path_provider` gives the temp folder. `share_plus` opens the system share sheet. The user then picks WhatsApp. The app never talks to WhatsApp directly (CO-03).

### 11.1 PDF layout

| Item | Rule |
| --- | --- |
| Page | A4 portrait. Margins 36 pt on every side. |
| Fonts | Noto Sans Regular and Bold, bundled in `assets/fonts/`. The default PDF fonts have no ₦ glyph, so the agent must not use them. The agent must render ₦, GH₵, £, and € in a test and look at the output. If any glyph is missing, add a fallback font to `fontFallback`. |
| Title | List name, 20 pt bold. An orange line (#F57C00, 2 pt) sits under it. |
| Sub-title | "Date: 12 Oct 2026" and "Items: 12", 10 pt, gray (#5E5750). |
| Table columns | Done (28 pt), No. (28 pt), Item (flexible, wraps up to 3 lines), Qty with unit (right aligned, may wrap to 2 lines), Unit price, Line total (both right aligned). |
| Column headers | The price headers use the list's currency, for example "Unit price (₦)" and "Line total (₦)". |
| Header row | Background #FFE0B2, text #3E2000, 10 pt bold. The header repeats on every page. |
| Body rows | 10 pt. Zebra background #FFF8F0 on every second row. 1 pt bottom border #E0D6CB. |
| Done column | A 10 x 10 pt vector square. A bought item shows a check mark drawn as vector lines inside it. Draw shapes, not font glyphs (AD-11). |
| Total row | After the last item row. "Total" right aligned, amount 12 pt bold, with the currency symbol, on a #FFE0B2 background. The total row never sits alone on a page. Keep it with at least the last item row. |
| Footer | Left: "Made with Market List" (app name placeholder). Right: "Page X of Y". 8 pt, gray. |
| Amount cells | Never wrap. The line total column fits 17 characters at 10 pt. |

### 11.2 Many pages

- Use a multi-page layout so rows flow to new pages. A 500-item list makes about 14 pages.
- A row never splits across two pages.
- The page count in the footer is correct on every page ("Page 2 of 14").
- Build the PDF off the UI thread. Load the font bytes on the main isolate with `rootBundle`, then pass the bytes and plain data into `Isolate.run`.

### 11.3 File name and location

- Folder: `<temporary directory>/exports/`.
- Name: `<list-name-slug>-<yyyyMMdd>.pdf`. The slug replaces every run of characters outside A to Z, a to z, and 0 to 9 with one dash, trims dashes, and cuts to 40 characters. An empty slug becomes `shopping-list`. Example: "Sunday market" becomes `Sunday-market-20261012.pdf`.
- A second export on the same day overwrites the first.

### 11.4 Flow from Share to WhatsApp

1. The user taps the share icon on List Detail. It is enabled only when the list has at least one item (FR-072).
2. A bottom sheet opens with Share as PDF and Share as text.
3. The user taps Share as PDF. `ShareCubit` goes to `working`. The option shows a progress indicator.
4. `BuildListPdf` reads the list with `GetListDetail`, builds the PDF in the temp folder, and returns an `ExportedFile`.
5. `ShareFile` calls `share_plus` with the file (MIME type `application/pdf`), subject = list name, and text = "Shopping list: <list name>". WhatsApp may use the text as a caption, but the app does not rely on it (AS-19). The agent passes `sharePositionOrigin` from the share button so iPad does not crash.
6. The system share sheet opens. The user taps WhatsApp. On iOS the user may need to tap More first.
7. WhatsApp opens its own contact picker with the PDF attached. The user picks a contact or group and taps Send.
8. The app receives the `ShareOutcome`. The bottom sheet closes. A dismissed sheet is not an error.

From the Share icon, WhatsApp usually opens after 3 taps on Android: the icon, Share as PDF, and WhatsApp. iOS may need a fourth tap (G4).

### 11.5 Fallback if WhatsApp is not installed

- The app does not check for WhatsApp. A check needs extra Android `<queries>` entries and iOS `LSApplicationQueriesSchemes`, which add review risk for no real gain.
- The system share sheet lists whatever apps exist. The user can send the PDF by email, SMS, Telegram, or save it to Files or Drive.
- If the share call throws, show "Could not open the share sheet. Try again." and return to `idle`.
- If the PDF build fails, show "Could not create the PDF. Try again." (FR-073).

### 11.6 Text share format

Share as text sends this plain text. Bought status is not included. The date uses `d MMM y`. Amounts have no symbol except in the total line, which uses the list's currency.

```text
Sunday market
12 Oct 2026

1. Tomatoes, 2.5 kg x 1,500.00 = 3,750.00
2. Onions, 3 pcs x 200.00 = 600.00
3. Rice, 1 bag x 45,000.00 = 45,000.00

Total: ₦49,350.00
```

If an item has no unit, the line reads "Tomatoes, 2.5 x 1,500.00 = 3,750.00".

## 12. Edge Cases and Validation Rules

`failure_messages.dart` is the only file that holds these strings (section 9.6). The domain validates every rule. The input formatters in the UI only help the user.

### 12.1 Field validation

The domain normalizes text first (section 8.4).

| Field | Rule | Message |
| --- | --- | --- |
| Item name | Required after normalization | Enter an item name. |
| Item name | 80 characters or fewer | Item name must be 80 characters or fewer. |
| Quantity | Required | Enter a quantity. |
| Quantity | Digits and one dot only. At most 3 decimals. | Use digits and one dot only, for example 2.5. |
| Quantity | Greater than 0 | Quantity must be greater than 0. |
| Quantity | At most 9,999.999 | Quantity cannot be more than 9,999.999. |
| Unit | 20 characters or fewer | Unit must be 20 characters or fewer. |
| Unit price | Required (0 is allowed) | Enter a price. Use 0 if you do not know it. |
| Unit price | Digits and one dot only. At most 2 decimals. | Use digits and one dot only, for example 1500.50. |
| Unit price | At most 99,999,999.99 | Price cannot be more than 99,999,999.99. |
| List name | Required after normalization | Enter a list name. |
| List name | 60 characters or fewer | List name must be 60 characters or fewer. |

Input formatter rule: the quantity and price fields use a custom formatter. It keeps the old text when a change would make the text not match digits plus one optional dot, or would add a decimal digit beyond the limit. A paste of "1,500" changes nothing. The agent must not silently drop characters, because "1,5" would turn into "15".

### 12.2 Limits and system errors

| Situation | Expected behavior | Message |
| --- | --- | --- |
| 500 items in a list | Block add. The form does not open. | This list has 500 items. Remove an item to add another. |
| Undo would exceed 500 items | Restore fails. The list is unchanged. | This list already has 500 items. Remove one before you undo. |
| 100 lists | Block create and duplicate. | You have 100 lists. Delete a list to create another. |
| Storage full on save | Keep the form open with the typed values. | Your phone storage is full. Free some space and try again. |
| Storage full on PDF build | Stay on the list. | Could not create the PDF. Your phone storage may be full. |
| Other database error on save | Keep the form open. | Something went wrong while saving. Try again. |
| Database cannot open at startup | Show a full-screen error. Never delete the database file. | Could not open your data. Close the app and try again. |
| Database schema is newer than the app | Show a full-screen error. Never change the file. | This data was created by a newer version of the app. Update the app to open it. |
| Item fails to load in edit mode | Show a Back button. | Could not load this item. |
| Setting save fails | Keep the old value. | Could not save your setting. |
| First-run save fails | Keep the sheet open. | Something went wrong while saving. Try again. |
| PDF build fails | Stay on the list. | Could not create the PDF. Try again. |
| Share sheet fails to open | Stay on the list. | Could not open the share sheet. Try again. |

### 12.3 Edge cases

| Case | Expected behavior |
| --- | --- |
| Empty list | Total reads 0.00. The empty state shows. Share is disabled with the tooltip "Add at least one item to share." |
| Duplicate item name | Dialog titled "Duplicate item". Body: "<name> is already on this list. Add it again?" Buttons: Add anyway, Cancel. Applies in add mode, and in edit mode when the name changes. |
| Duplicate list names | Allowed. Lists are told apart by their id. |
| Quantity 0 or empty | Field error from 12.1. No save. |
| Price 0 | Allowed. The row shows a line total of 0.00. No message. |
| Negative numbers | The minus sign cannot be typed. A paste with a minus sign changes nothing. |
| Very large numbers | Limits from 12.1 apply. The total text uses `FittedBox`. In the PDF, amount cells never wrap. |
| Decimals | "1500.5" saves as 1,500.50. "1500." saves as 1,500.00. ".5" saves as 0.50. "007" saves as 7. |
| Pasted line breaks or tabs | Normalization turns them into single spaces (section 8.4). |
| Long names | Max 80 characters. The list row shows 2 lines and then an ellipsis. The edit form and the PDF show the full name. |
| Special characters and emoji | Allowed and stored as typed. Database access uses bound parameters, so quotes are safe. The PDF font has no emoji or CJK glyphs. Those characters may show as empty boxes. The PDF build must not crash. A test covers this. |
| Only spaces in a name | Treated as empty. Show "Enter an item name." |
| Double tap on Save | Both buttons disable during `submitting`. Only one item saves. |
| Rapid checkbox taps | Each tap is its own transaction. The last tap wins. The summary never shows a count above the item count. |
| App killed during a save | The write is one transaction. After restart the item is either fully saved or absent. Typed but unsaved form text is lost. |
| Undo and leaving the screen | The Undo snackbar clears when the user leaves List Detail or opens the Item Form. The delete is then final. |
| Search with no match | Show "No items match "<query>"." The total and summary stay visible. |
| Currency change on a list | Amounts stay the same. No conversion. Other lists keep their currency. |
| Device time zone or date changes | Times are stored in UTC and shown in local time. Order does not change. |
| Text scale 200 percent | All screens scroll and nothing is cut off. |
| Small screen (320 x 568 dp) | No overflow. Forms scroll above the keyboard (`resizeToAvoidBottomInset: true`). |
| Rotation | Layouts do not break. |
| Share sheet dismissed | No message. Status returns to `idle`. |
| List name with no letters or digits | The PDF file name uses `shopping-list` (section 11.3). |

## 13. Testing Strategy

Tests use `flutter_test`, `bloc_test`, `mocktail`, Drift's in-memory database (`NativeDatabase.memory()`), and `integration_test`. The agent writes tests with each milestone. Test names include the requirement ID, for example `FR-061 rounds half up`.

### 13.1 Test types and coverage targets

| Type | Scope | Coverage target |
| --- | --- | --- |
| Unit: domain | Value objects, entities, normalization, validation, use cases (mocked repositories) | 95 percent |
| Unit: data | Mappers, DAOs on an in-memory database, repository implementations, migrations, PDF generator output | 85 percent |
| Bloc and Cubit tests | Every state transition in section 10 with `blocTest` | 90 percent |
| Widget tests | Each screen in loading, success, empty, and error states, at text scale 2.0 and at 320 x 568 dp | Every screen |
| Architecture test | Import and feature dependency rules from section 9.2 | Must pass |
| Contrast test | Contrast ratio for every palette pair (NFR-010) | Must pass |
| Integration test | Full user flows on a device or emulator | 4 flows below |
| Overall | `flutter test --coverage` | 80 percent |

### 13.2 Key test cases by feature

| Feature | Key test cases |
| --- | --- |
| Money and quantity (FR-061) | Parse "1500.5" to 150050. Parse "2.5" to 2500. Reject 4 decimals on quantity and 3 on price. All rows in section 8.5. Maximum values give no overflow. Line and list totals on 500 random items equal an independent `BigInt` calculation. |
| SQL parity (FR-063) | On 1,000 random items across several lists, each SQL total equals the Dart total. |
| Normalization (section 8.4) | Line breaks and tabs become single spaces. Control characters are removed. An empty unit becomes null. |
| Validation (FR-011) | Each row in 12.1 gives the exact message. A field shows its error only when touched or after submit. |
| First run (FR-092) | Region NG preselects NGN. An unsupported region preselects USD. Continue creates "Market list" with that currency in one transaction. A kill before Continue shows the sheet again. A failed transaction leaves no list and no settings change. |
| Lists (FR-001 to FR-007) | Create with the default currency. Rename. Delete with cascade. Duplicate keeps currency and resets bought. 100 list limit. Change currency leaves other lists alone. Order by updated time, and a tick on an item moves its list to the top (FR-080). |
| Add item (FR-010 to FR-016) | Valid save. Save and add another resets the form. Duplicate warning in add mode and in edit mode on a name change. 500 item limit. Preview updates while typing. |
| View list (FR-020 to FR-023) | Item order is oldest first. Empty state. Search keeps the total. Failure state and Retry. |
| Edit (FR-030, FR-031) | Prefill. Update keeps position. Total updates. Discard dialog on a dirty form. A failed load shows the load message. |
| Delete and undo (FR-040, FR-041) | Delete lowers the total. Restore returns the same id, values, and position. Restore fails at 500 items. Undo is cleared on leaving the screen and on opening the form. Delete from the edit form returns the item. |
| Bought (FR-050) | Toggle persists. Total does not change. Summary text is correct. |
| Total (FR-060 to FR-062) | Total after add, edit, delete, and restore. Empty total is 0.00. |
| PDF and share (FR-070 to FR-074) | The file starts with the bytes `%PDF`. The file is not empty. ₦, GH₵, £, and € render. Emoji in a name does not crash the build. A 500-item list builds in under 3 seconds. File name slug rules. Headers use the list currency. Text share matches 11.6 exactly. Share is disabled when empty. A dismissed share is not an error. Old export files are deleted. |
| Storage (FR-080 to FR-083) | Data survives closing and reopening the database. A thrown error inside a transaction leaves no partial row. A fake SQLITE_FULL maps to `StorageFullFailure`. Each migration step keeps data. A newer-schema database opens as `SchemaTooNewFailure` and the file is unchanged. |
| Settings (FR-090, FR-091) | Default currency applies to new lists only. Theme persists. |
| Accessibility (NFR-009 to NFR-012) | Tap target guideline passes. Semantics label matches NFR-012. No overflow at text scale 2.0 or at 320 x 568 dp. |

### 13.3 Integration flows (`integration_test/app_flow_test.dart`)

1. **First run.** Fresh install. Confirm the currency. The list "Market list" opens.
2. **Happy path.** Add 3 items. Check the total. Edit one price. Check the new total. Delete an item. Undo. Check the total again.
3. **Persistence.** Add items. Restart the app inside the test. Check that lists and items remain.
4. **Share.** Add items. Open the share sheet. Run both options with a fake `ShareService`. Check that the fake receives a non-empty PDF path and the correct text.

Real WhatsApp delivery, the backup restore, and the 20 force-stop cycles (G3) are manual checks. Section 16 lists them.

## 14. Dependencies

All versions are "latest stable". I cannot confirm exact version numbers from here. The agent adds each package with `flutter pub add <name>` (or `flutter pub add --dev <name>`), lets pub resolve the version, and follows that version's own documentation if an API differs from this PRD. The agent records resolved versions in `README.md`.

| Package | Type | Purpose | Reason for choosing it |
| --- | --- | --- | --- |
| `flutter_bloc` | Runtime | State management (Bloc and Cubit) | Required by your brief. |
| `bloc_concurrency` | Runtime | `restartable()` event transformer for the List Detail stream | Prevents double subscriptions. |
| `equatable` | Runtime | Value equality for states, events, entities | Less boilerplate and reliable Bloc rebuilds. |
| `fpdart` | Runtime | `Either` and `Unit` for failure handling | Maintained functional types. |
| `get_it` | Runtime | Dependency injection | Simple, no code generation. |
| `drift` | Runtime | Typed SQLite access, migrations, `.watch()` streams | See the database note below. |
| `drift_flutter` | Runtime | Opens the SQLite database on Android and iOS | Removes manual native setup. |
| `path_provider` | Runtime | Temp folder for PDF exports | Official plugin. |
| `path` | Runtime | Safe file path joins | Standard Dart package. |
| `pdf` | Runtime | Builds the PDF in Dart | Pure Dart, offline, supports custom fonts. |
| `share_plus` | Runtime | Opens the system share sheet with a file or text | Maintained by the Flutter Community. Works on Android and iOS. |
| `intl` | Runtime | Date format and number grouping | Official Dart package. |
| `uuid` | Runtime | UUID v4 ids | Ids that need no database counter. |
| `drift_dev` | Dev | Code generation and schema tools for Drift | Required by Drift. |
| `build_runner` | Dev | Runs code generation | Required by Drift. |
| `bloc_test` | Dev | `blocTest` for Bloc and Cubit tests | Standard for Bloc. |
| `mocktail` | Dev | Mocks without code generation | Simple and null-safe. |
| `integration_test` | Dev (SDK) | Device-level flow tests | Ships with Flutter. |
| `flutter_lints` | Dev | Lint rules | Ships with the Flutter template. |
| `flutter_launcher_icons` | Dev | Generates app icons | Saves manual work. |
| `flutter_native_splash` | Dev | Generates the splash screen and holds it during startup | Needed for the startup gate (section 10.2). |

**Database note.** I chose Drift on SQLite. Drift gives typed queries, a migration tool with schema dumps, reactive streams for live totals, and in-memory databases for fast tests. SQLite writes are transactional, which supports NFR-006.

**PDF to WhatsApp path.** `pdf` writes a file. `share_plus` hands that file to the system share sheet. The user picks WhatsApp. No WhatsApp SDK or API is used (CO-03).

**Not used on purpose:** `go_router` (four screens do not need it; `Navigator` passes results natively), `printing`, `shared_preferences` (settings live in Drift so there is one storage tech), `url_launcher` and any WhatsApp plugin, and any analytics or crash package (NFR-017).

## 15. AI Agent Build Plan

Build in this order. Do not start a milestone until the previous one passes its verify step. Commit after each milestone with a message like `M3: data layer (FR-080 to FR-083)`. Verify steps are commands the agent can run without a device. Device checks are marked **manual**.

### Rules the agent must follow

1. Follow the import and feature rules in section 9.2. The architecture test must stay green.
2. Put no business logic in widgets, Blocs, or Cubits. Rules live in entities, value objects, and use cases.
3. Write one use case per class and one public class per file.
4. Never use `double` for money or quantity (section 8.5).
5. Take every color from the theme (section 7). Never hard-code a color in a widget.
6. Write every user-facing error string only in `failure_messages.dart` (section 12).
7. Add no package outside section 14. If you need one, write the request in `QUESTIONS.md`, continue with the closest allowed option, and record the choice in `DECISIONS.md`.
8. Do not edit generated files (`*.g.dart`). Add them to `.gitignore` and regenerate with `build_runner`.
9. Run `flutter analyze` and `flutter test` at the end of every milestone. Fix failures before you continue.
10. If the PRD is unclear or two sections conflict, write the question in `QUESTIONS.md`, use the default in section 18, and record the choice in `DECISIONS.md`.
11. Keep widgets under 150 lines. Extract smaller widgets. Use `const` constructors.
12. Never log user data. Never add network code.
13. Test names include the requirement ID.

### M0. Project setup

- **Goal:** An empty app builds with the folder structure, lints, theme, DI, and router.
- **Tasks:** Run `flutter create --platforms android,ios market_list`. Add packages from section 14. Create the folders from 9.1. Set `analysis_options.yaml` with `flutter_lints`, `avoid_print`, `prefer_const_constructors`, and `always_use_package_imports`. Write `AppColors`, both `ColorScheme` objects (section 7), and `AppTheme`. Add the Noto Sans fonts. Stub `injection.dart` and `app_router.dart`.
- **Files:** `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/core/theme/*`, `lib/core/di/injection.dart`, `lib/core/router/app_router.dart`.
- **Definition of done:**
    - [ ] The app builds and shows a placeholder page with an orange primary color.
    - [ ] Light and dark themes exist.
    - [ ] The contrast test passes for every palette pair.
    - [ ] The Flutter version is written in `README.md`.
- **Verify:** `flutter analyze && flutter test && flutter build apk --debug`

### M1. Core foundations

- **Goal:** Money, quantity, currency, normalization, failures, formatters, and base classes exist and are tested.
- **Tasks:** Write `AppLimits`, `Failure` classes, `UseCase` and `StreamUseCase`, `Money`, `Quantity`, `CurrencyCode`, `TextNormalizer`, the formatters, `Clock`, and `IdGenerator`. Write all rounding, parsing, and normalization tests.
- **Files:** `lib/core/constants/*`, `lib/core/error/failures.dart`, `lib/core/usecase/usecase.dart`, `lib/core/domain/*`, `lib/core/formatting/*`, `lib/core/platform/*`, matching tests.
- **Definition of done:**
    - [ ] Every rounding example passes.
    - [ ] The `BigInt` cross-check test passes.
    - [ ] Formatter output matches section 7.6.
- **Verify:** `flutter test test/core --coverage`

### M2. Domain layer

- **Goal:** All entities, interfaces, and use cases exist with mocked tests.
- **Tasks:** Write the entities and interfaces from 9.3 and 9.4. Write `ValidateItemDraft` with every rule in 12.1. Write `ListDetail` getters. Include `GetListDetail`, `SetListCurrency`, and `CompleteOnboarding`.
- **Files:** `lib/features/*/domain/**`, matching tests.
- **Definition of done:**
    - [ ] Every use case has tests for success and failure.
    - [ ] `RestoreItem` fails at 500 items.
    - [ ] The domain folders import no Flutter, Drift, pdf, or share_plus.
- **Verify:** `flutter test test/features --coverage`

### M3. Database and data layer

- **Goal:** Data saves to SQLite and reads back through repositories.
- **Tasks:** Write the Drift tables and DAOs from section 8. Set schema version 1 and the pragmas. Implement the touch rule, the SQL mirror total, and the join query. Dump the schema. Write mappers, data sources, and repository implementations. Map exceptions to Failures (9.6). Wrap multi-step writes in transactions.
- **Files:** `lib/core/database/**`, `lib/features/*/data/**`, `drift_schemas/`, matching tests.
- **Definition of done:**
    - [ ] CRUD tests pass on an in-memory database.
    - [ ] Cascade delete test passes.
    - [ ] A thrown error inside a transaction leaves no partial row.
    - [ ] A fake SQLITE_FULL maps to `StorageFullFailure`.
    - [ ] The SQL parity test passes on 1,000 random rows.
    - [ ] A newer-schema database gives `SchemaTooNewFailure` and stays unchanged.
- **Verify:** `dart run build_runner build --delete-conflicting-outputs && flutter test test/core/database test/features`

### M4. Settings, first run, DI, and theme wiring

- **Goal:** First-run setup, default currency, and theme work and persist.
- **Tasks:** Write `SettingsCubit`, `SettingsPage`, and `OnboardingSheet`. Wire all `get_it` registrations. Hold the native splash until settings load. Apply `themeMode` in `MaterialApp`. Read the region from `PlatformDispatcher.instance.locale.countryCode`.
- **Files:** `lib/features/settings/presentation/**`, `lib/core/di/injection.dart`, `lib/app.dart`.
- **Definition of done:**
    - [ ] FR-090 to FR-092 pass in tests.
    - [ ] Cubit tests cover each transition in 10.2.
- **Verify:** `flutter test test/features/settings && flutter build apk --debug`. **Manual:** fresh install shows the sheet.

### M5. Lists screen

- **Goal:** The user creates, renames, changes currency of, duplicates, and deletes lists.
- **Tasks:** Write `ListsCubit`, `ListsPage`, `ListCard`, dialogs, and the route. Route list taps to a placeholder List Detail page until M6. Build the empty, loading, and error states.
- **Files:** `lib/features/shopping_lists/presentation/**`.
- **Definition of done:**
    - [ ] FR-001 to FR-007 pass.
    - [ ] Cubit tests cover each transition in 10.3.
    - [ ] Widget tests cover the 3 states.
- **Verify:** `flutter test test/features/shopping_lists`

### M6. List Detail, total, bought, delete, undo

- **Goal:** The user sees items, the total, and can tick, delete, and undo.
- **Tasks:** Write `ListDetailBloc`, `ListDetailPage`, `SummaryCard`, `ItemTile`, swipe to delete, the Undo snackbar rules, and the list menu. Add a debug-only seed action (guarded by `kDebugMode`) that inserts 5 sample items, so the screen can be checked before M7.
- **Files:** `lib/features/items/presentation/bloc/**`, `pages/list_detail_page.dart`, `widgets/*`.
- **Definition of done:**
    - [ ] FR-020 to FR-023, FR-040, FR-041, FR-050, FR-060 to FR-063 pass.
    - [ ] Bloc tests cover each event in 10.4.
    - [ ] The Undo snackbar clears on leaving and on opening the form.
- **Verify:** `flutter test test/features/items`

### M7. Item form

- **Goal:** The user adds and edits items with full validation.
- **Tasks:** Write `ItemFormCubit`, `ItemFormPage`, the number input formatters (12.1), unit chips, line preview, duplicate dialog, Save and add another, discard guard, and Delete in edit mode. Remove the debug seed or keep it behind `kDebugMode`.
- **Files:** `lib/features/items/presentation/cubit/**`, `pages/item_form_page.dart`, `widgets/unit_chips.dart`.
- **Definition of done:**
    - [ ] FR-010 to FR-016, FR-030, FR-031 pass.
    - [ ] Every message in 12.1 shows exactly, and only on touched fields or after submit.
    - [ ] A double tap on Save creates one item.
- **Verify:** `flutter test test/features/items && flutter build apk --debug`

### M8. PDF and sharing

- **Goal:** The user shares a PDF or text list through the system share sheet.
- **Tasks:** Write `PdfListGenerator` to the layout in 11.1 and 11.2. Write the export use cases, `SharePlusService`, `TempExportFileStore`, `ShareCubit`, and the share bottom sheet. Run `CleanupExports` at startup.
- **Files:** `lib/features/export/**`, `assets/fonts/*`.
- **Definition of done:**
    - [ ] FR-070 to FR-074 pass in tests.
    - [ ] The glyph test renders ₦, GH₵, £, and € and the output is checked by eye.
    - [ ] A 200-item list builds in under 3 seconds.
    - [ ] **Manual:** share to WhatsApp on a real Android phone.
- **Verify:** `flutter test test/features/export` plus the manual WhatsApp check

### M9. Quality pass

- **Goal:** Accessibility, search, architecture test, and integration tests are done.
- **Tasks:** Add search (FR-022). Add semantics labels (NFR-012). Run text scale 2.0 and 320 x 568 tests. Write `architecture_test.dart`. Write the 4 integration flows from 13.3. Check coverage and app size.
- **Files:** `test/architecture_test.dart`, `integration_test/app_flow_test.dart`, widget tests.
- **Definition of done:**
    - [ ] All NFR checks in section 5 pass or are marked manual.
    - [ ] Coverage meets NFR-016.
    - [ ] No analyzer issues.
- **Verify:** `flutter analyze && flutter test --coverage && flutter test integration_test` (the last needs an emulator and is a manual step if none exists)

### M10. Release preparation

- **Goal:** The app is ready for the stores.
- **Tasks:** Complete section 16. Set the app name and IDs. Make the icon and splash. Add Android backup rules. Remove any unneeded permission. Set up signing.
- **Files:** Android and iOS project files, icon and splash assets, `pubspec.yaml`.
- **Definition of done:** Every item in section 16 is checked.
- **Verify:** `flutter build appbundle --release` (and `flutter build ipa --release` on a Mac)

## 16. Release Checklist

- [ ] **App name.** Placeholder: "Market List". Confirm the final name (Open Question 6). The store name, launcher name, and PDF footer all use it.
- [ ] **Package ID.** Placeholder: `com.example.marketlist`. Replace it with your own reverse-domain ID before the first store upload. Use the same ID for Android `applicationId` and the iOS bundle identifier. It cannot change after release.
- [ ] **Version.** Start at `1.0.0+1`.
- [ ] **App icon.** 1024 x 1024 PNG with no transparency for iOS. Android adaptive icon with a foreground layer and an orange (#F57C00) background layer.
- [ ] **Splash screen.** Orange (#F57C00) background with the app icon in the center. Dark mode uses #141210.
- [ ] **Permissions.** The release app needs none. Check the merged release `AndroidManifest.xml` and confirm it has no `INTERNET` permission. iOS needs no usage description strings.
- [ ] **Android backup rules.** `android:allowBackup="true"` with rules that include only the database file (section 8.6). **Manual:** test backup and restore with Android's `bmgr` tool.
- [ ] **Developer accounts.** Google Play developer account (one-time fee). Apple Developer Program (yearly fee, needed to publish). Check Google's current testing requirements for new developer accounts before you plan the launch date.
- [ ] **Signing.** Create an Android upload keystore and keep it out of git. Set up iOS signing in Xcode.
- [ ] **Builds.** `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` for Android. `flutter build ipa --release` on a Mac for iOS.
- [ ] **Manual device tests.** One older and one newer Android phone, and one iPhone. Check: first run, add, edit, delete, undo, totals, restart, airplane mode, dark mode, large text, a 320 dp wide screen, sharing the PDF to WhatsApp and to another app, and 20 force-stop cycles (G3).
- [ ] **Store listing basics.** Short description (80 characters or fewer), full description, at least 4 phone screenshots (Lists, List Detail, Item Form, shared PDF), feature graphic for Google Play (1024 x 500), category Food and Drink or Productivity, content rating questionnaire, support email.
- [ ] **Privacy.** Google Play Data safety form: no data collected, none shared. Apple App Privacy: Data Not Collected. Publish a short privacy policy page and enter its URL in both stores.
- [ ] **Crash visibility.** The app has no crash SDK (NFR-017). Read crashes from Play Console vitals and App Store Connect. Check them weekly after launch (G6).

## 17. Future Roadmap

These ideas are outside the MVP. The agent must not build them.

1. **Backup and restore (v1.1, top priority).** Export all lists to a JSON file and import them on a new phone. This closes the gap in CO-01. Until then, About tells users that phone backup may restore their lists.
2. **Categories with subtotals (v1.2).** Group items by category and show a subtotal per group in the app and the PDF.
3. **Item memory (v1.2).** Suggest names, units, and the last price as the user types, based on past items.
4. **PDF options (v1.3).** Toggle prices on or off in the PDF. Add a "remaining to buy" total for items not yet bought.
5. **More languages and number formats (v2.0).** Localize the UI. Support comma decimals and more currencies, including zero-decimal ones.

**Monetization.** None in v1.0 (section 1). If the app becomes a product, items 2 to 4 are the first candidates for a paid tier.

## 18. Open Questions

Answer these before the build starts. If you do not answer, the agent uses the default in the third column.

| No. | Question | Default if unanswered | Affects |
| --- | --- | --- | --- |
| 1 | Is the price the price per unit (per kg, per piece), or the total price for the whole line? | Per unit. Line total = quantity x price. | AS-01, section 8 |
| 2 | Which default currency should the first-run sheet preselect, and do you need currencies beyond the 7 listed? | Device locale, else USD. 7 currencies. | AS-05, FR-092 |
| 3 | Should the shared PDF show prices, or only item names and quantities? | Show prices. A toggle moves to the roadmap. | Section 11 |
| 4 | Is the system share sheet enough, or must the app open a specific WhatsApp chat directly? | Share sheet only. | CO-03 |
| 5 | Do you accept multiple lists as a Must in v1.0? | Yes (AD-01). | Sections 4.1 and 6 |
| 6 | What is the final app name and package ID? | "Market List" and `com.example.marketlist` as placeholders. | Section 16 |
| 7 | Do you need decimal quantities such as 1.5 kg? | Yes, up to 3 decimals. | AS-02 |
| 8 | Should v1.0 ship on Android only, or on Android and iOS? iOS needs a Mac and a paid Apple Developer account to publish. | Build for both. Ship Android first if iOS is not ready. | NFR-013, section 16 |
| 9 | May Android Auto Backup restore the lists on a new phone? | Yes, with the rules in section 8.6. | AS-12 |
| 10 | Is English enough for v1.0? | English only. | AS-07 |
| 11 | Is this a commercial product or a personal tool? | Free, no ads, no revenue goal. | Section 1, section 17 |
| 12 | Which country or market launches first? | Not set. It only affects store listing text and the first-run currency check. | Section 16 |
| 13 | Do you accept the first-run currency sheet as the first thing a new user sees? | Yes. | AD-13, FR-092 |

## 19. One-Page Summary for the AI Agent

**Read this first.** Build an offline Flutter app (Android and iOS) where a user writes food shopping lists with item name, quantity, unit, and unit price, sees the total, and shares a list as a PDF or text through the system share sheet to WhatsApp.

**Stack (locked).** Flutter and Dart. Clean Architecture with `domain`, `data`, `presentation` per feature. `flutter_bloc` (one Bloc: `ListDetailBloc`; Cubits: `SettingsCubit`, `ListsCubit`, `ItemFormCubit`, `ShareCubit`). Drift on SQLite. `get_it`. Plain `Navigator` with `onGenerateRoute`. `pdf` and `share_plus`. `fpdart` for `Either`. Full list: section 14.

**First run.** A currency sheet appears. On Continue, one transaction saves the default currency and creates the list "Market list". Section 4.10, FR-092.

**Currency.** Each list stores its own currency. Settings holds the default for new lists. Changing a currency never converts amounts and never touches other lists. AD-05, FR-007.

**Screens.** Lists, List Detail, Item Form (add and edit), Settings, plus the first-run sheet. Section 6.

**Money rules.** `int` only. Price in minor units, quantity in thousandths. Line total = `(quantityMilli * unitPriceMinor + 500) ~/ 1000`. List total = sum of line totals. The Lists screen uses an SQL mirror of the same formula, proven equal by a parity test. Never use `double`. Section 8.5.

**Data safety.** Every write is one transaction and also touches the parent list's `updated_at`. SQLite default journal, `synchronous = FULL`, no WAL. Newer-schema databases are never altered. Sections 8.2, 8.6.

**Limits.** 100 lists. 500 items per list. Name 80, list name 60, unit 20. Quantity 0.001 to 9,999.999. Price 0 to 99,999,999.99. Undo respects the 500 limit. Section 8.3.

**Design.** Material 3. Light primary orange #F57C00 with on-primary #1A1A1A. Orange text and focus borders on light surfaces use #B45200. Dark primary #FFB74D. Build schemes with `fromSeed` then `copyWith`. Section 7.

**Must-have features.** Add, view, edit, delete items. Totals. PDF share. Local storage. Lists with their own currency. First-run setup. See FR-001, FR-010, FR-020, FR-030, FR-040, FR-060, FR-070, FR-080, FR-090, FR-092.

**Should-have additions (need your approval).** Unit labels, bought checkbox, undo delete, text share, save and add another, dark mode, PDF tick boxes, swipe delete, change list currency. Section 2.

**Hard rules.**

- Domain imports no Flutter, Drift, pdf, or share_plus. Presentation imports no data layer. Features import other features' domain layers only, in one direction. Section 9.2.
- No business logic in widgets. One use case per class.
- All user-facing error text lives in `failure_messages.dart`. Section 12.
- The PDF uses the bundled Noto Sans font. Test that ₦, GH₵, £, and € render. Section 11.1.
- No network code, no analytics, no INTERNET permission in release.
- Verify with commands that need no device. Mark device checks manual. Section 15.

**Order of work.** M0 setup, M1 core, M2 domain, M3 data, M4 settings and first run, M5 lists screen, M6 list detail, M7 item form, M8 PDF and share, M9 quality, M10 release. Section 15.

**When unsure.** Write the question in `QUESTIONS.md`. Use the default in section 18. Record the choice in `DECISIONS.md`. Do not guess silently.

## Appendix A. Review changes

| ID | Change | Where |
| --- | --- | --- |
| R1 | Timed goals, free and no-ads stance, store signals | 1, 16 |
| R2 | Multiple lists are Must. First run creates "Market list". Fallback removed. | 2, 4.1, 4.10, 6 |
| R3 | Untagged decisions tagged. Count is 39. | 2 |
| R4 | "Covered by" column for stories | 3 |
| R5 | Duplicate check covers edit mode on a name change | FR-015, 10.5 |
| R6 | Undo clears on navigation. Restore obeys the 500 limit. | FR-041, 10.4, 12.2 |
| R7 | Every write touches the list's `updated_at` | FR-080, 8.2 |
| R8 | SQL mirror total with a parity test | FR-063, 8.5, 13 |
| R9 | WAL removed. Backup rules and newer-schema guard added. | NFR-006, NFR-019, 8.6, FR-082 |
| R10 | First-run currency sheet. Currency code on the summary card. | FR-092, 6.0, 6.2 |
| R11 | Focus border uses `primaryText` | 7.1, 7.4, NFR-010 |
| R12 | Palette built with `fromSeed` and `copyWith`. Current slot names. Inverse tokens. | 7 |
| R13 | Currency stored per list | 8, FR-007, FR-090 |
| R14 | Text normalization rules | 8.4 |
| R15 | `getListDetail` added | 9.3, 9.4 |
| R16 | Feature dependency rule | 9.2 |
| R17 | One join query for list detail | 9.5 |
| R18 | `touched` set for error display | 10.5 |
| R19 | Native splash held until settings load | 10.2 |
| R20 | Unverified claims softened. Glyph test added. | 11, AS-19 |
| R21 | Edge cases added. Dead case removed. | 12 |
| R22 | Contrast, small screen, parity, onboarding, and schema tests added | 13 |
| R23 | `go_router` and `bloc` removed. Database note rewritten. | 14, 6 |
| R24 | Device-free verify commands. Debug seed. Rule 7 fixed. Onboarding in M4. | 15 |
| R25 | Accounts, fees, testing policy check, crash visibility | 16 |
| R26 | About text on backup. Backup is the top roadmap item. | 6.4, 17 |
| R27 | Open questions updated | 18 |
| R28 | Summary rewritten | 19 |
