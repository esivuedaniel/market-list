# DECISIONS.md

One job: the permanent record of what the user decided. Nothing else goes in this file.

## Rules for this file

- Append only. A row changes status once, from Pending to Approved or Rejected. After that it never changes. To reverse a decision, add a log entry that cites the row. Reason: later sessions read this file as fact. A silent edit changes the facts.
- Write a status or an answer only after the user states it in chat. Reason: an answer the agent writes for the user is an invented decision.
- Status is exactly one of Pending, Approved, Rejected. Reason: any other word cannot be checked.
- Every log entry names its source: `user` or `PRD section 18 default`. Reason: a reviewer must see which answers the user really gave.
- One decision per entry. Number entries D-001, D-002, and so on. Never reuse an ID. Reason: a mixed or unnumbered entry cannot be cited.

## Approvals (PRD section 2)

Descriptions live in the PRD. Do not copy them here. Reason: one source of truth.

| ID | Status | Date | Note |
| --- | --- | --- | --- |
| CO-01 | Approved | 2026-10-14 |  |
| CO-02 | Approved | 2026-10-14 |  |
| CO-03 | Approved | 2026-10-14 |  |
| CO-04 | Approved | 2026-10-14 |  |
| AS-01 | Approved | 2026-10-14 |  |
| AS-02 | Approved | 2026-10-14 |  |
| AS-03 | Approved | 2026-10-14 |  |
| AS-04 | Approved | 2026-10-14 |  |
| AS-05 | Approved | 2026-10-14 |  |
| AS-06 | Approved | 2026-10-14 |  |
| AS-07 | Approved | 2026-10-14 |  |
| AS-08 | Approved | 2026-10-14 |  |
| AS-09 | Approved | 2026-10-14 |  |
| AS-10 | Approved | 2026-10-14 |  |
| AS-11 | Approved | 2026-10-14 |  |
| AS-12 | Approved | 2026-10-14 |  |
| AS-13 | Approved | 2026-10-14 |  |
| AS-14 | Approved | 2026-10-14 |  |
| AS-15 | Approved | 2026-10-14 |  |
| AS-16 | Approved | 2026-10-14 |  |
| AS-17 | Approved | 2026-10-14 |  |
| AS-18 | Approved | 2026-10-14 |  |
| AS-19 | Approved | 2026-10-14 |  |
| AS-20 | Approved | 2026-10-14 |  |
| AD-01 | Approved | 2026-10-14 |  |
| AD-02 | Approved | 2026-10-14 |  |
| AD-03 | Approved | 2026-10-14 |  |
| AD-04 | Approved | 2026-10-14 |  |
| AD-05 | Approved | 2026-10-14 |  |
| AD-06 | Approved | 2026-10-14 |  |
| AD-07 | Approved | 2026-10-14 |  |
| AD-08 | Approved | 2026-10-14 |  |
| AD-09 | Approved | 2026-10-14 |  |
| AD-10 | Approved | 2026-10-14 |  |
| AD-11 | Approved | 2026-10-14 |  |
| AD-12 | Approved | 2026-10-14 |  |
| AD-13 | Approved | 2026-10-14 |  |
| AD-14 | Approved | 2026-10-14 |  |
| AD-15 | Approved | 2026-10-14 |  |

## Decision log

| ID | Date | Source | Question | Answer | PRD reference |
| --- | --- | --- | --- | --- | --- |
| D-001 | 2026-10-14 | user | Is the price the price per unit (per kg, per piece), or the total price for the whole line? | The price is per unit (per kg, per piece). | AS-01, section 8 |
| D-002 | 2026-10-14 | user | Which default currency should the first-run sheet preselect, and do you need currencies beyond the 7 listed? | Default currency comes from the device locale, else USD. Keep the 7 listed currencies. | AS-05, FR-092 |
| D-003 | 2026-10-14 | user | Should the shared PDF show prices, or only item names and quantities? | Show prices in the shared PDF. | Section 11 |
| D-004 | 2026-10-14 | user | Is the system share sheet enough, or must the app open a specific WhatsApp chat directly? | The system share sheet is enough. | CO-03 |
| D-005 | 2026-10-14 | user | Do you accept multiple lists as a Must in v1.0? | Multiple lists are a Must in v1.0. | Sections 4.1 and 6 |
| D-006 | 2026-10-14 | user | What is the final app name and package ID? | App name "Market List". Keep the package ID Android Studio set. | Section 16 |
| D-007 | 2026-10-14 | user | Do you need decimal quantities such as 1.5 kg? | Allow decimal quantities, up to 3 decimals. | AS-02 |
| D-008 | 2026-10-14 | user | Should v1.0 ship on Android only, or on Android and iOS? | Build for Android and iOS. Ship Android first. | NFR-013, section 16 |
| D-009 | 2026-10-14 | user | May Android Auto Backup restore the lists on a new phone? | Android Auto Backup may restore the lists. | AS-12, section 8.6 |
| D-010 | 2026-10-14 | user | Is English enough for v1.0? | English only. | AS-07 |
| D-011 | 2026-10-14 | user | Is this a commercial product or a personal tool? | Free, no ads, no revenue goal. | Section 1, section 17 |
| D-012 | 2026-10-14 | user | Which country or market launches first? | No launch country set yet. | Section 16 |
| D-013 | 2026-10-14 | user | Do you accept the first-run currency sheet as the first thing a new user sees? | Yes, show the first-run currency sheet first. | AD-13, FR-092 |
| D-014 | 2026-10-14 | user | Are Android 7.0 (API 24) and iOS 13 supported by Flutter minimums? | Yes. Flutter 3.38.3 supports Android 5.0+ (API 21) and iOS 12.0+, covering the minimum targets. | AS-08 |
| D-015 | 2026-10-14 | user | Where should failure_messages.dart be placed? | Create lib/core/widgets/failure_messages.dart so all feature presentation layers can import it without violating import rules. | PRD 9.1, 9.6, 12, AGENTS.md |