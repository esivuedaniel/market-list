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
| CO-01 | Pending |  |  |
| CO-02 | Pending |  |  |
| CO-03 | Pending |  |  |
| CO-04 | Pending |  |  |
| AS-01 | Pending |  |  |
| AS-02 | Pending |  |  |
| AS-03 | Pending |  |  |
| AS-04 | Pending |  |  |
| AS-05 | Pending |  |  |
| AS-06 | Pending |  |  |
| AS-07 | Pending |  |  |
| AS-08 | Pending |  |  |
| AS-09 | Pending |  |  |
| AS-10 | Pending |  |  |
| AS-11 | Pending |  |  |
| AS-12 | Pending |  |  |
| AS-13 | Pending |  |  |
| AS-14 | Pending |  |  |
| AS-15 | Pending |  |  |
| AS-16 | Pending |  |  |
| AS-17 | Pending |  |  |
| AS-18 | Pending |  |  |
| AS-19 | Pending |  |  |
| AS-20 | Pending |  |  |
| AD-01 | Pending |  |  |
| AD-02 | Pending |  |  |
| AD-03 | Pending |  |  |
| AD-04 | Pending |  |  |
| AD-05 | Pending |  |  |
| AD-06 | Pending |  |  |
| AD-07 | Pending |  |  |
| AD-08 | Pending |  |  |
| AD-09 | Pending |  |  |
| AD-10 | Pending |  |  |
| AD-11 | Pending |  |  |
| AD-12 | Pending |  |  |
| AD-13 | Pending |  |  |
| AD-14 | Pending |  |  |
| AD-15 | Pending |  |  |

## Decision log

| ID | Date | Source | Question | Answer | PRD reference |
| --- | --- | --- | --- | --- | --- |