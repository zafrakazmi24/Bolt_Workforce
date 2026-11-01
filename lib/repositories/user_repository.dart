import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

/// Firestore-backed users. Profile docs: `users/{uid}`.
class UserRepository {
  UserRepository._internal();
  static final UserRepository instance = UserRepository._internal();
  factory UserRepository() => instance;

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('users');

  Future<UserModel?> getById(String uid) async {
    final d = await _col.doc(uid).get();
    if (!d.exists) return null;
    return UserModel.fromMap(d.id, d.data()!);
  }

  Stream<UserModel?> watchById(String uid) => _col.doc(uid).snapshots().map(
      (d) => d.exists ? UserModel.fromMap(d.id, d.data()!) : null);

  Stream<List<UserModel>> watchAll() => _col.orderBy('name').snapshots().map(
      (s) => s.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList());

  /// Email is intentionally not updated (it belongs to Firebase Auth).
  Future<void> update(UserModel u) => _col.doc(u.id).update({
        'name': u.name,
        'phone': u.phone,
        'role': u.role,
        'roleId': u.toMap()['roleId'],
        'regionId': u.regionId,
        'departmentId': u.departmentId,
        'isActive': u.isActive,
      });

  /// Soft delete: the account can no longer sign in, history is preserved.
  Future<void> deactivate(String uid) => _col.doc(uid).update({'isActive': false});

  /// Creates the Firebase Auth account WITHOUT logging the current admin out,
  /// by using a secondary FirebaseApp instance, then writes the profile doc.
  Future<UserModel> createWithPassword(UserModel u, String password) async {
    final auth = FirebaseAuth.instanceFor(app: await _secondaryApp());
    final cred = await auth.createUserWithEmailAndPassword(
        email: u.email.trim(), password: password);
    final uid = cred.user!.uid;
    await auth.signOut();
    final created = UserModel(
      id: uid, name: u.name, email: u.email.trim(), role: u.role,
      phone: u.phone, regionId: u.regionId, departmentId: u.departmentId,
    );
    await _col.doc(uid).set(created.toMap());
    return created;
  }

  static Future<FirebaseApp> _secondaryApp() async {
    const name = 'adminCreateUser';
    for (final a in Firebase.apps) {
      if (a.name == name) return a;
    }
    return Firebase.initializeApp(name: name, options: Firebase.app().options);
  }

  /// Used by the seed service (see firebase_seed_service.dart).
  static Future<FirebaseApp> secondaryApp() => _secondaryApp();
}
