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

## Saved weekly budget update

SettingsService stores each user's reusable weekly limit at:
users/{uid}/settings/preferences

WeeklyBudgetScreen validates the amount and saves integer pence.
Budget displays an unset state, the saved limit, remaining budget,
or the amount over budget.

Manual checks passed:
- Saved £30.00 with £1.00 spending: £29.00 remaining.
- Refreshed Chrome: the limit and remaining amount persisted.
- Changed the limit to £0.50: £0.50 over budget.
- Spending remained £1.00 when the limit changed.
- Negative budget input was rejected.
- Restored £30.00: £29.00 remaining.
- Switched accounts: the other account had no budget set.

Earlier weeks are compared with the current reusable limit.
Historical weekly budget values are not stored.

Latest checks:
- flutter analyze: No issues found.
- flutter test: All 19 tests passed.

Saved budgets and the Budget remaining/overspending display are
now implemented. Home spending summaries and other pending
Week 6 checks remain outstanding.

## Home summary and repeated-action checks

Home now displays current-week spending, the saved weekly limit,
and the remaining or over-budget amount.

Manual checks passed:
- Home and Budget showed identical current-week values.
- Search and category filters worked with expiry groups.
- Clearing filters restored active items.
- Pantry filters did not change the spending summary.

Repeated-action check:
- Created a zero-price item with quantity 2.
- Temporarily submitted the same use action twice with one action ID.
- Remaining quantity became 1, confirming subtraction happened once.
- Removed the temporary test code.
- A new action with a new ID used the final unit.
- The item disappeared from the active pantry.

This verifies sequential retries with the same action ID.
Simultaneous requests have not yet been explicitly tested.

## Calendar-day refresh

DayRefreshMixin is connected to the pantry, Home spending summary
and Budget. It checks the date once a minute and when the app resumes.

Four automated tests passed:
- No refresh for time changes within the same calendar day.
- One refresh when crossing midnight.
- Immediate date check when resuming.
- Timer cancellation when the screen closes.

Budget advances to the new week if the current week was selected.
Historical week selections are preserved by the implementation;
this specific rollover behaviour still needs a dedicated test.

Browser background timers may be delayed. Real-device background
and overnight behaviour remain browser-refinement checks.

## Latest verification

- flutter analyze: No issues found.
- flutter test: All 23 tests passed.
- Test suite: 11 spending, 7 expiry, 4 day-refresh and 1 navigation.

The planned Week 6 features are implemented and the checks above
have passed. Remaining verification includes simultaneous inventory
requests and dedicated Budget week-rollover checks.

## Final Week 6 checks on 17 October 2026

### Concurrent inventory requests

Started two use requests together for one remaining unit,
using different action IDs.

The first attempt exposed a web error-handling issue: a StateError
raised inside the transaction callback appeared as NativeError.
The service now returns an acceptance result from the transaction
and raises the readable application error outside the callback.

Retest passed:
- One request succeeded and one was rejected.
- Firestore showed currentQuantity: 0 and status: used.
- Temporary concurrency test code was removed from the screen.

This was a manual concurrent-request check, not an automated
database stress test.

### Budget week rollover

Budget now uses SpendingUtils.weekAfterDayChange.

Five automated tests passed:
- Current-week selection advances on Monday.
- An older selected week stays selected.
- A day change within the same week preserves its Monday.
- Current-week selection follows after several weeks away.
- Rollover works across a year boundary.

These test the selection rule. Existing day-refresh tests cover
the timer and resume checks. Real-browser overnight and background
behaviour remain part of later browser verification.

### Final verification

- flutter analyze: No issues found.
- flutter test: All 28 tests passed.
- Coverage: 11 spending, 7 expiry, 5 Budget rollover,
  4 day-refresh and 1 navigation test.

The two previously outstanding Week 6 checks are now completed
within the scope described above.

## OCR assisted expiry entry and camera integration

Implemented during the Week 6 lab on 28 October 2026.

### Implementation

- Added browser text recognition using Tesseract.js.
- Added photo selection and optional camera capture.
- Camera access is requested after the user taps Enable camera.
- Microphone access is disabled.
- Added date suggestions with user confirmation before form entry.
- Manual date entry remains available.
- Recognition does not automatically save groceries.

### Date interpretation

- Supports UK numeric dates, ISO dates and named months.
- Supports both OCT 12 and 12 OCT.
- Missing years use the current year and are labelled as assumed.
- Printed years take priority.
- Two digit years are interpreted as 2000–2099.
- Impossible dates are rejected.
- Fixed overlapping matches found by an automated test.
- Detected dates are not automatically classified as expiry dates;
  users must compare them with the label.

### Checks completed

- A clear uploaded image of 11/12/2024 produced that date.
- A generated test label of 15/12/2026 produced that date.
- Confirming the future date populated the grocery form.
- Saved a test grocery and verified its quantity and expiry in My Pantry.
- Returning without selecting a date preserved manual entry.
- Laptop camera permission, preview, capture and image return worked.
- flutter analyze: no issues found.
- flutter test: all 44 tests passed.

### Limitations and pending checks

- Camera-photo recognition and rear-camera selection need phone testing.
- Synthetic and clear-image tests do not establish real-label accuracy.
- Blurry, faint, curved or stylised printing may be misread.
- OCR library and language files require external downloads.
- Recognition runs in the browser; this implementation does not
  upload the photo to Firebase or an OCR server.
- Recognition failure handling still needs an explicit check.
- Use by and Best before remain distinct label meanings; the current
  parser suggests dates without storing the label type.
- Blocking camera permission showed a clear error.
- Returning to photo selection still worked.
- A blank test image produced no date suggestions.
- The screen explained the manual-entry fallback.
- Returning to the grocery form allowed manual date selection.
- Blocking the Tesseract library download displayed an error.
- Unblocking it and retrying without refreshing recognised the date.
### OCR crop checks
- Cropped a label photo and recognised the correct printed date.
- Confirming the suggestion filled the Add grocery expiry field.
- Cancelling cropping preserved the existing form details.
- flutter analyze: no issues found.
- flutter test: all 44 tests passed.
- Phone testing of the crop feature remains pending.