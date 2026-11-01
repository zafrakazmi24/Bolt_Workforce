import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/data/doc_repo.dart';
import '../../core/data/rec.dart';
import '../../core/utils/choices.dart';
import '../../core/utils/money.dart';
import '../../core/utils/scope.dart';
import '../../widgets/dynamic_form.dart';
import '../../widgets/rec_list.dart';

/// All payment writes go through Firestore TRANSACTIONS so the ledger and the
/// payment log can never disagree (PDF 6.2, 16: server confirms before success).
class PaymentActions {
  PaymentActions._();

  static const methods = ['Bank Transfer', 'Cash', 'Cheque', 'Payroll Batch'];
  static int _n(dynamic v) => v is num ? v.round() : 0;

  static String ledgerStatus(int net, int paid) => paid <= 0 ? 'Unpaid' : (paid >= net ? 'Paid' : 'Partial');

  /// Dialog + transaction. Returns true if a payment was posted.
  static Future<bool> addPaymentDialog(Rec ledger) async {
    final outstanding = _n(ledger.d['netPayable']) - _n(ledger.d['paid']);
    final canOverride = Scope.can(AppPermissions.paymentOverride);
    final v = await showFormDialog('Add payment — ${ledger.s('employeeName')} (${ledger.s('period')})', [
      FieldSpec('amount', 'Amount', type: FT.money, required: true, initial: outstanding > 0 ? outstanding : null),
      FieldSpec('date', 'Payment date', type: FT.date, required: true, initial: DateTime.now()),
      FieldSpec('method', 'Method', type: FT.dropdown, required: true, choices: Choices.opts(methods), initial: methods.first),
      const FieldSpec('reference', 'Reference number'),
      const FieldSpec('bankAccount', 'Bank / account'),
      const FieldSpec('notes', 'Notes', type: FT.multiline),
      if (canOverride) ...const [
        FieldSpec('override', 'Allow overpayment (override)', type: FT.toggle),
        FieldSpec('overrideReason', 'Override reason (required if override)'),
      ],
    ], saveLabel: 'Post payment');
    if (v == null) return false;
    final err = await addPayment(
      ledger: ledger,
      amount: v['amount'] as int,
      date: (v['date'] as Timestamp),
      method: v['method'] as String,
      reference: v['reference'] ?? '',
      bankAccount: v['bankAccount'] ?? '',
      notes: v['notes'] ?? '',
      override: v['override'] == true,
      overrideReason: (v['overrideReason'] ?? '') as String,
    );
    if (err != null) {
      toast('Payment not posted', err, error: true);
      return false;
    }
    toast('Posted', 'Payment recorded');
    return true;
  }

  static Future<String?> addPayment({
    required Rec ledger,
    required int amount,
    required Timestamp date,
    required String method,
    String reference = '',
    String bankAccount = '',
    String notes = '',
    bool override = false,
    String overrideReason = '',
  }) async {
    if (amount <= 0) return 'Amount must be greater than zero';
    if (override && overrideReason.trim().isEmpty) return 'Override needs a reason';
    final db = DocRepo.db;
    final lref = db.collection('payroll_ledger').doc(ledger.id);
    final pref = db.collection('payments').doc();
    try {
      await db.runTransaction((tx) async {
        final snap = await tx.get(lref);
        final d = snap.data();
        if (d == null) throw 'Ledger row no longer exists';
        final st = d['status'];
        if (st == 'On Hold' || st == 'Cancelled') throw 'This payroll row is $st';
        final net = _n(d['netPayable']), paid = _n(d['paid']);
        final newPaid = paid + amount;
        if (newPaid > net && !override) throw 'Payment exceeds outstanding (${Money.sarExact(net - paid)})';
        tx.update(lref, {'paid': newPaid, 'status': ledgerStatus(net, newPaid)});
        tx.set(pref, {
          'employeeId': d['employeeId'], 'employeeCode': d['employeeCode'], 'employeeName': d['employeeName'],
          'regionId': d['regionId'], 'departmentId': d['departmentId'],
          'ledgerId': ledger.id, 'period': d['period'],
          'amount': amount, 'date': date, 'method': method, 'reference': reference,
          'bankAccount': bankAccount, 'notes': notes, 'status': 'Posted',
          if (override) 'overrideReason': overrideReason,
          'createdAt': FieldValue.serverTimestamp(), 'createdBy': FirebaseAuth.instance.currentUser?.uid,
        });
      });
      await DocRepo.audit('payments', pref.id, 'pay', newData: {'ledgerId': ledger.id, 'amount': amount, 'method': method});
      return null;
    } catch (e) {
      return e is String ? e : 'Payment failed: $e';
    }
  }

  /// Controlled reversal: payment is marked Reversed (never edited/deleted).
  static Future<bool> reverseDialog(Rec payment) async {
    final v = await showFormDialog('Reverse payment', [
      const FieldSpec('reason', 'Reason for reversal', type: FT.multiline, required: true),
    ], saveLabel: 'Reverse');
    if (v == null) return false;
    final db = DocRepo.db;
    final pref = db.collection('payments').doc(payment.id);
    try {
      await db.runTransaction((tx) async {
        final ps = await tx.get(pref);
        final pd = ps.data();
        if (pd == null || pd['status'] != 'Posted') throw 'Only posted payments can be reversed';
        final lid = pd['ledgerId'] as String?;
        if (lid == null) throw 'Payment is not linked to a ledger row';
        final lref = db.collection('payroll_ledger').doc(lid);
        final ls = await tx.get(lref);
        final ld = ls.data();
        if (ld == null) throw 'Ledger row not found';
        final net = _n(ld['netPayable']);
        var newPaid = _n(ld['paid']) - _n(pd['amount']);
        if (newPaid < 0) newPaid = 0;
        tx.update(pref, {
          'status': 'Reversed', 'reverseReason': v['reason'],
          'reversedAt': FieldValue.serverTimestamp(), 'reversedBy': FirebaseAuth.instance.currentUser?.uid,
        });
        final keep = ld['status'] == 'On Hold' || ld['status'] == 'Cancelled';
        tx.update(lref, {'paid': newPaid, if (!keep) 'status': ledgerStatus(net, newPaid)});
      });
      await DocRepo.audit('payments', payment.id, 'reverse', newData: {'reason': v['reason'], 'amount': payment.i('amount')});
      toast('Reversed', 'Payment reversed');
      return true;
    } catch (e) {
      toast('Not reversed', e is String ? e : '$e', error: true);
      return false;
    }
  }
}
