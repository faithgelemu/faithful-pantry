# Push Notification Checks

## Device registration and delivery

The following checks were completed:

- Desktop Chrome registered successfully for push notifications.
- Installed iPhone PWA registered successfully.
- Firebase test notifications arrived on both devices while the app was in the background.
- Disabling notifications on the iPhone prevented further delivery to its old token.
- Windows Do Not Disturb initially suppressed notification banners.

Push registrations are installation-specific and stored under the signed-in user's Firestore account.

## Account-linking checks

The following account-linking checks passed:

- Enabling notifications created a registration under `users/{uid}/pushTokens/{tokenHash}`.
- The registration contained the token, enabled status, platform and update timestamp.
- Logging out removed the registration for that installation.
- Logging back in without enabling notifications did not recreate the registration.
- Explicitly enabling notifications created a new registration.
- Notifications were delivered to the current registration while the app was in the background.

### Account switching

- Logging out of Account A removed its tested registration.
- Logging into Account B without enabling notifications did not create a registration.
- Enabling notifications for Account B created a registration under B's account only.
- Logging out of Account B removed its registration.

Unexpected account changes across multiple tabs have not been fully tested.

### iPhone account-linking

- Enabling notifications linked the iPhone installation to Account A.
- Its registration appeared under Account A's pushTokens collection.
- Logging out removed the registration.
- Other device registrations remained unchanged.

## Registration synchronisation

The following checks passed:

- Starting the app refreshed the existing registration timestamp.
- Returning to the app refreshed the timestamp.
- Logging out and back in without enabling notifications did not recreate the registration.

An actual Firebase Cloud Messaging token rotation has not yet been verified.

## Server-triggered expiry reminders

The reminder system uses a Node.js script in `tools/reminders` and GitHub Actions.

Verified checks:

- GitHub Actions authenticated with Google Cloud using Workload Identity Federation.
- A dry-run checked reminder eligibility against pantry records.
- Manual server-triggered reminders arrived on the laptop and iPhone.
- A repeated send run skipped registrations that already had a daily reservation.
- The delivery protection tests cover duplicate prevention and registration checks.
- The datastore permission required for the existing-reservation transaction was added after an earlier permission-denied failure.

The notification message is generic and asks users to open Faithful Pantry to review approaching expiry dates.

## Configurable reminder periods

Users can select an expiry reminder period between 1 and 7 days in Profile under Manage reminders.

- The default reminder period is 3 days.
- The selected period is stored in the user's Firestore settings.
- The reminder script reads the saved preference for each user.
- Missing or invalid preferences use the 3-day default.
- The expiry window includes today and dates up to the selected number of days.

The reminder period is applied by the server-side reminder script. It does not change the recorded expiry date of a grocery.

## GitHub Actions schedule

The workflow is stored in:

`.github/workflows/expiry-reminders.yml`

Its current configuration is:

- Runs daily at 09:17 UTC.
- This corresponds to 09:17 during UK winter time and 10:17 during UK summer time.
- Scheduled runs execute the reminder script with sending enabled.
- Manually triggered runs are dry-runs by default.
- A manual run must explicitly set `send_reminder` to `true` to send notifications.
- A maximum of 10 send attempts is allowed per run.
- Reminder tests run before the reminder job.

The daily schedule is configured, but the first successful delivery from an automatic scheduled run has not yet been verified.

## Delivery protection and limitations

The system uses daily delivery reservations to reduce duplicate notifications.

Reservations favour avoiding duplicate messages. An uncertain delivery attempt can therefore result in a missed reminder for that day.

Other checks still outstanding:

- Permission-denial handling.
- Actual FCM token rotation.
- Unexpected account changes across multiple tabs.
- Foreground notification behaviour.
- Successful delivery from an automatic scheduled run.

## Latest code verification

The latest recorded checks included:

- `flutter analyze`: no issues found.
- `flutter test`: all 56 tests passed.
- Node.js reminder and delivery-protection tests: all 18 tests passed.
- Flutter web release build completed successfully.
- Firebase Hosting deployment completed successfully.