# Bolt Workforce Ledger - how to put this into your project

## 1. Copy
Copy the `lib` folder from this zip over your project's `lib` folder (Replace all).
Copy `firestore.rules` to your project root. **Do not replace your `pubspec.yaml`.**

Delete these OLD files if they still exist (they were replaced):
- lib/controllers/employee_controller.dart
- lib/repositories/employee_repository.dart
- lib/models/employee_model.dart

## 2. Packages (run in the project folder, once)
```
flutter create . --platforms=android
dart pub global activate flutterfire_cli
flutterfire configure
flutter pub add firebase_core cloud_firestore firebase_auth
flutter pub get
```

## 3. Firebase console
1. Authentication -> Sign-in method -> enable Email/Password.
2. Firestore Database -> Create database -> **test mode** (temporary).

## 4. First run (debug build, Android emulator/phone)
1. Login screen -> "First-time setup: create demo data in Firebase"
   (creates 10 demo users, roles/permissions, regions, departments, CRs).
2. Login `superadmin@test.com` / `123456`.
3. Settings -> "Load sample workforce data (60 employees)" (optional, for testing).
4. Firebase console -> Firestore -> Rules -> paste `firestore.rules` -> Publish.

## 5. Role permissions
Roles screen: open each role and tick the new permissions (Firestore keeps the
role list that was seeded). Re-running the first-time setup resets roles to the defaults in
`lib/core/constants/app_roles.dart`.

## Demo accounts (password 123456)
superadmin@ / admin@ / manager@ / employee@ / guest@ / hradmin@ / payroll@ /
regional@ / deptmanager@ / auditor@  (all @test.com)

## Needs Firestore indexes?
No - all queries use equality filters only.
