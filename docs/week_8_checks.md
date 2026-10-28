# Week 8: Browser and PWA checks

## Build and fonts

- Bundled Nunito Sans font files and licence.
- Confirmed the font displays without asset-loading errors.
- flutter analyze: no issues found.
- flutter test: all 32 existing tests passed.
- flutter build web: succeeded.

## Local release checks

Served build/web at http://localhost:8080.

Manual checks passed:
- App opens with the correct font and browser icon.
- Login and navigation work.
- Saved groceries and budget appear.
- Refresh reloads the app and preserves the login session.

## Local installation

- Installed through Chrome's "Install page as app" option.
- App opens in its own window with the pantry icon.
- App reopens from the Windows Start menu.

This checks Chrome app installation on Windows using localhost.
It does not confirm offline operation or installation on phones.
The local server must remain running for these checks.

## Remaining checks

- Hosted HTTPS deployment and installation.
- Another browser and a real mobile device.
- Connection-loss and recovery behaviour in the release build.
- App update behaviour.
- Keyboard, zoom and reduced-motion checks after the redesign.

## Development interruption

Chrome and VS Code became unresponsive during the earlier session.
The cause was not established. After reopening VS Code, analysis,
tests and the release build completed successfully.

- Microsoft Edge: login, saved groceries and Budget work.
- At 200% zoom in Edge, Home, Add, Budget and Profile remain
  usable, with no overlapping text or inaccessible controls.

  - Keyboard check passed: navigation tabs and Add's Save grocery
  button are reachable and operable, with visible focus.
  ### Hosted service-worker checks
- Added a custom service worker and generated release asset list.
- Chrome DevTools showed sw.js registered and activated.
- App interface loaded after refreshing with DevTools Offline enabled.
- Saved groceries and budget returned after reconnecting.
- Offline cloud-data access, editing and OCR are not guaranteed.
- Each deployment requires a web build followed by
  tools/prepare_offline.ps1 before deploying.

  ### Installed iPhone offline recovery
- Installed app interface loaded and tabs worked in Airplane Mode
  with Wi-Fi disabled.
- Saved groceries and budget returned immediately after reconnecting.
- This verifies interface availability and recovery, not offline editing.

### Hosted iPhone inventory and spending journey
- Added Demo milk: 4 items at £1.25 each.
- Pantry showed 4 remaining; weekly spending increased by £5.00.
- Used 2: remaining quantity became 2; spending stayed unchanged.
- Wasted the remaining 2: item left the active pantry and
  Expiring Soon; its £5.00 purchase remained in Budget.

  - Added Demo bread: 2 items at £1.00; spending increased by £2.00.
- Edited unit price to £1.50: quantity stayed 2, purchase total
  became £3.00, and weekly spending increased by £1.00.
- Removed Demo bread: it left the pantry; its £3.00 purchase
  remained in Budget and spending stayed unchanged.

  ### Firestore ownership-rule simulations
Tested in Firebase Rules Playground without changing deployed rules.

- Signed-out pantry read: denied.
- Different user's pantry read: denied.
- Owner's pantry read: allowed.
- Different user's pantry create: denied.
- Owner's pantry create: allowed.
- Different user's purchase-history read: denied.
- Different user's settings read: denied.

These verify the listed ownership scenarios, not field validation
or every possible database operation.

### Release update check
- New worker waited while the previous release remained open.
- After closing all app windows and reopening, it activated normally.
- The page returned app-release marker update-check-1.