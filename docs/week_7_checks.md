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