import 'package:get/get.dart';
import '../core/constants/app_permissions.dart';
import '../models/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';
import 'permission_controller.dart';

/// Dashboard state: Region / Department / Month filters + KPI data.
class DashboardController extends GetxController {
  final DashboardRepository _repo = DashboardRepository.instance;
  final PermissionController _perm = Get.find<PermissionController>();

  final Rxn<DashboardData> data = Rxn<DashboardData>();
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  final Rxn<String> regionId = Rxn<String>();
  final Rxn<String> departmentId = Rxn<String>();
  final Rxn<String> month = Rxn<String>(); // null = All Months

  // What this user is allowed to see (also enforced by Firestore rules).
  bool get canEmployees => _perm.hasPermission(AppPermissions.employeeView);
  bool get canFinance => _perm.hasPermission(AppPermissions.dashboardFinance);
  bool get canExpiry => _perm.hasPermission(AppPermissions.expiryView);
  bool get canCost => canEmployees && canFinance;

  String? get lockedRegionId => _perm.scopeRegionId;
  String? get lockedDepartmentId => _perm.scopeDepartmentId;

  /// Last 12 months as 'YYYY-MM', newest first.
  List<String> get months {
    final now = DateTime.now();
    return [
      for (var i = 0; i < 12; i++)
        () {
          final d = DateTime(now.year, now.month - i);
          return '${d.year}-${d.month.toString().padLeft(2, '0')}';
        }()
    ];
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void setRegion(String? v) { regionId.value = v; load(); }
  void setDepartment(String? v) { departmentId.value = v; load(); }
  void setMonth(String? v) { month.value = v; load(); }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      data.value = await _repo.load(
        filter: DashboardFilter(
          regionId: lockedRegionId ?? regionId.value,
          departmentId: lockedDepartmentId ?? departmentId.value,
          month: month.value,
        ),
        scopeRegionId: lockedRegionId,
        scopeDepartmentId: lockedDepartmentId,
        canEmployees: canEmployees,
        canFinance: canFinance,
        canExpiry: canExpiry,
      );
    } catch (e) {
      error.value = 'Could not load dashboard: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
