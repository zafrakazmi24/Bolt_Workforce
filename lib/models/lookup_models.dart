import 'package:cloud_firestore/cloud_firestore.dart';

typedef _Doc = DocumentSnapshot<Map<String, dynamic>>;

/// Firestore `regions/{id}` - e.g. NEOM, Riyadh, Jeddah.
class RegionModel {
  final String id;
  final String name;
  final String code;
  final bool active;
  const RegionModel({required this.id, required this.name, this.code = '', this.active = true});

  Map<String, dynamic> toMap() => {'name': name, 'code': code, 'active': active};
  factory RegionModel.fromDoc(_Doc d) {
    final m = d.data() ?? {};
    return RegionModel(id: d.id, name: m['name'] ?? '', code: m['code'] ?? '', active: m['active'] ?? true);
  }
}

/// Firestore `departments/{id}`.
class DepartmentModel {
  final String id;
  final String name;
  final String costCenter;
  final bool active;
  const DepartmentModel({required this.id, required this.name, this.costCenter = '', this.active = true});

  Map<String, dynamic> toMap() => {'name': name, 'costCenter': costCenter, 'active': active};
  factory DepartmentModel.fromDoc(_Doc d) {
    final m = d.data() ?? {};
    return DepartmentModel(id: d.id, name: m['name'] ?? '', costCenter: m['costCenter'] ?? '', active: m['active'] ?? true);
  }
}

/// Firestore `commercial_registrations/{id}` - each CR pays its own GOSI.
class CommercialRegistration {
  final String id;
  final String regionId;
  final String branchName;
  final String crNumber;
  final String gosiRef;
  final String status;
  final String notes;
  final bool active;
  const CommercialRegistration({
    required this.id,
    required this.regionId,
    required this.branchName,
    required this.crNumber,
    this.gosiRef = '',
    this.status = 'Active',
    this.notes = '',
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
        'regionId': regionId,
        'branchName': branchName,
        'crNumber': crNumber,
        'gosiRef': gosiRef,
        'status': status,
        'notes': notes,
        'active': active,
      };
  factory CommercialRegistration.fromDoc(_Doc d) {
    final m = d.data() ?? {};
    return CommercialRegistration(
      id: d.id,
      regionId: m['regionId'] ?? '',
      branchName: m['branchName'] ?? '',
      crNumber: m['crNumber'] ?? '',
      gosiRef: m['gosiRef'] ?? '',
      status: m['status'] ?? 'Active',
      notes: m['notes'] ?? '',
      active: m['active'] ?? true,
    );
  }
}
