# RBAC Employee Management App (Flutter + GetX)

Flutter Internship Task ka complete solution — Role-Based Access Control (RBAC) & Permissions System.

## Android Studio mein kholain

1. Yeh folder (`rbac_app`) apne PC pay unzip karein.
2. Android Studio open karein → **File > Open** → `rbac_app` folder select karein.
3. Terminal mein (Android Studio ke andar) yeh command chalayein:
   ```
   flutter pub get
   ```
4. Emulator ya device select karke **Run** (▶️) button dabayein.

## Demo Login Accounts (password sab ke liye: `123456`)

| Role        | Email                  |
|-------------|-------------------------|
| Super Admin | superadmin@test.com     |
| Admin       | admin@test.com          |
| Manager     | manager@test.com        |
| Employee    | employee@test.com       |
| Guest       | guest@test.com          |
| HR Admin           | hradmin@test.com     |
| Payroll / Accounts | payroll@test.com     |
| Regional Manager   | regional@test.com    |
| Department Manager | deptmanager@test.com |
| Viewer / Auditor   | auditor@test.com     |

Login screen par har role ke liye "Quick demo login" chip diya gaya hai — tap karein to email/password khud fill ho jayega.

## Task Requirements Coverage

| # | Requirement | Kahan implement kiya |
|---|---|---|
| 1 | Authentication (dummy users, local storage) | `screens/auth/login_screen.dart`, `controllers/auth_controller.dart`, `repositories/user_repository.dart` |
| 2 | State Management | **GetX** (`get: ^4.6.6`) — poore app mein |
| 3 | Permission Manager | `controllers/permission_controller.dart` — `hasPermission`, `hasRole`, `hasAnyPermission`, `hasAllPermissions` |
| 4 | Route Protection + 403 | `core/routes/route_middleware.dart`, `core/routes/app_pages.dart`, `screens/error/permission_denied_screen.dart` |
| 5 | Sidebar/Drawer (role-based menu) | `widgets/app_sidebar.dart` |
| 6 | UI Protection (buttons hide) | `widgets/permission_gate.dart` |
| 7 | Employee Module (CRUD + details) | `screens/employees/*`, `controllers/employee_controller.dart` |
| 8 | Profile Module | `screens/profile/profile_screen.dart` |
| 9 | Users Module (CRUD, Super Admin/Admin only) | `screens/users/users_screen.dart`, `controllers/user_controller.dart` |
| 10 | Roles Module (Super Admin only) | `screens/roles/roles_screen.dart`, `controllers/role_controller.dart` |
| 11 | Reports Module | `screens/reports/reports_screen.dart` |
| 12 | Local Storage (SharedPreferences) | `core/services/storage_service.dart` |
| 13 | Clean Folder Structure | `lib/core`, `lib/models`, `lib/repositories`, `lib/controllers`, `lib/screens`, `lib/widgets`, `lib/utils` |
| 14 | Bonus Features | Dark Mode, Search, Pagination, Responsive Layout, Role Badge, Permission Chips, Splash Screen, Remember Me, Logout Confirmation, Theme Switcher — sab implemented |

## Roles & Permissions Summary

- **Super Admin** → sab kuch (full access, permissions locked/uneditable)
- **Admin** → employees manage, reports view, users manage (Super Admin accounts manage nahi kar sakta)
- **Manager** → employee add/edit/view (delete nahi kar sakta)
- **Employee** → sirf apna profile view/update
- **Guest** → sirf dashboard (read-only)

- **HR Admin** → employees full CRUD, reports view, dashboard
- **Payroll / Accounts** → dashboard, employees view, reports view
- **Regional Manager** → dashboard, employees view, reports view
- **Department Manager** → dashboard, employees view (reports nahi)
- **Viewer / Auditor** → read-only: dashboard, employees, reports

Roles module (Super Admin only) se aap kisi bhi role ke permissions runtime par change/assign kar sakte hain — changes SharedPreferences mein save hoti hain.

## Notes

- Yeh sandbox environment mein Flutter SDK available nahi tha, is liye code `flutter pub get` / build khud aapko apne machine par chalana hoga. Code manually review kiya gaya hai (structure + syntax balanced) taake koi issue na aaye.
- Agar koi error aaye to error message share kar dein, main fix kar dunga.
