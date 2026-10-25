# حواليك (Hawaleek)

Arabic RTL Flutter application for patients, family members, and doctors.

## Firebase setup

This workspace has no Firebase project identifiers or platform configuration. No credentials are included. Install Node.js and the Firebase CLI if needed, install FlutterFire CLI, then authenticate and configure the existing project:

```sh
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Choose the Firebase project and Android/iOS app identifiers when prompted. FlutterFire generates `lib/firebase_options.dart`; the checked-in bootstrap file contains no credentials and is replaced by that generated configuration. In Firebase Console, enable **Authentication → Email/Password** and create a **Cloud Firestore** database. Then select the same Firebase project for the CLI and deploy the restrictive rules:

```sh
firebase use --add
firebase deploy --only firestore:rules
```

The application intentionally remains in a setup-required state until a working Firebase configuration exists. Doctor approval requires a trusted administrator process: set the `admin: true` custom claim only from a trusted Firebase Admin SDK environment, then update a doctor's verification status. Never place Admin SDK credentials in this Flutter application. Family members can request a link using the patient's Firebase Auth UID; the patient must approve it.

## Run and validate

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

Firestore rules are in `firestore.rules`; patient records are readable only by the patient and family members with an approved relationship. Doctor reads of patient records remain denied until a separately scoped authorization model is implemented.
