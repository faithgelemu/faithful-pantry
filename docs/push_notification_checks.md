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

## Account-linking checks
- Enabling created users/{uid}/pushTokens/{tokenHash}.
- Record contained token, enabled, platform and updatedAt.
- Logout returned to Login and removed the registration document.
- A test to the old token after logout produced no notification.
- Logging back in without enabling left the document absent.
- Explicitly enabling again recreated the registration.
- A test to the current token arrived while the app was backgrounded.
- Analysis reported no issues; all 56 existing tests passed.
- These checks were performed on the tested browser installation.
- Cross-account switching, token refresh and the updated iPhone
  account-linking flow remain unverified.

  ## Same-browser account switching
- Logged out of Account A; its tested registration was removed.
- Logged into Account B without enabling; no registration appeared.
- Explicitly enabled for B; registration appeared only under B.
- Logged out of B; its registration was removed and Login appeared.
- Unexpected account changes across tabs remain untested.