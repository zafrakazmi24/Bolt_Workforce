import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

/// PDF 7.3 - EOSB settlements.
/// Workflow: Draft -> Reviewed -> Approved -> Partially Paid -> Settled / Cancelled.
/// The amount is ENTERED by the user: the PDF says the formula must not be
/// hard-coded until management/legal approve it.
class EosbScreen extends StatelessWidget {
  const EosbScreen({super.key});

  static const _repo = DocRepo('eosb');
  static const _pay = DocRepo('eosb_payments');

  List<FieldSpec> _fields(Rec? r, {List<Rec> emps = const []}) => [
        if (r == null) FieldSpec('employee', 'Employee', type: FT.dropdown, required: true, choices: Choices.employees(emps)),
        FieldSpec('lastWorkingDate', 'Last working date', type: FT.date, required: true, initial: r?.d['lastWorkingDate']),
        FieldSpec('serviceMonths', 'Service period (months)', type: FT.number, initial: r?.d['serviceMonths']),
        FieldSpec('calcNotes', 'Calculation inputs / basis', type: FT.multiline, initial: r?.s('calcNotes')),
        FieldSpec('computedAmount', 'Calculated amount (per approved policy)', type: FT.money, required: true, initial: r?.d['computedAmount']),
        FieldSpec('adjustments', 'Adjustments (+/-)', type: FT.money, initial: r?.d['adjustments']),
      ];

  Future<void> _create() async {
    final emps = await const DocRepo('employees').fetch();
    final v = await showFormDialog('New EOSB settlement', _fields(null, emps: emps));
    if (v == null) return;
    final emp = emps.firstWhere((e) => e.id == v['employee']);
    final computed = v['computedAmount'] as int, adj = (v['adjustments'] ?? 0) as int;
    v.remove('employee');
    await _repo.add({
      ...Choices.empRef(emp), ...v, 'adjustments': adj, 'payableAmount': computed + adj,
      'approvedAmount': 0, 'paidAmount': 0, 'status': 'Draft',
    });
  }

  Future<void> _edit(Rec r) async {
    final v = await showFormDialog('Edit EOSB', _fields(r));
    if (v == null) return;
    final computed = v['computedAmount'] as int, adj = (v['adjustments'] ?? 0) as int;
    await _repo.update(r.id, {...v, 'adjustments': adj, 'payableAmount': computed + adj}, before: r.d);
  }

  Future<void> _setStatus(Rec r, String status) async {
    final data = <String, dynamic>{'status': status};
    if (status == 'Approved') data['approvedAmount'] = r.i('payableAmount');
    await _repo.update(r.id, data, before: r.d, action: status.toLowerCase());
  }

  Future<void> _recordPayment(Rec r) async {
    final remaining = r.i('approvedAmount') - r.i('paidAmount');
    final v = await showFormDialog('EOSB payment — ${r.s('employeeName')}', [
      FieldSpec('amount', 'Amount', type: FT.money, required: true, initial: remaining),
      FieldSpec('date', 'Payment date', type: FT.date, required: true, initial: DateTime.now()),
      const FieldSpec('reference', 'Reference number'),
    ], saveLabel: 'Post payment');
    if (v == null) return;
    final amount = v['amount'] as int;
    final db = DocRepo.db;
    final eref = _repo.ref.doc(r.id);
    final pref = _pay.ref.doc();
    try {
      await db.runTransaction((tx) async {
        final d = (await tx.get(eref)).data();
        if (d == null) throw 'Settlement not found';
        if (d['status'] != 'Approved' && d['status'] != 'Partially Paid') throw 'Settlement is not payable';
        final approved = (d['approvedAmount'] as num).round(), paid = (d['paidAmount'] as num).round();
        if (amount <= 0) throw 'Amount must be greater than zero';
        if (amount > approved - paid) throw 'Exceeds remaining (${Money.sarExact(approved - paid)})';
        final newPaid = paid + amount;
        tx.update(eref, {'paidAmount': newPaid, 'status': newPaid >= approved ? 'Settled' : 'Partially Paid'});
        tx.set(pref, {
          'eosbId': r.id, 'employeeId': d['employeeId'], 'regionId': d['regionId'], 'departmentId': d['departmentId'],
          'amount': amount, 'date': v['date'], 'reference': v['reference'] ?? '',
          'createdBy': FirebaseAuth.instance.currentUser?.uid,
        });
      });
      await DocRepo.audit('eosb', r.id, 'pay', newData: {'amount': amount});
      toast('Posted', 'EOSB payment recorded');
    } catch (e) {
      toast('Not posted', e is String ? e : '$e', error: true);
    }
  }

  void _details(Rec r) {
    final st = r.s('status');
    final canCreate = Scope.can(AppPermissions.eosbCreate), canApprove = Scope.can(AppPermissions.eosbApprove), canPay = Scope.can(AppPermissions.eosbPay);
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(Get.context!).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.s('employeeName'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            KV('Last working date', Fmt.date(r.dt('lastWorkingDate'))),
            KV('Service (months)', r.s('serviceMonths')),
            KV('Calculation basis', r.s('calcNotes')),
            KV('Calculated', Money.sarExact(r.i('computedAmount'))),
            KV('Adjustments', Money.sarExact(r.i('adjustments'))),
            KV('Payable', Money.sarExact(r.i('payableAmount'))),
            KV('Approved', Money.sarExact(r.i('approvedAmount'))),
            KV('Paid', Money.sarExact(r.i('paidAmount'))),
            KV('Status', st),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (st == 'Draft' && canCreate) OutlinedButton(onPressed: () { Get.back(); _edit(r); }, child: const Text('Edit')),
              if (st == 'Draft' && canCreate) ElevatedButton(onPressed: () { Get.back(); _setStatus(r, 'Reviewed'); }, child: const Text('Mark reviewed')),
              if (st == 'Reviewed' && canApprove) ElevatedButton(onPressed: () { Get.back(); _setStatus(r, 'Approved'); }, child: const Text('Approve')),
              if ((st == 'Approved' || st == 'Partially Paid') && canPay) ElevatedButton(onPressed: () { Get.back(); _recordPayment(r); }, child: const Text('Record payment')),
              if ((st == 'Draft' || st == 'Reviewed' || st == 'Approved') && canApprove) OutlinedButton(onPressed: () { Get.back(); _setStatus(r, 'Cancelled'); }, child: const Text('Cancel')),
              if ((st == 'Draft' || st == 'Cancelled') && canCreate) OutlinedButton(onPressed: () async { Get.back(); await _repo.softDelete(r.id); }, child: const Text('Delete')),
            ]),
            const Divider(height: 28),
            const Text('Payment history', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(
              height: 140,
              child: RecStream(
                stream: _pay.watch(where: {'eosbId': r.id}),
                builder: (c, rows) => ListView(children: [
                  for (final p in rows) ListTile(dense: true, title: Text(Money.sarExact(p.i('amount'))), subtitle: Text('${Fmt.date(p.dt('date'))} ${p.s('reference')}')),
                ]),
              ),
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.eosb,
      title: 'EOSB Settlements',
      floatingActionButton: Scope.can(AppPermissions.eosbCreate) ? FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)) : null,
      body: RecList(
        stream: _repo.watch(),
        emptyText: 'No EOSB settlements',
        sort: (a, b) => (b.dt('lastWorkingDate') ?? DateTime(2000)).compareTo(a.dt('lastWorkingDate') ?? DateTime(2000)),
        searchText: (r) => '${r.s('employeeName')} ${r.s('employeeCode')}',
        filters: {for (final s in ['Draft', 'Reviewed', 'Approved', 'Partially Paid', 'Settled', 'Cancelled']) s: (r) => r.s('status') == s},
        itemBuilder: (context, r) => RecCard(
          title: r.s('employeeName'),
          lines: ['Last day ${Fmt.date(r.dt('lastWorkingDate'))}', 'Payable ${Money.sarExact(r.i('payableAmount'))} · Paid ${Money.sarExact(r.i('paidAmount'))}'],
          trailing: StatusChip(r.s('status')),
          onTap: () => _details(r),
        ),
      ),
    );
  }
}
