import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lookup_models.dart';

/// Regions, Departments and Commercial Registrations (master data).
class LookupRepository {
  LookupRepository._internal();
  static final LookupRepository instance = LookupRepository._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<RegionModel>> watchRegions() => _db.collection('regions').orderBy('name').snapshots()
      .map((s) => s.docs.map(RegionModel.fromDoc).toList());
  Stream<List<DepartmentModel>> watchDepartments() => _db.collection('departments').orderBy('name').snapshots()
      .map((s) => s.docs.map(DepartmentModel.fromDoc).toList());
  Stream<List<CommercialRegistration>> watchCrs() => _db.collection('commercial_registrations').orderBy('branchName').snapshots()
      .map((s) => s.docs.map(CommercialRegistration.fromDoc).toList());

  Future<void> saveRegion(RegionModel r) => _db.collection('regions').doc(r.id).set(r.toMap());
  Future<void> saveDepartment(DepartmentModel d) => _db.collection('departments').doc(d.id).set(d.toMap());
  Future<void> saveCr(CommercialRegistration c) => _db.collection('commercial_registrations').doc(c.id).set(c.toMap());

  /// Generates a readable doc id from a name ("Jeddah" -> "jeddah").
  static String slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
}
