import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_roles.dart';

/// Firestore `roles/{roleId}` -> { name, permissions[], isSystem }.
class RoleRepository {
  RoleRepository._internal();
  static final RoleRepository instance = RoleRepository._internal();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('roles');

  static Map<String, List<String>> _toMap(QuerySnapshot<Map<String, dynamic>> s) => {
        for (final d in s.docs)
          (d.data()['name'] ?? d.id) as String:
              List<String>.from(d.data()['permissions'] ?? const []),
      };

  Future<Map<String, List<String>>> getAll() async => _toMap(await _col.get());
  Stream<Map<String, List<String>>> watchAll() => _col.snapshots().map(_toMap);

  Future<void> save(String name, List<String> permissions) => _col.doc(AppRoles.idOf(name)).set({
        'name': name,
        'permissions': permissions,
        'isSystem': AppRoles.all.contains(name),
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
