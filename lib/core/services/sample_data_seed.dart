import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/money.dart';

/// DEV ONLY - loads fake workforce data so the dashboard can be tested.
/// Must be run by a signed-in Super Admin (see firestore.rules).
/// Every document has `isSample: true` and a fixed id, so running it again
/// just overwrites the same documents (no duplicates).
/// Real employees arrive in Step 3; delete sample docs then.
class SampleDataSeed {
  SampleDataSeed._();

  static const _regions = ['neom', 'riyadh', 'jeddah'];
  static const _depts = ['operations', 'technical', 'administration', 'finance', 'hr'];

  static String _period(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static Future<String> run() async {
    final db = FirebaseFirestore.instance;
    final rnd = Random(42);
    final now = DateTime.now();
    final periods = [for (var i = 2; i >= 0; i--) _period(DateTime(now.year, now.month - i))];

    final ops = <MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>>[];
    void put(String col, String id, Map<String, dynamic> data) =>
        ops.add(MapEntry(db.collection(col).doc(id), {...data, 'isSample': true}));

    for (var i = 1; i <= 60; i++) {
      final id = 'emp_${i.toString().padLeft(3, '0')}';
      final status = i <= 44 ? 'Active' : (i <= 48 ? 'Temporary' : 'Offboarded');
      final region = _regions[rnd.nextInt(_regions.length)];
      final dept = _depts[rnd.nextInt(_depts.length)];
      final isMudad = rnd.nextDouble() < 0.65;
      final baseSar = 2500 + rnd.nextInt(65) * 100;
      final base = Money.toMinor(baseSar);
      final allow = Money.toMinor((baseSar * 0.25).round());
      final contract = i % 13 == 0
          ? 'Transfer Pending'
          : i % 17 == 0
              ? 'Pending Renewal'
              : i % 29 == 0
                  ? 'Cancelled'
                  : 'Active';

      put('employees', id, {
        'code': 'BLT-${i.toString().padLeft(4, '0')}',
        'name': 'Sample Employee $i',
        'regionId': region,
        'departmentId': dept,
        'status': status,
        'isMudad': isMudad,
        'isAjeer': !isMudad,
        'contractStatus': contract,
        // monthly employer cost components (halalas) - sample values only
        'baseSalary': base,
        'allowances': allow,
        'gosi': Money.toMinor((baseSar * 0.1175).round()),
        'eosbAccrual': Money.toMinor((baseSar / 24).round()),
        'insurance': Money.toMinor(150 + rnd.nextInt(100)),
        'otherCosts': 0,
      });

      final common = {
        'employeeId': id,
        'employeeCode': 'BLT-${i.toString().padLeft(4, '0')}',
        'employeeName': 'Sample Employee $i',
        'regionId': region,
        'departmentId': dept,
      };

      if (status != 'Offboarded') {
        // payroll ledger + payments for the last 3 months
        for (var p = 0; p < periods.length; p++) {
          final net = base + allow - (rnd.nextBool() ? 0 : Money.toMinor(200));
          final latest = p == periods.length - 1;
          final roll = rnd.nextDouble();
          String ledgerStatus;
          int paid;
          if (!latest) {
            final full = roll < 0.95;
            ledgerStatus = full ? 'Paid' : 'Partial';
            paid = full ? net : net ~/ 2;
          } else if (roll < 0.4) {
            ledgerStatus = 'Paid';
            paid = net;
          } else if (roll < 0.6) {
            ledgerStatus = 'Partial';
            paid = net ~/ 2;
          } else {
            ledgerStatus = 'Unpaid';
            paid = 0;
          }
          put('payroll_ledger', '${id}_${periods[p]}', {
            ...common, 'period': periods[p], 'netPayable': net, 'paid': paid, 'status': ledgerStatus,
          });
          if (paid > 0) {
            put('payments', 'pay_${id}_${periods[p]}', {
              ...common, 'period': periods[p], 'amount': paid, 'status': 'Posted',
              'method': 'Bank Transfer', 'date': Timestamp.fromDate(DateTime.now()),
            });
          }
        }
        // identity / compliance documents
        for (final type in ['iqama', 'insurance', 'work_permit']) {
          final days = rnd.nextInt(220) - 30; // some already expired
          put('employee_documents', '${id}_$type', {
            ...common, 'type': type,
            'expiryDate': Timestamp.fromDate(DateTime.now().add(Duration(days: days))),
          });
        }
        if (i % 7 == 0) {
          final total = Money.toMinor(3000 + rnd.nextInt(5) * 1000);
          put('loans', 'loan_$id', {
            ...common, 'total': total, 'remaining': total ~/ 2, 'status': 'Active',
          });
        }
      } else {
        final approved = Money.toMinor(5000 + rnd.nextInt(10) * 1000);
        final s = i % 3 == 0 ? 'Settled' : (i % 3 == 1 ? 'Approved' : 'Partially Paid');
        put('eosb', 'eosb_$id', {
          ...common, 'approvedAmount': approved,
          'paidAmount': s == 'Settled' ? approved : (s == 'Partially Paid' ? approved ~/ 3 : 0),
          'status': s,
        });
      }
    }

    // Firestore batch limit is 500 writes.
    for (var i = 0; i < ops.length; i += 400) {
      final batch = db.batch();
      for (final op in ops.skip(i).take(400)) {
        batch.set(op.key, op.value);
      }
      await batch.commit();
    }
    return 'Sample data loaded: ${ops.length} documents.';
  }
}
