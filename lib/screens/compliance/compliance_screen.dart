import 'package:flutter/material.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/data/doc_repo.dart';
import '../../core/data/rec.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/choices.dart';
import '../../core/utils/fmt.dart';
import '../../core/utils/money.dart';
import '../../core/utils/scope.dart';
import '../../widgets/dynamic_form.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/rec_list.dart';
import 'package:get/get.dart';

/// PDF 9.2 - Compliance costs (GOSI, insurance, permits, Ajeer, Mudad, custom).
class ComplianceScreen extends StatelessWidget {
  const ComplianceScreen({super.key});

  static const _repo = DocRepo('compliance_costs');
  static const types = ['GOSI', 'Medical insurance', 'Iqama / work permit', 'Ajeer', 'Mudad', 'Custom'];

  Future<void> _edit(Rec? r) async {
    final emps = await const DocRepo('employees').fetch();
    final v = await showFormDialog(r == null ? 'New compliance cost' : 'Edit compliance cost', [
      FieldSpec('type', 'Cost type', type: FT.dropdown, required: true, choices: Choices.opts(types), initial: r?.s('type')),
      FieldSpec('period', 'Period (YYYY-MM)', required: true, initial: r?.s('period', Fmt.period(DateTime.now()))),
      FieldSpec('amount', 'Amount', type: FT.money, required: true, initial: r?.d['amount']),
      FieldSpec('recurring', 'Recurring monthly cost', type: FT.toggle, initial: r?.b('recurring') ?? false),
      const FieldSpec.section('Linked to (leave empty = company-wide)'),
      FieldSpec('employee', 'Employee', type: FT.dropdown, choices: Choices.employees(emps), initial: r?.s('employeeId').isEmpty == true ? null : r?.s('employeeId')),
      FieldSpec('crId', 'Commercial Registration', type: FT.dropdown, choices: Choices.crs(), initial: r?.s('crId').isEmpty == true ? null : r?.s('crId')),
      FieldSpec('regionId', 'Region', type: FT.dropdown, choices: Choices.regions(), initial: r?.s('regionId').isEmpty == true ? null : r?.s('regionId')),
      FieldSpec('departmentId', 'Department', type: FT.dropdown, choices: Choices.departments(), initial: r?.s('departmentId').isEmpty == true ? null : r?.s('departmentId')),
      FieldSpec('notes', 'Notes', type: FT.multiline, initial: r?.s('notes')),
    ]);
    if (v == null) return;
    final emp = emps.firstWhereOrNull((e) => e.id == v['employee']);
    v.remove('employee');
    final data = {...v, if (emp != null) ...Choices.empRef(emp), if (emp == null) ...{'employeeId': '', 'employeeName': ''}};
    if (r == null) {
      await _repo.add(data);
    } else {
      await _repo.update(r.id, data, before: r.d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = Scope.can(AppPermissions.complianceUpdate);
    return MainShell(
      currentRoute: AppRoutes.compliance,
      title: 'Compliance Costs',
      floatingActionButton: Scope.can(AppPermissions.complianceCreate) ? FloatingActionButton(onPressed: () => _edit(null), child: const Icon(Icons.add)) : null,
      body: RecList(
        stream: _repo.watch(),
        emptyText: 'No compliance costs',
        sort: (a, b) => b.s('period').compareTo(a.s('period')),
        searchText: (r) => '${r.s('type')} ${r.s('employeeName')} ${r.s('period')} ${r.s('notes')}',
        filters: {for (final t in types) t: (r) => r.s('type') == t, 'Recurring': (r) => r.b('recurring')},
        header: (rows) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total (shown)', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(Money.sar(rows.fold<int>(0, (a, r) => a + r.i('amount'))), style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
        itemBuilder: (context, r) => RecCard(
          title: '${r.s('type')} · ${Money.sarExact(r.i('amount'))}',
          lines: [
            '${r.s('period')}${r.b('recurring') ? ' · recurring' : ''}',
            r.s('employeeName').isNotEmpty ? r.s('employeeName') : (r.s('crId').isNotEmpty ? 'CR: ${r.s('crId')}' : 'Company-wide'),
          ],
          trailing: canEdit
              ? IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () async {
                  if (await confirm('Delete', 'Move this cost to Trash?', yes: 'Delete')) await _repo.softDelete(r.id);
                })
              : null,
          onTap: canEdit ? () => _edit(r) : null,
        ),
      ),
    );
  }
}
