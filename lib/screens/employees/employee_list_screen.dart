import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/lookup_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/data/doc_repo.dart';
import '../../core/data/rec.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/fmt.dart';
import '../../core/utils/scope.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/rec_list.dart';

/// PDF 5.1 - searchable employee list with quick filters.
class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});
  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _lookups = Get.find<LookupController>();
  Set<String> _expiring = {};

  @override
  void initState() {
    super.initState();
    _loadExpiring();
  }

  Future<void> _loadExpiring() async {
    if (!Scope.can(AppPermissions.expiryView)) return;
    try {
      final docs = await const DocRepo('employee_documents').fetch();
      final ids = <String>{};
      for (final d in docs) {
        final e = d.dt('expiryDate');
        if (e != null && Fmt.daysUntil(e) <= AppConfig.expiryWarningDays) ids.add(d.s('employeeId'));
      }
      if (mounted) setState(() => _expiring = ids);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.employees,
      title: 'Employees',
      floatingActionButton: Scope.can(AppPermissions.employeeCreate)
          ? FloatingActionButton(onPressed: () => Get.toNamed(AppRoutes.employeeForm), child: const Icon(Icons.add))
          : null,
      body: RecList(
        stream: const DocRepo('employees').watch(),
        emptyText: 'No employees found',
        sort: (a, b) => a.s('code').compareTo(b.s('code')),
        searchText: (e) => [
          e.s('code'), e.s('name'), e.s('idNumber'), e.s('mobile'), e.s('jobTitle'),
          _lookups.departmentName(e.s('departmentId')), _lookups.regionName(e.s('regionId')),
        ].join(' '),
        filters: {
          'Active': (e) => e.s('status') == 'Active',
          'Offboarded': (e) => e.s('status') == 'Offboarded',
          'Mudad': (e) => e.b('isMudad'),
          'Ajeer': (e) => e.b('isAjeer'),
          'Expiring Soon': (e) => _expiring.contains(e.id),
          'Contract Watch': (e) => e.s('status') != 'Offboarded' && AppConfig.contractWatchStatuses.contains(e.s('contractStatus')),
        },
        itemBuilder: (context, e) => RecCard(
          title: e.s('name'),
          lines: [
            '${e.s('code')} · ${e.s('jobTitle', '-')}',
            '${_lookups.regionName(e.s('regionId'))} · ${_lookups.departmentName(e.s('departmentId'))}',
          ],
          trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusChip(e.s('status', '-')),
            if (_expiring.contains(e.id))
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
              ),
          ]),
          onTap: () => Get.toNamed(AppRoutes.employeeDetails, arguments: e.id),
        ),
      ),
    );
  }
}
