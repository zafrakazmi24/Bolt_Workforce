import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

/// PDF 9.1 - Remote expenses: Draft -> Submitted -> Approved/Rejected -> Paid.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  static const _repo = DocRepo('expenses');
  static const cats = ['Travel', 'Accommodation', 'Food', 'Fuel', 'Materials', 'Communication', 'Other'];
  String? _category;

  Future<void> _edit(Rec? r) async {
    final emps = await const DocRepo('employees').fetch();
    final v = await showFormDialog(r == null ? 'New expense' : 'Edit expense', [
      FieldSpec('employee', 'Employee (optional)', type: FT.dropdown, choices: Choices.employees(emps), initial: r?.s('employeeId').isEmpty == true ? null : r?.s('employeeId')),
      FieldSpec('site', 'Site / project', initial: r?.s('site')),
      FieldSpec('regionId', 'Region', type: FT.dropdown, required: true, choices: Choices.regions(), initial: r?.s('regionId').isEmpty == true ? Scope.region : r?.s('regionId')),
      FieldSpec('departmentId', 'Department', type: FT.dropdown, required: true, choices: Choices.departments(), initial: r?.s('departmentId').isEmpty == true ? Scope.dept : r?.s('departmentId')),
      FieldSpec('category', 'Category', type: FT.dropdown, required: true, choices: Choices.opts(cats), initial: r?.s('category')),
      FieldSpec('date', 'Date', type: FT.date, required: true, initial: r?.d['date'] ?? DateTime.now()),
      FieldSpec('amount', 'Amount', type: FT.money, required: true, initial: r?.d['amount']),
      FieldSpec('currency', 'Currency', initial: r?.s('currency', 'SAR')),
      FieldSpec('vat', 'VAT / tax', type: FT.money, initial: r?.d['vat']),
      FieldSpec('description', 'Description', type: FT.multiline, initial: r?.s('description')),
    ]);
    if (v == null) return;
    final emp = emps.firstWhereOrNull((e) => e.id == v['employee']);
    final data = {
      if (emp != null) ...Choices.empRef(emp),
      if (emp == null) ...{'employeeId': '', 'employeeName': ''},
      ...v..remove('employee'),
      'vat': v['vat'] ?? 0,
    };
    if (emp != null) {
      data['regionId'] = emp.s('regionId');
      data['departmentId'] = emp.s('departmentId');
    }
    if (r == null) {
      await _repo.add({...data, 'status': 'Draft'});
    } else {
      await _repo.update(r.id, data, before: r.d);
    }
  }

  Future<void> _setStatus(Rec r, String status, {String? reason}) async {
    await _repo.update(r.id, {'status': status, if (reason != null) 'rejectReason': reason}, before: r.d, action: status.toLowerCase());
  }

  void _details(Rec r) {
    final st = r.s('status');
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(Get.context!).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r.s('category')} · ${Money.sarExact(r.i('amount'))}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            KV('Employee', r.s('employeeName')),
            KV('Site', r.s('site')),
            KV('Date', Fmt.date(r.dt('date'))),
            KV('VAT / tax', Money.sarExact(r.i('vat'))),
            KV('Description', r.s('description')),
            KV('Status', st),
            if (r.s('rejectReason').isNotEmpty) KV('Rejected because', r.s('rejectReason')),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if ((st == 'Draft' || st == 'Rejected') && Scope.can(AppPermissions.expenseCreate)) ...[
                OutlinedButton(onPressed: () { Get.back(); _edit(r); }, child: const Text('Edit')),
                ElevatedButton(onPressed: () { Get.back(); _setStatus(r, 'Submitted'); }, child: const Text('Submit')),
                OutlinedButton(onPressed: () async { Get.back(); await _repo.softDelete(r.id); }, child: const Text('Delete')),
              ],
              if (st == 'Submitted' && Scope.can(AppPermissions.expenseApprove)) ...[
                ElevatedButton(onPressed: () { Get.back(); _setStatus(r, 'Approved'); }, child: const Text('Approve')),
                OutlinedButton(
                  onPressed: () async {
                    Get.back();
                    final v = await showFormDialog('Reject expense', [const FieldSpec('reason', 'Reason', required: true)], saveLabel: 'Reject');
                    if (v != null) _setStatus(r, 'Rejected', reason: v['reason']);
                  },
                  child: const Text('Reject'),
                ),
              ],
              if (st == 'Approved' && Scope.can(AppPermissions.expensePay))
                ElevatedButton(onPressed: () { Get.back(); _setStatus(r, 'Paid'); }, child: const Text('Mark paid')),
            ]),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.expenses,
      title: 'Remote Expenses',
      floatingActionButton: Scope.can(AppPermissions.expenseCreate) ? FloatingActionButton(onPressed: () => _edit(null), child: const Icon(Icons.add)) : null,
      body: Column(children: [
        DropdownButtonFormField<String?>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'Category', isDense: true),
          items: [const DropdownMenuItem<String?>(value: null, child: Text('All categories')), for (final c in cats) DropdownMenuItem<String?>(value: c, child: Text(c))],
          onChanged: (v) => setState(() => _category = v),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RecList(
            stream: _repo.watch(),
            emptyText: 'No expenses',
            extra: (r) => _category == null || r.s('category') == _category,
            sort: (a, b) => (b.dt('date') ?? DateTime(2000)).compareTo(a.dt('date') ?? DateTime(2000)),
            searchText: (r) => '${r.s('employeeName')} ${r.s('site')} ${r.s('description')} ${r.s('category')}',
            filters: {for (final s in ['Draft', 'Submitted', 'Approved', 'Rejected', 'Paid']) s: (r) => r.s('status') == s},
            itemBuilder: (context, r) => RecCard(
              title: '${r.s('category')} · ${Money.sarExact(r.i('amount'))}',
              lines: ['${r.s('employeeName').isEmpty ? r.s('site') : r.s('employeeName')} · ${Fmt.date(r.dt('date'))}'],
              trailing: StatusChip(r.s('status')),
              onTap: () => _details(r),
            ),
          ),
        ),
      ]),
    );
  }
}
