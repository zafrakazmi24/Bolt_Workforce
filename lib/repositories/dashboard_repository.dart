import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/app_config.dart';
import '../models/dashboard_data.dart';

/// Aggregates dashboard KPIs from Firestore.
///
/// Collections (schema is shared with the upcoming modules):
///  employees, payroll_ledger, payments, loans, eosb, employee_documents.
/// Every doc carries denormalised `regionId` / `departmentId` so a manager's
/// scope can be applied in the query AND enforced by security rules.
/// Money fields are int halalas.
class DashboardRepository {
  DashboardRepository._internal();
  static final DashboardRepository instance = DashboardRepository._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static int _n(dynamic v) => v is num ? v.round() : 0;

  Future<DashboardData> load({
    required DashboardFilter filter,
    String? scopeRegionId,
    String? scopeDepartmentId,
    required bool canEmployees,
    required bool canFinance,
    required bool canExpiry,
  }) async {
    Query<Map<String, dynamic>> scoped(String col, {String? month}) {
      Query<Map<String, dynamic>> q = _db.collection(col);
      if (scopeRegionId != null) q = q.where('regionId', isEqualTo: scopeRegionId);
      if (scopeDepartmentId != null) q = q.where('departmentId', isEqualTo: scopeDepartmentId);
      if (month != null) q = q.where('period', isEqualTo: month);
      return q;
    }

    bool match(Map<String, dynamic> m) =>
        (filter.regionId == null || m['regionId'] == filter.regionId) &&
        (filter.departmentId == null || m['departmentId'] == filter.departmentId);

    // Fire all needed queries in parallel.
    final empF = canEmployees ? scoped('employees').get() : null;
    final ledF = canFinance ? scoped('payroll_ledger', month: filter.month).get() : null;
    final payF = canFinance ? scoped('payments', month: filter.month).get() : null;
    final loanF = canFinance ? scoped('loans').get() : null;
    final eosbF = canFinance ? scoped('eosb').get() : null;
    final docF = canExpiry ? scoped('employee_documents').get() : null;

    final empDocs = (await empF)?.docs ?? [];
    final ledDocs = (await ledF)?.docs ?? [];
    final payDocs = (await payF)?.docs ?? [];
    final loanDocs = (await loanF)?.docs ?? [];
    final eosbDocs = (await eosbF)?.docs ?? [];
    final docDocs = (await docF)?.docs ?? [];

    // ---- Employees ----
    final empById = {for (final d in empDocs) d.id: d.data()};
    final emps = empById.values.where(match).toList();
    int active = 0, temp = 0, off = 0, mudad = 0, ajeer = 0, watch = 0, loaded = 0;
    for (final e in emps) {
      final status = e['status'];
      if (status == 'Active') active++;
      if (status == 'Temporary') temp++;
      if (status == 'Offboarded') off++;
      if (e['isMudad'] == true) mudad++;
      if (e['isAjeer'] == true) ajeer++;
      if (status != 'Offboarded' && AppConfig.contractWatchStatuses.contains(e['contractStatus'])) watch++;
      if (AppConfig.costRosterStatuses.contains(status)) loaded += _monthlyCost(e);
    }

    // Company-wide comparison views (only scope-limited, not filter-limited).
    final costByDept = <String, int>{};
    final headByRegion = <String, int>{};
    for (final e in empById.values) {
      if (e['status'] == 'Active') {
        headByRegion[e['regionId'] ?? '-'] = (headByRegion[e['regionId'] ?? '-'] ?? 0) + 1;
      }
      if (AppConfig.costRosterStatuses.contains(e['status'])) {
        final k = (e['departmentId'] ?? '-') as String;
        costByDept[k] = (costByDept[k] ?? 0) + _monthlyCost(e);
      }
    }

    // ---- Payroll / payments ----
    int paid = 0, outstanding = 0, paidRows = 0, openRows = 0;
    for (final d in payDocs) {
      final m = d.data();
      if (match(m) && m['status'] == 'Posted') paid += _n(m['amount']);
    }
    for (final d in ledDocs) {
      final m = d.data();
      if (!match(m) || m['status'] == 'Cancelled') continue;
      if (m['status'] == 'Paid') paidRows++;
      if (AppConfig.openLedgerStatuses.contains(m['status'])) {
        openRows++;
        final o = _n(m['netPayable']) - _n(m['paid']);
        if (o > 0) outstanding += o;
      }
    }

    // ---- Loans / EOSB ----
    int loans = 0, eosb = 0;
    for (final d in loanDocs) {
      final m = d.data();
      if (match(m) && m['status'] == 'Active') loans += _n(m['remaining']);
    }
    for (final d in eosbDocs) {
      final m = d.data();
      if (match(m) && AppConfig.eosbPayableStatuses.contains(m['status'])) {
        final r = _n(m['approvedAmount']) - _n(m['paidAmount']);
        if (r > 0) eosb += r;
      }
    }

    // ---- Expiry ----
    final buckets = {'expired': 0, 'd7': 0, 'd30': 0, 'd60': 0, 'd90': 0};
    int red = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final d in docDocs) {
      final m = d.data();
      if (!match(m)) continue;
      final emp = empById[m['employeeId']];
      if (emp != null && emp['status'] == 'Offboarded') continue;
      final ts = m['expiryDate'];
      if (ts is! Timestamp) continue;
      final days = ts.toDate().difference(today).inDays;
      if (days < 0) {
        buckets['expired'] = buckets['expired']! + 1;
      } else if (days <= 7) {
        buckets['d7'] = buckets['d7']! + 1;
      } else if (days <= 30) {
        buckets['d30'] = buckets['d30']! + 1;
      } else if (days <= 60) {
        buckets['d60'] = buckets['d60']! + 1;
      } else if (days <= 90) {
        buckets['d90'] = buckets['d90']! + 1;
      }
      if (days <= AppConfig.expiryWarningDays) red++;
    }

    return DashboardData(
      total: emps.length, active: active, temporary: temp, offboarded: off,
      mudad: mudad, ajeer: ajeer, contractWatch: watch,
      fullyLoadedMinor: loaded, paidMinor: paid, outstandingMinor: outstanding,
      eosbPendingMinor: eosb, loansMinor: loans,
      paidRows: paidRows, openRows: openRows, redFlags: red,
      expiryBuckets: buckets, costByDepartment: costByDept, headcountByRegion: headByRegion,
      loadedAt: DateTime.now(),
    );
  }

  /// Base + allowances + GOSI + EOSB accrual + insurance + other recurring.
  /// Components are stored per employee so the formula stays configurable.
  static int _monthlyCost(Map<String, dynamic> e) =>
      _n(e['baseSalary']) + _n(e['allowances']) + _n(e['gosi']) +
      _n(e['eosbAccrual']) + _n(e['insurance']) + _n(e['otherCosts']);
}
