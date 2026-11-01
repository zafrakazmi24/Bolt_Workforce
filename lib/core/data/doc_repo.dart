import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/scope.dart';
import 'rec.dart';

/// Generic Firestore access for every module.
///  - applies the manager's region / department scope automatically
///  - soft delete / restore / purge
///  - writes an audit log entry for every create / update / delete
class DocRepo {
  final String col;
  final bool scoped;
  const DocRepo(this.col, {this.scoped = true});

  static FirebaseFirestore get db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get ref => db.collection(col);
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Query<Map<String, dynamic>> _q(Map<String, dynamic>? where) {
    Query<Map<String, dynamic>> q = ref;
    if (scoped) {
      final r = Scope.region, d = Scope.dept;
      if (r != null) q = q.where('regionId', isEqualTo: r);
      if (d != null) q = q.where('departmentId', isEqualTo: d);
    }
    where?.forEach((k, v) => q = q.where(k, isEqualTo: v));
    return q;
  }

  List<Rec> _map(QuerySnapshot<Map<String, dynamic>> s, bool deleted) =>
      s.docs.map((d) => Rec(d.id, d.data())).where((r) => r.deleted == deleted).toList();

  Stream<List<Rec>> watch({Map<String, dynamic>? where, bool deleted = false}) =>
      _q(where).snapshots().map((s) => _map(s, deleted));

  Future<List<Rec>> fetch({Map<String, dynamic>? where, bool deleted = false}) async =>
      _map(await _q(where).get(), deleted);

  Future<Rec?> getOne(String id) async {
    final d = await ref.doc(id).get();
    return d.exists ? Rec(d.id, d.data()!) : null;
  }

  Stream<Rec?> watchOne(String id) =>
      ref.doc(id).snapshots().map((d) => d.exists ? Rec(d.id, d.data()!) : null);

  Future<String> add(Map<String, dynamic> data, {String? id}) async {
    final doc = id == null ? ref.doc() : ref.doc(id);
    await doc.set({...data, 'createdAt': FieldValue.serverTimestamp(), 'createdBy': _uid});
    await audit(col, doc.id, 'create', newData: data);
    return doc.id;
  }

  /// [before] (optional) = previous values; only changed fields go to the audit log.
  Future<void> update(String id, Map<String, dynamic> data,
      {Map<String, dynamic>? before, String action = 'update'}) async {
    await ref.doc(id).update({...data, 'updatedAt': FieldValue.serverTimestamp(), 'updatedBy': _uid});
    Map<String, dynamic> oldD = {}, newD = data;
    if (before != null) {
      newD = {for (final e in data.entries) if (before[e.key] != e.value) e.key: e.value};
      oldD = {for (final k in newD.keys) k: before[k]};
      if (newD.isEmpty) return;
    }
    await audit(col, id, action, oldData: oldD, newData: newD);
  }

  Future<void> softDelete(String id) async {
    await ref.doc(id).update({'isDeleted': true, 'deletedAt': FieldValue.serverTimestamp(), 'deletedBy': _uid});
    await audit(col, id, 'delete');
  }

  Future<void> restore(String id) async {
    await ref.doc(id).update({'isDeleted': false, 'deletedAt': null, 'deletedBy': null});
    await audit(col, id, 'restore');
  }

  Future<void> purge(String id) async {
    await ref.doc(id).delete();
    await audit(col, id, 'purge');
  }

  /// Audit trail: module, record, action, old/new values, user, time.
  static Future<void> audit(String module, String recordId, String action,
      {Map<String, dynamic>? oldData, Map<String, dynamic>? newData}) async {
    try {
      final u = FirebaseAuth.instance.currentUser;
      await db.collection('audit_logs').add({
        'module': module,
        'recordId': recordId,
        'action': action,
        'oldData': oldData ?? {},
        'newData': newData ?? {},
        'by': u?.uid,
        'byEmail': u?.email,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (_) {/* never block the user action because of logging */}
  }
}
