import 'package:get/get.dart';
import '../../controllers/lookup_controller.dart';
import '../data/rec.dart';

/// id -> label maps for dropdowns.
class Choices {
  Choices._();
  static LookupController get _l => Get.find<LookupController>();

  static Map<String, String> opts(List<String> l) => {for (final o in l) o: o};
  static Map<String, String> regions() => {for (final r in _l.activeRegions) r.id: r.name};
  static Map<String, String> departments() => {for (final d in _l.activeDepartments) d.id: d.name};
  static Map<String, String> crs() => {for (final c in _l.crs.where((c) => c.active)) c.id: '${c.branchName} (${c.crNumber})'};
  static Map<String, String> employees(List<Rec> emps) =>
      {for (final e in emps) e.id: '${e.s('code')} — ${e.s('name')}'};

  /// Denormalised employee reference stored on child documents
  /// (needed for filtering, manager scope and security rules).
  static Map<String, dynamic> empRef(Rec e) => {
        'employeeId': e.id,
        'employeeCode': e.s('code'),
        'employeeName': e.s('name'),
        'regionId': e.s('regionId'),
        'departmentId': e.s('departmentId'),
      };
}
