# Faithful Pantry

A grocery and pantry management app that helps you track groceries, expiry dates and weekly spending.

Built for CS52001 Mobile Application Development at the University of Dundee.

**Live app:** https://faithful-pantry.web.app

Faithful Pantry is built with Flutter Web and can be installed as a web app on supported browsers. An account and an internet connection are needed for normal cloud operations.

## Features

- Register, log in, log out and reset your password by email
- Add, edit, remove, search and filter pantry items
- Track purchased and remaining quantities separately
- See groceries that are expiring soon or have expired
- Record quantities used or wasted, with purchase history kept
- View weekly spending, daily breakdowns and a saved weekly budget
- Set a preferred name for the Home screen greeting
- Scan expiry dates from label photos using in-browser OCR (crop, review, then confirm)
- Install the app and launch its interface offline

## Technologies

- Flutter and Dart
- Firebase Authentication, Cloud Firestore and Firebase Hosting
- Tesseract.js for browser-based OCR
- `image_picker`, `camera` and `crop_your_image`
- A custom JavaScript service worker for offline interface caching
- Nunito Sans fonts

Dependency versions are recorded in `pubspec.yaml` and `pubspec.lock`.

## Running locally

Install Flutter (with web support) and Git, then:

```bash
git clone https://github.com/faithgelemu/faithful-pantry.git
cd faithful-pantry
flutter pub get
flutter run -d chrome
```

Repository access is required if the repository is private.

The project is configured to use the Faithful Pantry Firebase project. Running the app does not give you Firebase administration access, and Firestore rules control access to user records. To use your own Firebase project, configure a web app with FlutterFire, enable email/password authentication, create a Firestore database and add suitable security rules.

## Testing

```bash
flutter analyze
flutter test
```

Latest recorded full validation:

- No issues reported by Flutter analysis
- All 56 Flutter tests passing, including 24 OCR date-parser tests
- 18 reminder-related Node.js tests passing

The tests cover spending calculations, expiry logic, calendar rollover, navigation and supported OCR date formats. They do not establish OCR accuracy across every package, device or lighting condition.

Manual checks were recorded on desktop Chrome, desktop Edge (including zoom and keyboard checks) and iPhone Safari (Home Screen installation, camera capture, cropping and selected real-label OCR tests). Android Chrome and other combinations have not been tested. Full records are in `docs/week_5_checks.md` to `docs/week_8_checks.md` and `docs/ocr_experiment.md`.

## Known limitations

- OCR assists with entry but does not guarantee correct recognition. Glare, blur, low contrast and nearby batch or time codes can affect results, and cropping to the date and its label helps.
- Unlabelled compact dates such as `141126` are unsupported, as are some packaging layouts and date formats.
- Ambiguous numeric dates use UK day/month/year order.
- Missing years use the current year, and month/year dates assume the last day of the month. Both show a notice and need review.
- Use-by and best-before dates are stored as a single date, with no separate field for the label type.
- Offline support covers launching the interface only. Authentication, cloud data, editing and OCR need a connection.
- Expiry reminders do not determine whether food is safe to eat.
- Barcode lookup, donation maps and profile-photo uploads are not implemented.

## Further documentation

| Topic | File |
| --- | --- |
| Building and deploying | [`docs/deployment.md`](docs/deployment.md) |
| Data model, spending logic and Firebase security | [`docs/architecture.md`](docs/architecture.md) |
| Expiry-date OCR and supported formats | [`docs/ocr.md`](docs/ocr.md) |
| Offline support and service worker updates | [`docs/offline.md`](docs/offline.md) |

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

ChatGPT was used during development for guidance, code generation and revision, troubleshooting, test design and documentation. Testing and verification were carried out as part of the project, with results and known limitations recorded in the documentation.

## Fonts

Nunito Sans font files and their licence are included in `assets/fonts`.