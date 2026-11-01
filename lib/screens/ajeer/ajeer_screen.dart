import 'package:flutter/material.dart';
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

/// PDF 3 / 10 - Outsourced (Ajeer) workers: provider, contract, expiry, cost.
class AjeerScreen extends StatelessWidget {
  const AjeerScreen({super.key});

  static const _emps = DocRepo('employees');
  static const _repo = DocRepo('ajeer_records');

  Future<void> _edit(Rec emp, Rec? r) async {
    final v = await showFormDialog('Ajeer — ${emp.s('name')}', [
      FieldSpec('provider', 'Provider', required: true, initial: r?.s('provider')),
      FieldSpec('contractNo', 'Contract / permit number', initial: r?.s('contractNo')),
      FieldSpec('startDate', 'Start date', type: FT.date, initial: r?.d['startDate']),
      FieldSpec('endDate', 'End date', type: FT.date, required: true, initial: r?.d['endDate']),
      FieldSpec('cost', 'Cost', type: FT.money, initial: r?.d['cost']),
      FieldSpec('status', 'Status', type: FT.dropdown, required: true,
          choices: Choices.opts(['Active', 'Pending', 'Expired', 'Cancelled']), initial: r?.s('status', 'Active')),
    ]);
    if (v == null) return;
    v['cost'] = v['cost'] ?? 0;
    if (r == null) {
      await _repo.add({...Choices.empRef(emp), ...v}, id: emp.id); // one record per worker
    } else {
      await _repo.update(r.id, v, before: r.d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = Scope.can(AppPermissions.ajeerUpdate);
    return MainShell(
      currentRoute: AppRoutes.ajeer,
      title: 'Outsourced (Ajeer)',
      body: RecStream(
        stream: _emps.watch(),
        builder: (context, emps) => RecStream(
          stream: _repo.watch(),
          builder: (context, records) {
            final byEmp = {for (final r in records) r.s('employeeId'): r};
            final workers = emps.where((e) => e.b('isAjeer') && e.s('status') != 'Offboarded').toList()
              ..sort((a, b) => a.s('name').compareTo(b.s('name')));
            if (workers.isEmpty) return const Center(child: Text('No Ajeer workers', style: TextStyle(color: Colors.grey)));
            return ListView(children: [
              for (final w in workers)
                () {
                  final r = byEmp[w.id];
                  final end = r?.dt('endDate');
                  final days = end == null ? null : Fmt.daysUntil(end);
                  return RecCard(
                    title: w.s('name'),
                    lines: r == null
                        ? ['${w.s('code')} · No Ajeer contract recorded']
                        : ['${r.s('provider')} · ${r.s('contractNo')}', '${Fmt.date(r.dt('startDate'))} → ${Fmt.date(end)}', 'Cost ${Money.sarExact(r.i('cost'))}'],
                    trailing: r == null
                        ? const StatusChip('No contract', color: Colors.grey)
                        : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                            StatusChip(r.s('status')),
                            if (days != null) Padding(padding: const EdgeInsets.only(top: 6), child: StatusChip(days < 0 ? 'Expired' : '$days d', color: days < 0 ? Colors.red : (days <= 30 ? Colors.orange : Colors.green))),
                          ]),
                    onTap: canEdit ? () => _edit(w, r) : null,
                  );
                }(),
            ]);
          },
        ),
      ),
    );
  }
}
