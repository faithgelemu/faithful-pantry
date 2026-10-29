# Push notification experiment

## Verified checks
- Desktop Chrome registration succeeded.
- A Firebase test notification arrived while the app was backgrounded.
- Installed iPhone PWA registration succeeded.
- A Firebase test notification arrived while the app was backgrounded.
- After disabling on iPhone, another test to the old token did not arrive.
- Windows Do not disturb initially suppressed notification banners.
- Before deployment, flutter analyze reported no issues and all
  56 existing tests passed. Those tests do not verify push delivery.

## Current limits
- Tokens are installation-specific and are not stored in Firestore.
- Registrations are not yet linked to user accounts.
- Only manually triggered, generic test messages have been tested.
- Automatic expiry scheduling and foreground handling remain pending.
- Permission-denial handling still needs manual verification.