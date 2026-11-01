import '../core/constants/app_roles.dart';

/// User profile stored in Firestore `users/{uid}` (uid = Firebase Auth uid).
/// Passwords live ONLY in Firebase Auth - never in this model.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;

  /// Data scope for Regional / Department managers (null = no restriction).
  final String? regionId;
  final String? departmentId;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.regionId,
    this.departmentId,
    this.isActive = true,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? phone,
    String? regionId,
    String? departmentId,
    bool? isActive,
    bool clearRegion = false,
    bool clearDepartment = false,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      regionId: clearRegion ? null : (regionId ?? this.regionId),
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'roleId': AppRoles.idOf(role), // used by Firestore security rules
        'phone': phone,
        'regionId': regionId,
        'departmentId': departmentId,
        'isActive': isActive,
      };

  factory UserModel.fromMap(String id, Map<String, dynamic> m) => UserModel(
        id: id,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        role: m['role'] ?? AppRoles.guest,
        phone: m['phone'] ?? '',
        regionId: m['regionId'],
        departmentId: m['departmentId'],
        isActive: m['isActive'] ?? true,
      );
}
