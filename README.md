# BudgetBites Firebase edition

An iOS grocery-budgeting coursework app by Joshua Daramola using SwiftUI, Firebase Firestore and local AppStorage.

## Implemented in this source

- Budget input and local persistence of the budget value with AppStorage.
- Grocery-item entry and spending/remaining-budget calculations.
- Saving and fetching grocery items using Cloud Firestore.
- Tab navigation, a progress indicator, insights and a meal-ideas sheet.
- A reset action that requests deletion of the shared grocery collection.

This edition is separate from the Core Data/barcode-scanning edition. Features from the two versions should not be combined in a project description.

## Setup

1. Open `BudgetBites.xcodeproj` in Xcode. The saved deployment target is iOS 26.2.
2. Select your own signing team and bundle identifier where needed. The original signing-team selection was cleared in this prepared copy.
3. Create a separate Firebase development project and register the app using the same bundle identifier selected in Xcode.
4. Follow the official [Firebase Apple setup guide](https://firebase.google.com/docs/ios/setup), adding your own `GoogleService-Info.plist` to the app target.
5. Configure a development Firestore database and access rules appropriate to your test environment. The app uses a `groceryItems` collection. The original project's rules were not provided.
6. Let Xcode resolve the included Swift package dependencies, then build and run.

The original Firebase project configuration is deliberately absent and ignored by Git. Without a replacement configuration, Firebase setup will not complete.

## Known limitations

- Grocery-item swipe deletion currently removes local state only. It does not delete the Firestore document, so items can reappear after a reload.
- The collection is shared and the source has no user-based data separation. Reset requests deletion of every document returned from that collection. Use only an isolated test database.
- A Firestore write failure is printed, but the locally appended item is not rolled back or accompanied by a visible failure message.
- Validation accepts any parsable price, including negative values; it should be tightened.
- Saving/fetching uses callbacks; this is not a real-time Firestore listener.

These are review findings, not changes to the submitted application logic. No production security or multi-user isolation claim is made.

## Validation

The Swift files passed a syntax-only parse during preparation. Full Xcode builds, Firebase access and device behaviour were not exercised. The archive includes university testing reports; those are historical evidence, not a fresh test run of this copy.
