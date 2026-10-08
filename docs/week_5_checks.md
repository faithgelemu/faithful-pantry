# Week 5: Core Pantry Development Checks

Date: 8 October 2026
Platform tested: Flutter Web in Chrome on Windows
Implementation checkpoint: 323945b

## Implemented workflow

A signed-in user can add, view, edit, remove and search pantry
items, and filter them by category.

Manual entry includes name, category, purchase date, expiry date,
purchased quantity and unit price.

PantryItem and PurchaseRecord define the data models.
PantryService handles database reads and writes.

## Data structure

- users/{uid}/pantry/{itemId}
  - name, category
  - purchasedQuantity, currentQuantity
  - unitPricePence, purchaseDate, expiryDate, status
  - createdAt; updatedAt when changed; resolvedAt when fully resolved
- users/{uid}/purchases/{itemId}
  - pantryItemId, name, category
  - purchasedQuantity, unitPricePence, totalPricePence, purchaseDate
  - createdAt; updatedAt when corrected
- users/{uid}/inventoryActions/{actionId}
  - pantryItemId, action, quantity, createdAt

Prices use integer pence.
Purchase total = purchasedQuantity × unitPricePence.
Calendar dates use YYYY-MM-DD.

Older records using quantity remain readable through model fallbacks.
Older records without a category display as Other.

## Manual acceptance checks

| Check | Result |
|---|---|
| Save a valid grocery and find it in the pantry | Passed |
| Reload and confirm saved data remains | Passed |
| Edit a price and confirm the purchase total updates | Passed |
| Reload after editing and confirm persistence | Passed |
| Search by item name | Passed |
| Search with no matches and clear the search | Passed |
| Filter items by category | Passed |
| Combine search and category filters | Passed |
| Reject a blank name | Passed |
| Reject quantity 0 | Passed |
| Reject a negative unit price | Passed |
| Cancel removal without changing inventory | Passed after model/service refactor |
| Remove an item while retaining its purchase record | Passed after model/service refactor |
| Switch accounts and see separate pantries and purchase lists | Passed after model/service refactor |


## Inventory and financial history checks

Using a test purchase of 3 items at £1.00 each:

- Marked 1 used: remaining quantity became 2.
- Marked 1 wasted: remaining quantity became 1.
- Purchased quantity remained 3.
- Purchase total remained £3.00.
- Attempting to use 2 when only 1 remained was rejected.
- Corrected unit price to £1.20.
- Remaining quantity stayed 1; purchase total became £3.60.
- Reloaded and confirmed the corrected values persisted.
- Budget displayed purchased quantity 3 and total £3.60.

## Access-rule simulations

Firestore Rules Playground used:
users/test-user/pantry/test-item

| Simulated request | Result |
|---|---|
| Unauthenticated get | Denied |
| get with UID different-user | Denied |
| get with UID test-user | Allowed |
| delete with UID different-user | Denied |
| update with UID different-user | Denied |
| create with UID different-user | Denied |

These are permission simulations, not database mutations.
The rules require authentication and a UID matching the user path.
They enforce ownership; field-level validation is currently in
the application and data service.

## Code checks

- flutter analyze: No issues found.
- flutter test: 1 navigation test passed.

The automated test covers tab selection.
Database workflows above were checked manually.
Automated calculation and transaction tests remain to be added.

## Week 6 work still outstanding

- Expiring Soon section with a documented three-day threshold.
- Expiry checks for today, tomorrow, three days ahead and expired items.
- Repeated-action and concurrency verification.
- Daily spending breakdown.
- Weekly budget saved in settings and remaining-budget display.
- Consistent spending summaries on Home and Budget.
- Automated calculation tests.