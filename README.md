# Faithful Pantry

Faithful Pantry is a grocery and pantry management app that helps users keep track of groceries, expiry dates and weekly spending.

I developed this project as part of CS52001 Mobile Application Development at the University of Dundee.

## Live application

https://faithful-pantry.web.app

Faithful Pantry is built with Flutter Web and can be installed as a web app on supported browsers. An account and internet connection are needed for normal cloud operations.

## Features

- Register, log in and log out using email and password.
- Reset passwords through email.
- Add, edit, remove, search and filter pantry items.
- Track purchased and remaining quantities separately.
- View groceries that are expiring soon or have expired.
- Record quantities used or wasted.
- Keep purchase history when groceries are used, wasted or removed.
- View weekly spending, daily spending breakdowns and a saved weekly budget.
- Set a preferred name for the Home screen greeting.
- Capture or select grocery label photos for expiry-date OCR.
- Crop photos and review suggested dates before using them.
- Install the app and launch its interface offline.

## Technologies used

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Hosting
- Tesseract.js for browser-based OCR
- image_picker, camera and crop_your_image
- Nunito Sans fonts
- A custom JavaScript service worker for offline interface caching

Dependency versions are recorded in `pubspec.yaml` and `pubspec.lock`.

## Running locally

Install Flutter with web support and Git.

```powershell
git clone https://github.com/faithgelemu/faithful-pantry.git
cd faithful-pantry
flutter pub get
flutter run -d chrome
```

Repository access is required if the repository is private.

The project is configured to use the Faithful Pantry Firebase project. Running the app does not provide Firebase administration access. Authentication and Firestore rules control access to user records.

To use another Firebase project, configure its web application using FlutterFire, enable email/password authentication, create Firestore and configure appropriate security rules.

## Testing

Run the following commands from the project directory:

```powershell
flutter analyze
flutter test
```

The latest recorded full validation completed with:

- No issues reported by Flutter analysis.
- All 56 Flutter tests passing.
- 24 OCR date-parser tests included in the test suite.
- 18 reminder-related Node.js tests passing.

The tests cover spending calculations, expiry logic, calendar rollover, navigation and supported OCR date formats.

Additional manual checks are documented in:

- `docs/week_5_checks.md`
- `docs/week_6_checks.md`
- `docs/week_7_checks.md`
- `docs/week_8_checks.md`
- `docs/ocr_experiment.md`

Automated tests do not establish OCR accuracy across every package, device or lighting condition.

## Building and deploying

Build the web release:

```powershell
flutter build web --no-web-resources-cdn
```

Prepare the offline asset list:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\prepare_offline.ps1
```

This generates `build/web/sw-assets.js`, which contains the application asset list and cache version.

Deploy to Firebase Hosting:

```powershell
firebase.cmd deploy --only hosting --project faithful-pantry
```

Deployment requires the Firebase CLI, an authenticated account and permission to deploy to the project.

The offline asset list must be generated after each release build and before deployment. Generated files in `build/web` should not be edited manually.

Service-worker registration is restricted to the project's `web.app` and `firebaseapp.com` domains. Using another hosting domain requires updating `web/index.html`.

## Data storage

User data is stored in Firestore under the authenticated user's UID:

```text
users/{uid}/pantry/{itemId}
users/{uid}/purchases/{purchaseId}
users/{uid}/inventoryActions/{actionId}
users/{uid}/settings/preferences
```

Pantry records contain current inventory, while purchase records preserve spending history.

Adding a grocery saves its pantry and purchase records together. Using, wasting or removing inventory does not remove the original purchase from spending history.

Money is stored as integer pence. Purchase totals are calculated using:

```text
Purchased quantity × unit price in pence
```

Weekly spending runs from Monday to Sunday using the user's local calendar. Comparisons with previous weeks use the current saved weekly budget rather than a historical budget.

## Firebase security

Firestore rules require authentication and a matching UID in the document path.

The following ownership checks were verified using the Firebase Rules Playground:

- Signed-out pantry reads were denied.
- Another user's pantry reads and creates were denied.
- The owner's pantry reads and creates were allowed.
- Another user's purchase-history and settings reads were denied.

These checks cover the documented ownership scenarios. The current rules do not validate individual fields, so application-side validation should not be treated as a replacement for server-side validation.

## Expiry-date OCR

Users can select or capture a grocery label photo, crop it and run OCR in the browser. The photo bytes are not uploaded to Firestore or an OCR processing server through this workflow.

The OCR library, worker and language resources require external downloads.

Supported examples include:

- `14/11/2026`, `14-11-26` and `14 11 26`
- `2027-03-27`
- `27 MAR 27` and `27 March 2027`
- `OCT 12` and `12 OCT`, with a current-year assumption notice
- `SEP 2028` and `05/2027`, with an assumed month-end date
- `BB: 05 27`, when associated with best-before wording

The parser looks for supported date formats near recognised expiry labels and excludes dates clearly associated with recognised production or packing labels.

OCR can misread dates or associate them with the wrong label. Users should check suggestions against the packaging before confirming. Confirming a suggestion fills the grocery form but does not automatically save the item.

Use-by and best-before dates have different meanings. The current pantry model stores the selected date without a separate structured field for the label type.

## Offline support

The service worker caches selected application files so the interface can launch offline. It does not cache Firebase records or external OCR resources.

The following offline checks were recorded:

- Chrome loaded the interface after an offline refresh.
- The service worker registered and activated in Chrome.
- The installed iPhone app opened offline and its tabs remained usable.
- Saved groceries and budget information appeared again after reconnecting.

Offline support does not guarantee that authentication, cloud data access, editing or OCR will work without a connection.

When a new service worker is installed, it waits for existing controlled app windows to close before activation. To check a new release, close the app tabs and windows, reopen the app online and allow the update to activate.

Release updates were checked in Chrome using worker activation and the updated page's release marker.

## Browser and device testing

Recorded manual checks include:

- Desktop Chrome
- Desktop Edge, including zoom and keyboard checks
- iPhone Safari and Home Screen installation
- iPhone camera capture, cropping and selected real-label OCR tests

Android Chrome and other unrecorded browser/device combinations have not been claimed as tested.

## Known limitations

- OCR assists with entry but does not guarantee correct recognition.
- Glare, blur, low contrast and nearby batch or time codes can affect results.
- Cropping the date and relevant wording can improve recognition.
- Unlabelled compact dates such as `141126` are unsupported.
- Ambiguous numeric dates use UK day/month/year interpretation.
- Missing years use the current year and require review.
- Month/year suggestions assume the last calendar day and display a notice.
- Some packaging layouts and date formats are unsupported.
- Expiry reminders do not determine whether food is safe to eat.
- Barcode lookup, donation maps and profile-photo uploads are not implemented.

## Project structure

```text
lib/
  models/       Pantry and purchase models
  services/     Firebase, settings and OCR services
  utils/        Expiry, spending and date-parsing logic
  widgets/      Reusable interface components

test/           Automated tests
web/            Web branding, OCR bridge and service worker
tools/          Release preparation scripts
docs/           Development and manual testing records
```

## AI assistance

ChatGPT was used during development for guidance, code generation and revision, troubleshooting, test design and documentation.

Testing and verification were carried out as part of the project, with results and known limitations recorded in the documentation.

## Fonts

Nunito Sans font files and their licence are included in `assets/fonts`.