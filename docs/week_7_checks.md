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