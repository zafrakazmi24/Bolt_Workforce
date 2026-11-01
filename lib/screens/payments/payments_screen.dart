import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/data/doc_repo.dart';
import '../../core/data/rec.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/fmt.dart';
import '../../core/utils/money.dart';
import '../../core/utils/scope.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/rec_list.dart';
import 'payment_actions.dart';

/// PDF 6.2 - Payment Log.
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  static const _repo = DocRepo('payments');

  Future<void> _newPayment() async {
    // choose an open payroll row, then post against it
    final open = (await const DocRepo('payroll_ledger').fetch())
        .where((r) => r.s('status') == 'Unpaid' || r.s('status') == 'Partial')
        .toList()
      ..sort((a, b) => b.s('period').compareTo(a.s('period')));
    if (open.isEmpty) {
      toast('No open payroll', 'Generate payroll in Employee Ledger first');
      return;
    }
    final picked = await Get.dialog<Rec>(SimpleDialog(
      title: const Text('Select payroll row'),
      children: [
        SizedBox(
          width: double.maxFinite,
          height: 360,
          child: ListView(children: [
            for (final r in open)
              ListTile(
                title: Text('${r.s('employeeCode')} — ${r.s('employeeName')}'),
                subtitle: Text('${r.s('period')} · outstanding ${Money.sarExact(r.i('netPayable') - r.i('paid'))}'),
                onTap: () => Get.back(result: r),
              ),
          ]),
        ),
      ],
    ));
    if (picked != null) await PaymentActions.addPaymentDialog(picked);
  }

  void _details(Rec p) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(Get.context!).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.s('employeeName'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            KV('Period', p.s('period')),
            KV('Amount', Money.sarExact(p.i('amount'))),
            KV('Date', Fmt.date(p.dt('date'))),
            KV('Method', p.s('method')),
            KV('Reference', p.s('reference')),
            KV('Bank / account', p.s('bankAccount')),
            KV('Notes', p.s('notes')),
            KV('Status', p.s('status')),
            if (p.s('overrideReason').isNotEmpty) KV('Override reason', p.s('overrideReason')),
            if (p.s('reverseReason').isNotEmpty) KV('Reversal reason', p.s('reverseReason')),
            if (p.s('status') == 'Posted' && Scope.can(AppPermissions.paymentReverse)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Reverse payment'),
                  onPressed: () async {
                    Get.back();
                    await PaymentActions.reverseDialog(p);
                  },
                ),
              ),
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
      currentRoute: AppRoutes.payments,
      title: 'Payment Log',
      floatingActionButton: Scope.can(AppPermissions.paymentCreate)
          ? FloatingActionButton.extended(onPressed: _newPayment, icon: const Icon(Icons.add), label: const Text('Add payment'))
          : null,
      body: RecList(
        stream: _repo.watch(),
        emptyText: 'No payments yet',
        sort: (a, b) => (b.dt('date') ?? DateTime(2000)).compareTo(a.dt('date') ?? DateTime(2000)),
        searchText: (p) => '${p.s('employeeName')} ${p.s('employeeCode')} ${p.s('reference')} ${p.s('period')}',
        filters: {
          'Posted': (p) => p.s('status') == 'Posted',
          'Reversed': (p) => p.s('status') == 'Reversed',
        },
        itemBuilder: (context, p) => RecCard(
          title: '${p.s('employeeName')} · ${Money.sarExact(p.i('amount'))}',
          lines: ['${p.s('period')} · ${p.s('method')} · ${Fmt.date(p.dt('date'))}', if (p.s('reference').isNotEmpty) 'Ref ${p.s('reference')}'],
          trailing: StatusChip(p.s('status')),
          onTap: () => _details(p),
        ),
      ),
    );
  }
}
