import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/lookup_controller.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/data/doc_repo.dart';
import '../../core/data/rec.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/choices.dart';
import '../../core/utils/fmt.dart';
import '../../core/utils/money.dart';
import '../../core/utils/scope.dart';
import '../../widgets/dynamic_form.dart';
import '../../widgets/rec_list.dart';

/// PDF 5.2 - Employee profile with tabs. Get.arguments = employee id.
class EmployeeDetailsScreen extends StatelessWidget {
  const EmployeeDetailsScreen({super.key});

  static const _repo = DocRepo('employees');
  static int _pos(int v) => v < 0 ? 0 : v;

  @override
  Widget build(BuildContext context) {
    final id = Get.arguments as String;
    return StreamBuilder<Rec?>(
      stream: _repo.watchOne(id),
      builder: (context, snap) {
        if (snap.hasError) return Scaffold(appBar: AppBar(), body: Center(child: Text('${snap.error}')));
        if (!snap.hasData) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        final e = snap.data;
        if (e == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Employee not found')));

        final tabs = <String, Widget>{
          'Overview': _overview(e),
          'Employment': _employment(e),
          'Identity & Compliance': _DocsTab(e, const ['Iqama', 'Passport', 'Work Permit', 'Insurance', 'Mudad']),
          if (Scope.can(AppPermissions.ledgerView)) 'Ledger': _ledger(e),
          if (Scope.can(AppPermissions.attendanceView)) 'Attendance': _AttendanceTab(e),
          if (Scope.can(AppPermissions.loanView)) 'Loans': _loans(e),
          if (Scope.can(AppPermissions.eosbView)) 'EOSB': _eosb(e),
          if (Scope.can(AppPermissions.assetView)) 'Assets': _assets(e),
          'Documents': _DocsTab(e, const ['Contract', 'Certificate', 'Other']),
          if (Scope.can(AppPermissions.auditView)) 'Audit History': _audit(e),
        };

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(e.s('name'), style: const TextStyle(fontWeight: FontWeight.w800)),
              actions: [
                if (Scope.can(AppPermissions.employeeUpdate))
                  IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => Get.toNamed(AppRoutes.employeeForm, arguments: e.id)),
                if (Scope.can(AppPermissions.employeeDelete))
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      if (await confirm('Delete employee', 'Move ${e.s('name')} to Trash? It can be restored later.', yes: 'Delete')) {
                        await _repo.softDelete(e.id);
                        Get.back();
                      }
                    },
                  ),
              ],
              bottom: TabBar(isScrollable: true, tabs: [for (final t in tabs.keys) Tab(text: t)]),
            ),
            body: TabBarView(children: tabs.values.toList()),
          ),
        );
      },
    );
  }

  // ---------- Overview ----------
  Widget _overview(Rec e) {
    final l = Get.find<LookupController>();
    final cr = l.crs.firstWhereOrNull((c) => c.id == e.s('crId'));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [Expanded(child: Text(e.s('name'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), StatusChip(e.s('status', '-'))]),
      const SizedBox(height: 10),
      KV('Employee code', e.s('code')),
      KV('Nationality', e.s('nationality')),
      KV('Mobile', e.s('mobile')),
      KV('Email', e.s('email')),
      KV('Job title', e.s('jobTitle')),
      KV('Department', l.departmentName(e.s('departmentId'))),
      KV('Region', l.regionName(e.s('regionId'))),
      KV('Sponsor / CR', cr == null ? '' : '${cr.branchName} (${cr.crNumber})'),
      KV('Joining date', Fmt.date(e.dt('joiningDate'))),
      KV('Work location', e.s('workLocation')),
    ]);
  }

  // ---------- Employment (salary only for payroll-authorised roles) ----------
  Widget _employment(Rec e) {
    final showPay = Scope.can(AppPermissions.ledgerView) || Scope.can(AppPermissions.employeeUpdate);
    return ListView(padding: const EdgeInsets.all(20), children: [
      KV('Contract type', e.s('contractType')),
      KV('Contract start', Fmt.date(e.dt('contractStart'))),
      KV('Contract end', Fmt.date(e.dt('contractEnd'))),
      KV('Contract status', e.s('contractStatus')),
      KV('Payroll type', e.s('payrollType')),
      KV('Mudad', e.b('isMudad') ? 'Registered' : 'Not registered'),
      KV('Ajeer', e.b('isAjeer') ? 'Yes' : 'No'),
      const Divider(height: 28),
      if (!showPay)
        const Text('Compensation details are restricted for your role.', style: TextStyle(color: Colors.grey))
      else ...[
        KV('Base salary', Money.sarExact(e.i('baseSalary'))),
        KV('Allowances', Money.sarExact(e.i('allowances'))),
        KV('GOSI (employer)', Money.sarExact(e.i('gosi'))),
        KV('EOSB accrual', Money.sarExact(e.i('eosbAccrual'))),
        KV('Insurance', Money.sarExact(e.i('insurance'))),
        KV('Other costs', Money.sarExact(e.i('otherCosts'))),
      ],
    ]);
  }

  // ---------- Simple list tabs ----------
  Widget _list(String collection, Rec e, Widget Function(Rec) tile, {String empty = 'No records'}) => RecStream(
        stream: DocRepo(collection).watch(where: {'employeeId': e.id}),
        builder: (c, rows) => rows.isEmpty
            ? Center(child: Text(empty, style: const TextStyle(color: Colors.grey)))
            : ListView(padding: const EdgeInsets.all(16), children: [for (final r in rows) tile(r)]),
      );

  Widget _ledger(Rec e) => _list('payroll_ledger', e, (r) => RecCard(
        title: r.s('period'),
        lines: ['Net ${Money.sarExact(r.i('netPayable'))} · Paid ${Money.sarExact(r.i('paid'))}', 'Outstanding ${Money.sarExact(_pos(r.i('netPayable') - r.i('paid')))}'],
        trailing: StatusChip(r.s('status')),
      ));

  Widget _loans(Rec e) => _list('loans', e, (r) => RecCard(
        title: '${r.s('type', 'Loan')} · ${Money.sarExact(r.i('total'))}',
        lines: ['Remaining ${Money.sarExact(r.i('remaining'))}', 'Issued ${Fmt.date(r.dt('issueDate'))}'],
        trailing: StatusChip(r.s('status')),
      ));

  Widget _eosb(Rec e) => _list('eosb', e, (r) => RecCard(
        title: 'Last working day ${Fmt.date(r.dt('lastWorkingDate'))}',
        lines: ['Approved ${Money.sarExact(r.i('approvedAmount'))} · Paid ${Money.sarExact(r.i('paidAmount'))}'],
        trailing: StatusChip(r.s('status')),
      ));

  Widget _assets(Rec e) => _list('asset_assignments', e, (r) => RecCard(
        title: '${r.s('assetCode')} · ${r.s('assetType')}',
        lines: ['Issued ${Fmt.date(r.dt('issueDate'))}', r.dt('returnDate') == null ? 'Not returned' : 'Returned ${Fmt.date(r.dt('returnDate'))}'],
        trailing: StatusChip(r.dt('returnDate') == null ? 'Issued' : 'Closed'),
      ));

  Widget _audit(Rec e) => RecStream(
        stream: const DocRepo('audit_logs', scoped: false).watch(where: {'recordId': e.id}),
        builder: (c, rows) {
          rows.sort((a, b) => (b.dt('at') ?? DateTime(2000)).compareTo(a.dt('at') ?? DateTime(2000)));
          if (rows.isEmpty) return const Center(child: Text('No history yet', style: TextStyle(color: Colors.grey)));
          return ListView(padding: const EdgeInsets.all(16), children: [
            for (final r in rows)
              RecCard(
                title: '${r.s('action')} · ${r.s('module')}',
                lines: [
                  '${r.s('byEmail')} · ${r.dt('at') == null ? '' : Fmt.dateTime(r.dt('at')!)}',
                  for (final k in (r.d['newData'] as Map? ?? {}).keys) '$k: ${(r.d['oldData'] as Map?)?[k] ?? '-'} → ${(r.d['newData'] as Map)[k]}',
                ],
              ),
          ]);
        },
      );
}

// ---------- Documents / Identity tab (document records) ----------
class _DocsTab extends StatelessWidget {
  final Rec emp;
  final List<String> types;
  const _DocsTab(this.emp, this.types);

  static const _repo = DocRepo('employee_documents');

  Future<void> _edit(Rec? r) async {
    final v = await showFormDialog(r == null ? 'Add document' : 'Edit document', [
      FieldSpec('type', 'Type', type: FT.dropdown, required: true, choices: Choices.opts(types), initial: r?.s('type')),
      FieldSpec('number', 'Number / reference', initial: r?.s('number')),
      FieldSpec('issueDate', 'Issue date', type: FT.date, initial: r?.d['issueDate']),
      FieldSpec('expiryDate', 'Expiry date', type: FT.date, initial: r?.d['expiryDate']),
      FieldSpec('notes', 'Notes / provider', type: FT.multiline, initial: r?.s('notes')),
    ]);
    if (v == null) return;
    if (r == null) {
      await _repo.add({...Choices.empRef(emp), ...v});
    } else {
      await _repo.update(r.id, v, before: r.d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = Scope.can(AppPermissions.employeeUpdate);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canEdit ? FloatingActionButton.small(onPressed: () => _edit(null), child: const Icon(Icons.add)) : null,
      body: RecStream(
        stream: _repo.watch(where: {'employeeId': emp.id}),
        builder: (c, all) {
          final rows = all.where((r) => types.contains(r.s('type'))).toList();
          if (rows.isEmpty) return const Center(child: Text('No documents', style: TextStyle(color: Colors.grey)));
          return ListView(padding: const EdgeInsets.all(16), children: [
            for (final r in rows)
              RecCard(
                title: '${r.s('type')} ${r.s('number')}',
                lines: ['Issued ${Fmt.date(r.dt('issueDate'))} · Expires ${Fmt.date(r.dt('expiryDate'))}', if (r.s('notes').isNotEmpty) r.s('notes')],
                trailing: r.dt('expiryDate') == null
                    ? null
                    : (() {
                        final days = Fmt.daysUntil(r.dt('expiryDate')!);
                        return StatusChip(days < 0 ? 'Expired' : '$days d', color: days < 0 ? Colors.red : (days <= 30 ? Colors.orange : Colors.green));
                      })(),
                onTap: canEdit ? () => _edit(r) : null,
              ),
          ]);
        },
      ),
    );
  }
}

// ---------- Attendance tab (monthly summary) ----------
class _AttendanceTab extends StatefulWidget {
  final Rec emp;
  const _AttendanceTab(this.emp);
  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  String _month = Fmt.period(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          initialValue: _month,
          decoration: const InputDecoration(labelText: 'Month'),
          items: [for (final m in Fmt.lastPeriods()) DropdownMenuItem(value: m, child: Text(m))],
          onChanged: (v) => setState(() => _month = v ?? _month),
        ),
      ),
      Expanded(
        child: RecStream(
          stream: const DocRepo('attendance').watch(where: {'employeeId': widget.emp.id, 'month': _month}),
          builder: (c, rows) {
            rows.sort((a, b) => a.s('date').compareTo(b.s('date')));
            final counts = <String, int>{};
            for (final r in rows) {
              counts[r.s('status')] = (counts[r.s('status')] ?? 0) + 1;
            }
            return ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
              Wrap(spacing: 8, runSpacing: 8, children: [for (final e in counts.entries) StatusChip('${e.key}: ${e.value}')]),
              const SizedBox(height: 10),
              for (final r in rows) ListTile(dense: true, title: Text(r.s('date')), trailing: StatusChip(r.s('status'))),
            ]);
          },
        ),
      ),
    ]);
  }
}
