# Building and deploying

The commands below are for Windows PowerShell. On macOS or Linux, use `firebase` instead of `firebase.cmd` and run the preparation script with PowerShell Core (`pwsh`) or an equivalent.

## 1. Build the web release

```powershell
flutter build web --no-web-resources-cdn
```

## 2. Prepare the offline asset list

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\prepare_offline.ps1
```

This generates `build/web/sw-assets.js`, which contains the application asset list and cache version. It must be generated after every release build and before deployment. Do not edit generated files in `build/web` manually.

## 3. Deploy to Firebase Hosting

```powershell
firebase.cmd deploy --only hosting --project faithful-pantry
```

Deployment requires the Firebase CLI, an authenticated account and permission to deploy to the project.

## Using a different hosting domain

Service-worker registration is restricted to the project's `web.app` and `firebaseapp.com` domains. To host elsewhere, update `web/index.html`.
