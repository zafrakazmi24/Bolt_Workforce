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

/// PDF 7.2 - Loans & Advances: request -> approve/reject -> disburse -> recover.
class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  static const _repo = DocRepo('loans');
  static const _tx = DocRepo('loan_transactions');

  Future<void> _create() async {
    final emps = (await const DocRepo('employees').fetch()).where((e) => e.s('status') != 'Offboarded').toList();
    final v = await showFormDialog('New loan / advance', [
      FieldSpec('employee', 'Employee', type: FT.dropdown, required: true, choices: Choices.employees(emps)),
      FieldSpec('type', 'Type', type: FT.dropdown, required: true, choices: Choices.opts(['Loan', 'Advance']), initial: 'Advance'),
      const FieldSpec('total', 'Total amount', type: FT.money, required: true),
      FieldSpec('issueDate', 'Issue date', type: FT.date, required: true, initial: DateTime.now()),
      const FieldSpec('recoveryStart', 'Recovery start period (YYYY-MM)'),
      const FieldSpec('installment', 'Installment amount', type: FT.money, required: true),
      const FieldSpec('notes', 'Notes', type: FT.multiline),
    ]);
    if (v == null) return;
    final emp = emps.firstWhere((e) => e.id == v['employee']);
    final total = v['total'] as int;
    await _repo.add({
      ...Choices.empRef(emp),
      'type': v['type'], 'total': total, 'recovered': 0, 'remaining': total,
      'issueDate': v['issueDate'], 'recoveryStart': v['recoveryStart'], 'installment': v['installment'],
      'notes': v['notes'], 'status': 'Pending',
    });
  }

  Future<void> _decide(Rec l, bool approve) async {
    if (approve) {
      await _repo.update(l.id, {'status': 'Active'}, before: l.d, action: 'approve');
      await _tx.add({
        'loanId': l.id, 'employeeId': l.s('employeeId'), 'regionId': l.s('regionId'), 'departmentId': l.s('departmentId'),
        'type': 'Disbursement', 'amount': l.i('total'), 'date': Timestamp.now(),
      });
    } else {
      await _repo.update(l.id, {'status': 'Rejected'}, before: l.d, action: 'reject');
    }
  }

  Future<void> _recover(Rec l) async {
    final next = l.i('installment') < l.i('remaining') ? l.i('installment') : l.i('remaining');
    final v = await showFormDialog('Recover — ${l.s('employeeName')}', [
      FieldSpec('amount', 'Recovery amount', type: FT.money, required: true, initial: next),
      FieldSpec('date', 'Date', type: FT.date, required: true, initial: DateTime.now()),
      const FieldSpec('source', 'Source (payroll / manual)'),
    ], saveLabel: 'Post recovery');
    if (v == null) return;
    final amount = v['amount'] as int;
    final db = DocRepo.db;
    final lref = _repo.ref.doc(l.id);
    final tref = _tx.ref.doc();
    try {
      await db.runTransaction((tx) async {
        final d = (await tx.get(lref)).data();
        if (d == null) throw 'Loan not found';
        if (d['status'] != 'Active') throw 'Loan is not active';
        final remaining = (d['remaining'] as num).round();
        if (amount <= 0) throw 'Amount must be greater than zero';
        if (amount > remaining) throw 'Recovery exceeds remaining balance (${Money.sarExact(remaining)})';
        final newRem = remaining - amount;
        tx.update(lref, {
          'remaining': newRem, 'recovered': ((d['recovered'] ?? 0) as num).round() + amount,
          'status': newRem == 0 ? 'Closed' : 'Active',
        });
        tx.set(tref, {
          'loanId': l.id, 'employeeId': d['employeeId'], 'regionId': d['regionId'], 'departmentId': d['departmentId'],
          'type': 'Recovery', 'amount': amount, 'date': v['date'], 'source': v['source'] ?? '',
          'createdBy': FirebaseAuth.instance.currentUser?.uid,
        });
      });
      await DocRepo.audit('loans', l.id, 'recover', newData: {'amount': amount});
      toast('Posted', 'Recovery recorded');
    } catch (e) {
      toast('Not posted', e is String ? e : '$e', error: true);
    }
  }

  void _details(Rec l) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(Get.context!).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${l.s('employeeName')} · ${l.s('type')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            KV('Total', Money.sarExact(l.i('total'))),
            KV('Recovered', Money.sarExact(l.i('recovered'))),
            KV('Remaining', Money.sarExact(l.i('remaining'))),
            KV('Next installment', Money.sarExact(l.i('installment') < l.i('remaining') ? l.i('installment') : l.i('remaining'))),
            KV('Issue date', Fmt.date(l.dt('issueDate'))),
            KV('Recovery starts', l.s('recoveryStart')),
            KV('Status', l.s('status')),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (l.s('status') == 'Pending' && Scope.can(AppPermissions.loanApprove)) ...[
                ElevatedButton(onPressed: () { Get.back(); _decide(l, true); }, child: const Text('Approve')),
                OutlinedButton(onPressed: () { Get.back(); _decide(l, false); }, child: const Text('Reject')),
              ],
              if (l.s('status') == 'Active' && Scope.can(AppPermissions.loanRecover))
                ElevatedButton(onPressed: () { Get.back(); _recover(l); }, child: const Text('Post recovery')),
              if ((l.s('status') == 'Pending' || l.s('status') == 'Rejected') && Scope.can(AppPermissions.loanCreate))
                OutlinedButton(onPressed: () async { Get.back(); await _repo.softDelete(l.id); }, child: const Text('Delete')),
            ]),
            const Divider(height: 28),
            const Text('Transaction history', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(
              height: 180,
              child: RecStream(
                stream: _tx.watch(where: {'loanId': l.id}),
                builder: (c, rows) {
                  rows.sort((a, b) => (b.dt('date') ?? DateTime(2000)).compareTo(a.dt('date') ?? DateTime(2000)));
                  return ListView(children: [
                    for (final r in rows)
                      ListTile(dense: true, title: Text('${r.s('type')} · ${Money.sarExact(r.i('amount'))}'), subtitle: Text(Fmt.date(r.dt('date')))),
                  ]);
                },
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
      currentRoute: AppRoutes.loans,
      title: 'Loans & Advances',
      floatingActionButton: Scope.can(AppPermissions.loanCreate) ? FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)) : null,
      body: RecList(
        stream: _repo.watch(),
        emptyText: 'No loans or advances',
        sort: (a, b) => (b.dt('issueDate') ?? DateTime(2000)).compareTo(a.dt('issueDate') ?? DateTime(2000)),
        searchText: (l) => '${l.s('employeeName')} ${l.s('employeeCode')}',
        filters: {for (final s in ['Pending', 'Active', 'Closed', 'Rejected']) s: (l) => l.s('status') == s},
        header: (rows) {
          final rem = rows.where((l) => l.s('status') == 'Active').fold<int>(0, (a, l) => a + l.i('remaining'));
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Outstanding (active)', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(Money.sar(rem), style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
            ),
          );
        },
        itemBuilder: (context, l) => RecCard(
          title: '${l.s('employeeName')} · ${l.s('type')}',
          lines: ['Total ${Money.sarExact(l.i('total'))} · Remaining ${Money.sarExact(l.i('remaining'))}', 'Issued ${Fmt.date(l.dt('issueDate'))}'],
          trailing: StatusChip(l.s('status')),
          onTap: () => _details(l),
        ),
      ),
    );
  }
}
