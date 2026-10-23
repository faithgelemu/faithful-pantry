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