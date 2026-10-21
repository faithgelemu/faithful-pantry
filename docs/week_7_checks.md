# Week 7 UI and Navigation Checks

Date: 17 October 2026
Status: In progress
Platform checked: desktop Chrome on Windows

## Changes implemented

- Replaced the Profile placeholder with the signed-in email
  and access to the existing weekly-budget setting.
- Reused SettingsService and WeeklyBudgetScreen.
- Renamed the Scan tab to Add and its page title to Add groceries.
- Updated the pantry instruction and navigation test.

Barcode scanning remains optional. The Add label describes the
working manual-entry feature without implying a scanner exists.

## Manual checks passed

- Profile displayed the signed-in account email and budget setting.
- Saved a £35.00 weekly limit through Profile.
- Home, Budget and Profile displayed the same limit.
- Changing the limit did not change recorded spending.
- Tabs displayed Home, Add, Budget and Profile.
- Add opened the grocery-entry form.

## Code checks

- flutter analyze: No issues found.
- flutter test: All 28 tests passed.

The automated suite does not yet test the new Profile workflow;
the Profile checks above were performed manually.

## Remaining Week 7 work

- Review the full core user journey.
- Check narrow layouts, enlarged text and keyboard focus.
- Check browser back navigation and form cancellation.
- Review loading, error and retry interactions.
- Reconcile the current Home layout with the proposed app map.
- Gather and record informal peer feedback where available.

## Usability checks on 17 October 2026

Manual checks in Chrome on Windows:

- At an emulated 390 × 844 viewport, Home, Add, Budget and
  Profile showed no observed overlapping controls or horizontal
  scrolling. Vertical scrolling remained available.
- Keyboard navigation reached the grocery form controls in a
  sensible order, with visible focus. A grocery was saved using
  the keyboard.
- Leaving Edit using the app back arrow discarded an unsaved
  name change; the original name remained.
- Chrome's Back button returned from Edit to the pantry.
- At 200% browser zoom, the four tabs remained readable and
  usable, with no observed overlap.

These are developer checks, not a formal accessibility audit.
Device emulation does not replace real-phone testing.
Browser zoom does not replace testing OS text-size settings.

## Combined user journey

Added Journey test: Dairy and eggs, quantity 2, unit price £0.50,
purchase date today and expiry tomorrow.

- Item appeared under Expiring Soon.
- Using 1 left 1 remaining.
- Budget retained 2 purchased for £1.00.
- Today's daily spending included the purchase.
- Home and Budget weekly totals matched.

Result: passed in desktop Chrome on Windows.

## Redesigned navigation checks on 21 October 2026

Manual checks in desktop Chrome on Windows passed:

- Chrome Back returned from My Pantry to the Home dashboard.
- Switching from Expiry Alerts to Budget, then Home, showed
  the dashboard rather than reopening the detail view.
- Editing through a grocery's three-dot menu returned to
  My Pantry with the updated name and Home selected.
- Partial use through Expiry Alerts reduced remaining quantity
  while preserving the original purchase quantity and total.
- Cancelling removal kept the item.
- Confirming removal deleted inventory but preserved its purchase.
- Home, My Pantry and Expiry Alerts remained usable at an
  emulated 390 × 844 viewport.
- Keyboard navigation reached dashboard links, search,
  category selection, the item menu and the app back control.
- The redesigned screens remained usable at 200% browser zoom.

These are developer checks, not a formal accessibility audit
or a substitute for real-device testing.

## Lecturer feedback on text recognition

Investigate camera-based text recognition for prefilling food
names and expiry dates.

Evaluate Flutter Web compatibility, camera/image input, recognition
quality, privacy, cost and implementation effort before adoption.

Any recognised name or date must be reviewed and confirmed by
the user before saving. Manual entry remains available.

This is an investigation, not a committed MVP feature.