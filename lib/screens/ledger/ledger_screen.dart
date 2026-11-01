import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/data/doc_repo.dart';
import '../../core/data/rec.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/fmt.dart';
import '../../core/utils/money.dart';
import '../../core/utils/scope.dart';
import '../../widgets/dynamic_form.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/rec_list.dart';
import '../payments/payment_actions.dart';

/// PDF 6.1 - Employee Ledger (monthly payroll rows).
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});
  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  static const _repo = DocRepo('payroll_ledger');
  String _period = Fmt.period(DateTime.now());
  List<Rec> _shownForExport = [];

  int _out(Rec r) {
    if (r.s('status') == 'Cancelled') return 0;
    final o = r.i('netPayable') - r.i('paid');
    return o < 0 ? 0 : o;
  }

  Future<void> _generate() async {
    if (!await confirm('Generate payroll', 'Create payroll rows for $_period for all non-offboarded employees that do not have one yet?', yes: 'Generate')) return;
    try {
      final emps = (await const DocRepo('employees').fetch()).where((e) => e.s('status') != 'Offboarded').toList();
      final existing = (await _repo.fetch(where: {'period': _period})).map((r) => r.id).toSet();
      final batch = DocRepo.db.batch();
      var n = 0;
      for (final e in emps) {
        final id = '${e.id}_$_period';
        if (existing.contains(id)) continue;
        final employer = e.i('gosi') + e.i('eosbAccrual') + e.i('insurance') + e.i('otherCosts');
        final net = e.i('baseSalary') + e.i('allowances');
        batch.set(_repo.ref.doc(id), {
          'employeeId': e.id, 'employeeCode': e.s('code'), 'employeeName': e.s('name'),
          'regionId': e.s('regionId'), 'departmentId': e.s('departmentId'),
          'period': _period, 'baseSalary': e.i('baseSalary'), 'allowances': e.i('allowances'),
          'employerCosts': employer, 'deductions': 0, 'netPayable': net, 'paid': 0, 'status': 'Unpaid',
        });
        n++;
      }
      await batch.commit();
      await DocRepo.audit('payroll_ledger', _period, 'generate', newData: {'rows': n});
      toast('Done', '$n payroll rows created');
    } catch (e) {
      toast('Failed', '$e', error: true);
    }
  }

  void _copyCsv() {
    final b = StringBuffer('Employee,Code,Period,Base,Allowances,Employer costs,Deductions,Net payable,Paid,Outstanding,Status\n');
    String m(int v) => (v / 100).toStringAsFixed(2);
    for (final r in _shownForExport) {
      b.writeln('"${r.s('employeeName')}",${r.s('employeeCode')},${r.s('period')},${m(r.i('baseSalary'))},${m(r.i('allowances'))},${m(r.i('employerCosts'))},${m(r.i('deductions'))},${m(r.i('netPayable'))},${m(r.i('paid'))},${m(_out(r))},${r.s('status')}');
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
    toast('Copied', 'Ledger CSV copied to clipboard');
  }

  Future<void> _editDeductions(Rec r) async {
    final v = await showFormDialog('Deductions — ${r.s('employeeName')}', [
      FieldSpec('deductions', 'Deductions (absence, loan recovery, penalty…)', type: FT.money, required: true, initial: r.i('deductions')),
    ]);
    if (v == null) return;
    final ded = v['deductions'] as int;
    final net = r.i('baseSalary') + r.i('allowances') - ded;
    if (net < r.i('paid')) {
      toast('Not allowed', 'Net payable cannot be lower than the amount already paid', error: true);
      return;
    }
    await _repo.update(r.id, {'deductions': ded, 'netPayable': net, 'status': PaymentActions.ledgerStatus(net, r.i('paid'))}, before: r.d);
  }

  Future<void> _setStatus(Rec r, String status) async {
    final back = status == 'Release';
    await _repo.update(r.id, {'status': back ? PaymentActions.ledgerStatus(r.i('netPayable'), r.i('paid')) : status}, before: r.d);
  }

  void _sheet(Rec r) {
    final open = r.s('status') == 'Unpaid' || r.s('status') == 'Partial';
    final canPay = Scope.can(AppPermissions.paymentCreate);
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(Get.context!).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r.s('employeeName')} · ${r.s('period')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            KV('Base salary', Money.sarExact(r.i('baseSalary'))),
            KV('Allowances', Money.sarExact(r.i('allowances'))),
            KV('Employer costs', Money.sarExact(r.i('employerCosts'))),
            KV('Deductions', Money.sarExact(r.i('deductions'))),
            KV('Net payable', Money.sarExact(r.i('netPayable'))),
            KV('Paid', Money.sarExact(r.i('paid'))),
            KV('Outstanding', Money.sarExact(_out(r))),
            KV('Status', r.s('status')),
            if (canPay) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (open)
                  ElevatedButton.icon(icon: const Icon(Icons.payments_rounded), label: const Text('Add payment'), onPressed: () { Get.back(); PaymentActions.addPaymentDialog(r); }),
                if (open) OutlinedButton(onPressed: () { Get.back(); _editDeductions(r); }, child: const Text('Edit deductions')),
                if (open) OutlinedButton(onPressed: () { Get.back(); _setStatus(r, 'On Hold'); }, child: const Text('Put on hold')),
                if (r.s('status') == 'On Hold') OutlinedButton(onPressed: () { Get.back(); _setStatus(r, 'Release'); }, child: const Text('Release hold')),
                if (r.i('paid') == 0 && r.s('status') != 'Cancelled') OutlinedButton(onPressed: () { Get.back(); _setStatus(r, 'Cancelled'); }, child: const Text('Cancel row')),
              ]),
            ],
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.ledger,
      title: 'Employee Ledger',
      actions: [
        if (Scope.can(AppPermissions.ledgerExport)) IconButton(tooltip: 'Copy CSV', icon: const Icon(Icons.copy_all_rounded), onPressed: _copyCsv),
        if (Scope.can(AppPermissions.paymentCreate)) IconButton(tooltip: 'Generate payroll', icon: const Icon(Icons.playlist_add_rounded), onPressed: _generate),
      ],
      body: Column(children: [
        DropdownButtonFormField<String>(
          initialValue: _period,
          decoration: const InputDecoration(labelText: 'Period', isDense: true),
          items: [for (final p in Fmt.lastPeriods()) DropdownMenuItem(value: p, child: Text(p))],
          onChanged: (v) => setState(() => _period = v ?? _period),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RecList(
            key: ValueKey(_period),
            stream: _repo.watch(where: {'period': _period}),
            emptyText: 'No payroll rows for $_period',
            sort: (a, b) => a.s('employeeCode').compareTo(b.s('employeeCode')),
            searchText: (r) => '${r.s('employeeName')} ${r.s('employeeCode')}',
            filters: {for (final s in ['Unpaid', 'Partial', 'Paid', 'On Hold', 'Cancelled']) s: (r) => r.s('status') == s},
            header: (rows) {
              _shownForExport = rows;
              final net = rows.where((r) => r.s('status') != 'Cancelled').fold<int>(0, (a, r) => a + r.i('netPayable'));
              final paid = rows.where((r) => r.s('status') != 'Cancelled').fold<int>(0, (a, r) => a + r.i('paid'));
              final out = rows.fold<int>(0, (a, r) => a + _out(r));
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _total('Net payable', net),
                    _total('Paid', paid),
                    _total('Outstanding', out),
                  ]),
                ),
              );
            },
            itemBuilder: (context, r) => RecCard(
              title: '${r.s('employeeName')} (${r.s('employeeCode')})',
              lines: ['Net ${Money.sarExact(r.i('netPayable'))} · Paid ${Money.sarExact(r.i('paid'))}', 'Outstanding ${Money.sarExact(_out(r))}'],
              trailing: StatusChip(r.s('status')),
              onTap: () => _sheet(r),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _total(String label, int v) => Column(children: [
        Text(Money.sar(v), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ]);
}
