import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_roles.dart';
import '../../models/lookup_models.dart';
import '../../models/user_model.dart';
import '../../repositories/lookup_repository.dart';
import '../../repositories/role_repository.dart';
import '../../repositories/user_repository.dart';

/// ONE-TIME DEV SETUP. Creates demo Firebase Auth accounts, their Firestore
/// profiles, default roles/permissions and sample master data.
///
/// It runs while nobody is signed in, so Firestore must be in *test mode*
/// when you run it. Afterwards deploy `firestore.rules` (see FIREBASE_SETUP.md).
class FirebaseSeedService {
  FirebaseSeedService._();
  static const demoPassword = '123456';

  static final List<Map<String, String?>> _demoUsers = [
    {'name': 'Ayesha Khan', 'email': 'superadmin@test.com', 'role': AppRoles.superAdmin, 'phone': '0300-1234567'},
    {'name': 'Bilal Ahmed', 'email': 'admin@test.com', 'role': AppRoles.admin, 'phone': '0301-2345678'},
    {'name': 'Sara Malik', 'email': 'manager@test.com', 'role': AppRoles.manager, 'phone': '0302-3456789'},
    {'name': 'Hamza Tariq', 'email': 'employee@test.com', 'role': AppRoles.employee, 'phone': '0303-4567890'},
    {'name': 'Guest User', 'email': 'guest@test.com', 'role': AppRoles.guest, 'phone': '0304-5678901'},
    {'name': 'Fatima Noor', 'email': 'hradmin@test.com', 'role': AppRoles.hrAdmin, 'phone': '0305-6789012'},
    {'name': 'Usman Raza', 'email': 'payroll@test.com', 'role': AppRoles.payrollAccounts, 'phone': '0306-7890123'},
    {'name': 'Zainab Ali', 'email': 'regional@test.com', 'role': AppRoles.regionalManager, 'phone': '0307-8901234', 'regionId': 'riyadh'},
    {'name': 'Imran Shah', 'email': 'deptmanager@test.com', 'role': AppRoles.departmentManager, 'phone': '0308-9012345', 'departmentId': 'operations'},
    {'name': 'Nadia Hussain', 'email': 'auditor@test.com', 'role': AppRoles.viewerAuditor, 'phone': '0309-0123456'},
  ];

  /// Returns a short summary for the UI. Throws on failure.
  static Future<String> run() async {
    // 1) Roles
    for (final e in kDefaultRolePermissions.entries) {
      await RoleRepository.instance.save(e.key, e.value);
    }

    // 2) Master data (sample - editable later from the Master Data screen)
    final lookups = LookupRepository.instance;
    for (final r in const [
      RegionModel(id: 'neom', name: 'NEOM', code: 'NEOM'),
      RegionModel(id: 'riyadh', name: 'Riyadh', code: 'RYD'),
      RegionModel(id: 'jeddah', name: 'Jeddah', code: 'JED'),
    ]) {
      await lookups.saveRegion(r);
    }
    for (final d in const [
      DepartmentModel(id: 'operations', name: 'Operations'),
      DepartmentModel(id: 'technical', name: 'Technical'),
      DepartmentModel(id: 'administration', name: 'Administration'),
      DepartmentModel(id: 'finance', name: 'Finance & Accounts'),
      DepartmentModel(id: 'hr', name: 'Human Resources'),
    ]) {
      await lookups.saveDepartment(d);
    }
    for (final c in const [
      CommercialRegistration(id: 'neom_main', regionId: 'neom', branchName: 'NEOM — MAIN CR', crNumber: '7037584021'),
      CommercialRegistration(id: 'riyadh_cr', regionId: 'riyadh', branchName: 'RIYADH — CR', crNumber: '7042508759'),
      CommercialRegistration(id: 'jeddah_cr', regionId: 'jeddah', branchName: 'JEDDAH — CR', crNumber: '7042044292'),
    ]) {
      await lookups.saveCr(c);
    }

    // 3) Auth accounts + profiles (secondary app => nobody gets signed out)
    final auth = FirebaseAuth.instanceFor(app: await UserRepository.secondaryApp());
    int created = 0, existing = 0;
    for (final u in _demoUsers) {
      UserCredential cred;
      try {
        cred = await auth.createUserWithEmailAndPassword(email: u['email']!, password: demoPassword);
        created++;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') rethrow;
        cred = await auth.signInWithEmailAndPassword(email: u['email']!, password: demoPassword);
        existing++;
      }
      final profile = UserModel(
        id: cred.user!.uid,
        name: u['name']!,
        email: u['email']!,
        role: u['role']!,
        phone: u['phone'] ?? '',
        regionId: u['regionId'],
        departmentId: u['departmentId'],
      );
      await FirebaseFirestore.instance.collection('users').doc(profile.id).set(profile.toMap());
    }
    await auth.signOut();
    return 'Done: ${kDefaultRolePermissions.length} roles, 3 regions, 5 departments, 3 CRs, '
        '$created new + $existing existing users.';
  }
}
