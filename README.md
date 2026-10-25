# حواليك (Hawaleek)

Arabic RTL Flutter application for family members and doctors.

## Firebase setup

This workspace has no Firebase project identifiers or platform configuration. No credentials are included. Install Node.js and the Firebase CLI if needed, install FlutterFire CLI, then authenticate and configure the existing project:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Choose the Firebase project and Android/iOS app identifiers when prompted. FlutterFire generates `lib/firebase_options.dart`; the checked-in bootstrap file contains no credentials and is replaced by that generated configuration. In Firebase Console, enable **Authentication → Email/Password** and create a **Cloud Firestore** database. Then select the same Firebase project for the CLI and deploy the restrictive rules:

```powershell
firebase use --add
firebase deploy --only firestore:rules
```

The application intentionally remains in a setup-required state until a working Firebase configuration exists. Doctor approval requires a trusted administrator process: set the `admin: true` custom claim only from a trusted Firebase Admin SDK environment, then update a doctor's verification status. Never place Admin SDK credentials in this Flutter application.

Only family and doctor roles can register in this version. Existing patient profiles and approved family links are retained in Firestore for compatibility; this app does not expose patient-mode screens. New family-link requests still target existing patient UIDs and remain pending until approved by an authorized patient client or reviewed through trusted administrative tooling. No stored Firebase data is deleted.

Egyptian phone inputs show a fixed `+20` prefix and accept the remaining ten-digit mobile number. Local `01…`, international `+20…`, and `0020…` values are normalized to the same `+201…` Firestore form.

## Run and validate

```powershell
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

Firestore rules are in `firestore.rules`; existing patient records remain readable only by their owner and family members with an approved relationship. Doctor reads of patient records remain denied until a separately scoped authorization model is implemented.
