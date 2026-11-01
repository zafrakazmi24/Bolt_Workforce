import 'package:flutter/material.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/data/doc_repo.dart';
import '../../core/data/rec.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/choices.dart';
import '../../core/utils/fmt.dart';
import '../../core/utils/scope.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/rec_list.dart';

/// PDF 7.1 - Attendance: daily marking + monthly summary.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const _repo = DocRepo('attendance');
  static const codes = ['Present', 'Absent', 'Leave', 'Sick', 'Site', 'Remote', 'Off', 'Holiday'];
  DateTime _date = DateTime.now();
  String _month = Fmt.period(DateTime.now());

  bool get _canEdit => Scope.can(AppPermissions.attendanceCreate) || Scope.can(AppPermissions.attendanceUpdate);

  Future<void> _mark(Rec emp, String? status) async {
    if (status == null) return;
    final day = Fmt.ymd(_date);
    try {
      await _repo.ref.doc('${emp.id}_$day').set({
        ...Choices.empRef(emp), 'date': day, 'month': day.substring(0, 7), 'status': status,
      });
    } catch (e) {
      toast('Not saved', '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.attendance,
      title: 'Attendance',
      body: DefaultTabController(
        length: 2,
        child: Column(children: [
          const TabBar(tabs: [Tab(text: 'Daily'), Tab(text: 'Monthly summary')]),
          Expanded(child: TabBarView(children: [_daily(), _monthly()])),
        ]),
      ),
    );
  }

  Widget _daily() {
    final day = Fmt.ymd(_date);
    return Column(children: [
      const SizedBox(height: 10),
      OutlinedButton.icon(
        icon: const Icon(Icons.calendar_today_rounded, size: 18),
        label: Text(Fmt.date(_date)),
        onPressed: () async {
          final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
          if (d != null) setState(() => _date = d);
        },
      ),
      const SizedBox(height: 10),
      Expanded(
        child: RecStream(
          stream: const DocRepo('employees').watch(),
          builder: (c, emps) => RecStream(
            key: ValueKey(day),
            stream: _repo.watch(where: {'date': day}),
            builder: (c, marks) {
              final byEmp = {for (final m in marks) m.s('employeeId'): m.s('status')};
              final list = emps.where((e) => e.s('status') != 'Offboarded').toList()..sort((a, b) => a.s('code').compareTo(b.s('code')));
              if (list.isEmpty) return const Center(child: Text('No employees', style: TextStyle(color: Colors.grey)));
              return ListView(children: [
                for (final e in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(e.s('name'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(e.s('code')),
                      trailing: SizedBox(
                        width: 120,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Not marked'),
                          value: byEmp[e.id],
                          items: [for (final c in codes) DropdownMenuItem(value: c, child: Text(c))],
                          onChanged: _canEdit ? (v) => _mark(e, v) : null,
                        ),
                      ),
                    ),
                  ),
              ]);
            },
          ),
        ),
      ),
    ]);
  }

  Widget _monthly() {
    return Column(children: [
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        initialValue: _month,
        decoration: const InputDecoration(labelText: 'Month', isDense: true),
        items: [for (final m in Fmt.lastPeriods()) DropdownMenuItem(value: m, child: Text(m))],
        onChanged: (v) => setState(() => _month = v ?? _month),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: RecStream(
          key: ValueKey(_month),
          stream: _repo.watch(where: {'month': _month}),
          builder: (c, rows) {
            final byEmp = <String, Map<String, int>>{};
            final names = <String, String>{};
            final total = <String, int>{};
            for (final r in rows) {
              final id = r.s('employeeId');
              names[id] = '${r.s('employeeCode')} — ${r.s('employeeName')}';
              final m = byEmp.putIfAbsent(id, () => {});
              m[r.s('status')] = (m[r.s('status')] ?? 0) + 1;
              total[r.s('status')] = (total[r.s('status')] ?? 0) + 1;
            }
            if (rows.isEmpty) return const Center(child: Text('No attendance recorded', style: TextStyle(color: Colors.grey)));
            final ids = byEmp.keys.toList()..sort((a, b) => names[a]!.compareTo(names[b]!));
            return ListView(children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(spacing: 8, runSpacing: 8, children: [for (final e in total.entries) StatusChip('${e.key}: ${e.value}')]),
                ),
              ),
              for (final id in ids)
                RecCard(
                  title: names[id]!,
                  trailing: null,
                  lines: [byEmp[id]!.entries.map((e) => '${e.key} ${e.value}').join(' · ')],
                ),
            ]);
          },
        ),
      ),
    ]);
  }
}
