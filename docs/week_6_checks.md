# Week 6 Development Checks

Last updated: 14 October 2026
Platform: Flutter Web in desktop Chrome on Windows
Status: In progress

## Expiry implementation

ExpiryUtils provides shared date calculations and classification.

- Expired: expiry date before today.
- Expiring Soon: today through three days ahead, inclusive.
- Later: more than three days ahead.
- Unknown: missing, malformed or impossible expiry date.

Calendar-day differences avoid daylight-saving time effects.
The threshold is defined as soonThresholdDays = 3.

Home groups active pantry items by expiry status.
Search and category filters apply before grouping.
Inactive items and items with zero remaining quantity are excluded.
Date reminders do not establish whether food is safe to eat.

## Automated expiry tests

Seven tests passed using a fixed reference date:

| Case | Expected result |
|---|---|
| Yesterday | Expired; -1 day |
| Today | Expiring Soon; 0 days |
| Tomorrow | Expiring Soon; 1 day |
| Three days ahead | Expiring Soon; 3 days |
| Four days ahead | Later; 4 days |
| Missing, malformed or impossible date | Unknown |
| 31 December to 1 January | 1 calendar day |

These tests check the utility independently of Firebase.

## Manual expiry checks

Using a zero-price test item and 14 October 2026 as today:

| Expiry date | Observed result |
|---|---|
| 14 October | Expiring Soon; Expires today |
| 17 October | Expiring Soon; Expires in 3 days |
| 18 October | Later; Expires in 4 days |
| 15 October | Expiring Soon; Expires tomorrow |
| 13 October | Expired; Expired 13/10/2026 |

For the expired case, purchase date was also set to 13 October.
The form correctly requires expiry to be on or after purchase.

Marking the final unit as wasted removed the item from the
active expiry groups. Its £0.00 purchase remained in Budget.

## Previously completed inventory and spending checks

- Partial use and waste reduced current quantity.
- Purchased quantity and original spending stayed unchanged.
- Requests exceeding available quantity were rejected.
- Purchase corrections preserved quantities already resolved.
- Weekly totals were compared with hand calculations.
- Sunday and Monday purchase-date boundaries were checked.
- Removed inventory retained its purchase record.
- Account switching showed separate purchase lists.

These manual results were obtained during earlier development.
They do not replace automated transaction or calculation tests.

## Latest code checks

- flutter analyze: No issues found.
- flutter test: All 8 tests passed.
- Coverage: 7 expiry utility tests and 1 navigation widget test.

The current automated suite does not test all database workflows.

## Remaining Week 6 work

- Explicit repeated-action and concurrency checks.
- Shared spending calculations with automated tests.
- Daily spending breakdown.
- Weekly budget stored in settings.
- Remaining-budget display.
- Consistent spending summaries on Home and Budget.
- Recheck search and category filters with the expiry groups.
- Verify date groups update correctly across a change of day.

## Scope decision from lecturer feedback

Keep the core workflow simple and prioritise deadlines.
Barcode scanning remains optional and may be dropped if difficult.
AI receipt scanning, maps, donation and background push are deferred.

## Spending update on 14 October 2026

SpendingUtils now provides shared weekly selection, weekly totals,
seven daily totals and remaining-budget arithmetic.

All 11 spending utility tests passed, covering known totals,
Monday/Sunday boundaries, year boundaries, empty weeks, invalid
records, zero-price purchases and overspending.

Budget now uses SpendingUtils and displays Monday–Sunday daily totals.

Manual check:
- Added 2 items at £0.50 each, purchased on Tuesday, 13 October.
- Tuesday's amount and the weekly total both increased by £1.00.
- Marked both items used.
- Daily and weekly spending remained unchanged.

Latest checks:
- flutter analyze: No issues found.
- flutter test: All 19 tests passed
  (11 spending, 7 expiry and 1 navigation).

The earlier eight-test result records the expiry checkpoint.
Daily breakdown and shared calculation tests are now complete.
Saved weekly budgets, remaining-budget display and Home spending
summaries are still outstanding, along with the other pending checks.