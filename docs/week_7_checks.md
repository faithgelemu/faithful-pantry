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

## Automated navigation checks on 22 October 2026

HomeScreen accepts optional dashboard and detail builders so tests
can use simple content without connecting to Firebase.

Five navigation tests passed:
- All four tabs select their corresponding pages.
- My Pantry opens within Home; the back arrow returns.
- Expiry Alerts opens within Home; the back arrow returns.
- Switching tabs clears the Home detail selection.
- A navigation back request closes the detail view.

The tests exercise the real navigation logic with replacement
page content. They do not test Firebase or the full detail screens.

Latest checks:
- flutter analyze: No issues found.
- flutter test: All 32 tests passed.

## Manual entry timing on 23 October 2026

One familiarised developer attempt took approximately 33 seconds,
without rushing, from entering grocery details to save confirmation.

This is close to the approximate 30-second target. It is a single
informal observation, not a representative usability result.

## Refresh recovery check on 23 October 2026

An initial refresh coincided with the app and another Chrome
window becoming unresponsive. The cause was not established.

After recovering Chrome and restarting Flutter:
- The app launched normally.
- Refreshing from Add returned to Home.
- The signed-in session persisted.
- The Add form remained responsive.

The freeze was not reproduced in this repeat check.
No app-code fix was made for it.

## Connection recovery check on 23 October 2026

Using Chrome DevTools Network → Offline:
- Previously loaded groceries remained visible in My Pantry.
- No writes were attempted while offline.

After restoring No throttling:
- A test grocery name was edited and saved.
- The edited name persisted after refreshing.

Result: recovery passed for this sequence.
Offline saving and failed-write behaviour remain untested.

## Offline pending-save check on 23 October 2026

- Prepared one valid zero-price grocery while online.
- Switched Chrome DevTools Network to Offline.
- Clicked Save once; the form remained in Saving state.
- Restored No throttling without submitting again.
- Save confirmation appeared.
- My Pantry contained exactly one matching entry, quantity 1.

Result: the pending write completed after reconnection.
This did not test a rejected write or offline persistence after refresh.

Issue identified: a prolonged Saving state needs explanatory
feedback so users know not to submit the item again.

Peer feedback remains pending because the tester left.

## Slow-save feedback improvement

After 10 seconds, a pending grocery save displays an explanatory
message asking the user to check the connection, keep the form
open and avoid submitting again.

The timer does not cancel or retry the write. Save remains disabled.
The timer is cancelled on completion or when the screen is disposed.

Manual check passed:
- Simulated an offline save.
- Delayed message appeared while Save remained disabled.
- Restored the connection without submitting again.
- Save confirmation appeared; the message cleared and form reset.
- Exactly one matching grocery entry was present.

Latest checks:
- flutter analyze: No issues found.
- flutter test: All 32 tests passed.

The new timer/message behaviour was checked manually; the existing
automated suite does not directly test it.

## Server-rejected save check on 23 October 2026

Temporarily added a forbidden write to a specifically named test
grocery's batch. Published Firestore rules were not changed.

Observed results:
- Firestore rejected the save.
- The form displayed the permission error.
- Entered details remained present and Save became enabled again.
- No matching pantry entry was found after rejection.

Removed the temporary code. Hot reload returned to Home and reset
the form, so an uninterrupted retry of retained input was not tested.

Re-entered the details and submitted once:
- Save succeeded.
- Exactly one matching pantry entry appeared.

Final checks:
- flutter analyze: No issues found.
- flutter test: All 32 tests passed.
- PantryService diff: empty, confirming temporary code removal.

Peer feedback remains pending.

## Password reset

Implemented a shared password-reset screen accessible from:
- Login through “Forgot password?”
- Profile through “Reset password”.

Firebase Authentication sends the reset email. The user chooses
a new password through the emailed link.

Manual checks passed:
- Profile opens the reset screen with the account email filled in.
- The reset email arrives.
- Completing the emailed flow allows login with the new password.
- Login opens the reset screen without requiring a password.
- An entered email carries across from Login.
- Back returns to Login.
- “Forgot password?” is hidden on Create account.

Validation:
- flutter analyze: no issues found.
- flutter test: all 32 existing tests passed.

The reset journey was checked manually; the existing automated
tests do not directly test this new feature.