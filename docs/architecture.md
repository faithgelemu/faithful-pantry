# Architecture

## Data storage

User data is stored in Firestore under the authenticated user's UID:

```text
users/{uid}/pantry/{itemId}
users/{uid}/purchases/{purchaseId}
users/{uid}/inventoryActions/{actionId}
users/{uid}/settings/preferences
```

Pantry records hold current inventory, while purchase records preserve spending history.

- Adding a grocery saves its pantry and purchase records together.
- Using, wasting or removing inventory does not remove the original purchase from spending history.
- Money is stored as integer pence.
- Purchase totals are calculated as: purchased quantity × unit price in pence.
- Weekly spending runs from Monday to Sunday using the user's local calendar.
- Comparisons with previous weeks use the current saved weekly budget, not a historical one.

## Firebase security

Firestore rules require authentication and a matching UID in the document path.

These ownership checks were verified in the Firebase Rules Playground:

- Signed-out pantry reads were denied.
- Another user's pantry reads and creates were denied.
- The owner's pantry reads and creates were allowed.
- Another user's purchase-history and settings reads were denied.

These checks cover the documented ownership scenarios only. The current rules do not validate individual fields, so application-side validation should not be treated as a replacement for server-side validation.
