import 'dart:async';
import 'package:get/get.dart';
import '../models/lookup_models.dart';
import '../repositories/lookup_repository.dart';
import 'auth_controller.dart';

/// Master data used by filters, forms and dashboards from Step 2 onwards.
class LookupController extends GetxController {
  final LookupRepository _repo = LookupRepository.instance;
  final AuthController _auth = Get.find<AuthController>();

  final RxList<RegionModel> regions = <RegionModel>[].obs;
  final RxList<DepartmentModel> departments = <DepartmentModel>[].obs;
  final RxList<CommercialRegistration> crs = <CommercialRegistration>[].obs;

  final List<StreamSubscription> _subs = [];

  @override
  void onInit() {
    super.onInit();
    ever(_auth.currentUser, (_) => _resubscribe());
    _resubscribe();
  }

  void _resubscribe() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    regions.clear();
    departments.clear();
    crs.clear();
    if (!_auth.isLoggedIn) return;
    _subs.add(_repo.watchRegions().listen(regions.assignAll, onError: (_) {}));
    _subs.add(_repo.watchDepartments().listen(departments.assignAll, onError: (_) {}));
    _subs.add(_repo.watchCrs().listen(crs.assignAll, onError: (_) {}));
  }

  List<RegionModel> get activeRegions => regions.where((r) => r.active).toList();
  List<DepartmentModel> get activeDepartments => departments.where((d) => d.active).toList();

  String regionName(String? id) =>
      regions.firstWhereOrNull((r) => r.id == id)?.name ?? (id ?? '-');
  String departmentName(String? id) =>
      departments.firstWhereOrNull((d) => d.id == id)?.name ?? (id ?? '-');

  Future<void> saveRegion(RegionModel r) => _repo.saveRegion(r);
  Future<void> saveDepartment(DepartmentModel d) => _repo.saveDepartment(d);
  Future<void> saveCr(CommercialRegistration c) => _repo.saveCr(c);

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }
}
