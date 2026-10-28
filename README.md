# Faithful Pantry

Faithful Pantry helps users track groceries, expiry dates and weekly spending.

Developed by Faith Gelemu for CS52001 Mobile Application Development,
University of Dundee.

## Live application

https://faithful-pantry.web.app

The application uses Flutter Web and can be installed through supported
browsers. An account and internet connection are required for reliable
cloud-data operations.

## Features

- Email/password registration, login and logout.
- Password-reset emails from Login and Profile.
- Add, edit, remove, search and filter pantry items.
- Track purchased quantity separately from remaining quantity.
- Expiring Soon and expired-item views.
- Record partial quantities as used or wasted.
- Preserve purchase history when groceries are used, wasted or removed.
- Weekly spending, daily breakdown and a saved weekly budget.
- Optional preferred name and personalised Home greeting.
- Optional photo or camera OCR for expiry-date entry.
- Crop label photos and review date suggestions before applying them.
- Installable web app with cached interface files for offline launch.

## Technology

- Flutter and Dart.
- Firebase Authentication.
- Cloud Firestore.
- Firebase Hosting.
- Tesseract.js for browser-based OCR.
- image_picker, camera and crop_your_image.
- Bundled Nunito Sans fonts.
- Custom JavaScript service worker for interface caching.

Dependency versions are recorded in pubspec.yaml and pubspec.lock.

## Run locally

Install Flutter with web support and Git, then run:

```powershell
git clone https://github.com/faithgelemu/faithful-pantry.git
cd faithful-pantry
flutter pub get
flutter run -d chrome
```

Repository access is required if the repository is private.

The included Firebase configuration points to the project's Firebase
services. Running the frontend does not grant Firebase administration
access. Access to private records is controlled by Authentication and
Firestore rules.

To use a separate Firebase project, configure its web application using
FlutterFire, enable email/password authentication, create Firestore,
and deploy appropriate access rules.

## Validation

```powershell
flutter analyze
flutter test
```

At the latest recorded full validation:
- Analysis reported no issues.
- All 56 tests passed, including 24 OCR date-parser tests.

Tests cover spending calculations, expiry logic, day/week rollover,
navigation and supported OCR parsing rules. They do not establish OCR
accuracy across all packaging, devices or lighting conditions.

Manual check records are in:

- docs/week_5_checks.md
- docs/week_6_checks.md
- docs/week_7_checks.md
- docs/week_8_checks.md
- docs/ocr_experiment.md

## Release build and deployment

Build with local Flutter renderer resources:

```powershell
flutter build web --no-web-resources-cdn
```

Generate the offline asset list after every release build:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\prepare_offline.ps1
```

The execution-policy option applies to that PowerShell process.
The helper creates build/web/sw-assets.js with file paths and a
content-based cache version.

After both commands succeed, deploy:

```powershell
firebase.cmd deploy --only hosting --project faithful-pantry
```

Deployment requires the Firebase CLI, authentication and permission
to deploy to the Firebase project.

Do not deploy a fresh build before generating its offline asset list.
Do not edit generated files inside build/web manually.

Service-worker registration is currently restricted to the project's
web.app and firebaseapp.com hostnames. A different hosting domain
requires updating web/index.html.

## Data model

Records are stored under the authenticated user's UID:

```text
users/{uid}/pantry/{itemId}
users/{uid}/purchases/{purchaseId}
users/{uid}/inventoryActions/{actionId}
users/{uid}/settings/preferences
```

Pantry records hold current inventory. Purchase records preserve the
financial history.

Adding a grocery saves its pantry and purchase records together.
Using, wasting or removing inventory does not remove the original
purchase from spending history.

Money is stored as integer pence. A purchase total is:

purchased quantity × unit price in pence

Weekly spending uses purchase dates from Monday to Sunday in the
user's local calendar. Comparisons for earlier weeks use the current
saved weekly budget, not a historical budget snapshot.

## Access control

Firestore rules require an authenticated UID matching the user ID
in the document path.

Rules Playground checks verified:
- Signed-out pantry reads were denied.
- Another user's pantry reads and creates were denied.
- Owner pantry reads and creates were allowed.
- Another user's purchase-history and settings reads were denied.

These checks cover the documented ownership scenarios. The current
ownership rules do not enforce field-level data validation.
Application/service validation is not a substitute for server-side rules.

## OCR behaviour

Photos can be selected or captured with camera permission, then cropped.
OCR runs in the browser. Photo bytes are not uploaded by this workflow
to Firestore or an OCR processing server.

OCR library, worker and language resources require external downloads.

Supported examples include:
- 14/11/2026, 14-11-26 and 14 11 26.
- 2027-03-27.
- 27 MAR 27 and 27 March 2027.
- OCT 12 and 12 OCT, with a current-year assumption notice.
- SEP 2028 and 05/2027, with an assumed month-end day notice.
- BB: 05 27, when associated with best-before wording.

The parser identifies nearby supported date labels and excludes
dates clearly associated with recognised production/packing labels.

Recognition and label association can be wrong. Users must compare
suggestions with the packaging before confirming. Confirming an OCR
date fills the grocery form; it does not automatically save a grocery.

Use-by and best-before wording have different meanings. The pantry
model currently stores the selected date rather than a separate
structured label type.

## Offline behaviour and updates

The custom service worker caches listed application interface files.
It does not cache Firebase records or external OCR resources.

Verified checks:
- Chrome showed sw.js registered and activated.
- The interface loaded after an offline refresh in Chrome.
- The installed iPhone app opened offline and its tabs worked.
- Saved groceries and budget returned after reconnecting.

This does not guarantee offline data access, editing, authentication
or OCR. Reliable cloud operations require a connection.

A new service worker waits for existing controlled app windows to
close before activation. Close all app tabs/windows and reopen online
when checking a new release. Release-to-release updating was verified in Chrome by checking
worker activation and the updated page's release marker.

## Browser and device coverage

Recorded checks include:
- Desktop Chrome.
- Desktop Edge, including zoom and keyboard checks.
- iPhone Safari and Home Screen installation.
- iPhone camera capture, cropping and selected real-label OCR checks.

Android Chrome and other unrecorded combinations are not claimed
as tested.

## Known limitations

- OCR is an entry aid, not guaranteed recognition.
- Glare, blur, low contrast and nearby batch/time codes can interfere.
- Cropping the date and relevant wording can improve results.
- Unlabelled compact strings such as 141126 remain unsupported.
- Ambiguous numeric full dates use UK day/month/year interpretation.
- Missing years use the current year and require review.
- Month/year suggestions assume the last calendar day and display a notice.
- Some label layouts and date formats are unsupported.
- Date reminders do not determine whether food is safe.
- Background push notifications, barcode lookup, donation maps
  and profile-photo uploads are not implemented.

## Project structure

- lib/models: pantry and purchase data objects.
- lib/services: Firebase operations, settings and OCR integration.
- lib/utils: expiry, spending, calendar and OCR parsing logic.
- lib/widgets: reusable interface components.
- test: automated tests.
- web: web branding, OCR bridge, bootstrap and service worker.
- tools: release preparation helper.
- docs: development and manual verification records.

## AI assistance acknowledgement

ChatGPT assisted with development guidance, code generation and
revision, troubleshooting, test design and documentation.

Verification results and known limitations are recorded in the
project documentation. AI-assisted work should also be acknowledged
in the assessed report as required by the module instructions.

## Fonts

Nunito Sans font files and their licence are included in assets/fonts.