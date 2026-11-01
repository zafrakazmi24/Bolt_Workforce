import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/data/doc_repo.dart';
import '../../core/data/rec.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/fmt.dart';
import '../../core/utils/scope.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/rec_list.dart';

class _Item {
  final String employeeId, name, kind, number;
  final DateTime expiry;
  final int days;
  _Item(this.employeeId, this.name, this.kind, this.number, this.expiry) : days = Fmt.daysUntil(expiry);
}

/// PDF 8 - Expiry alerts: Iqama, passport, permit, insurance, Mudad,
/// Ajeer contracts and employment contracts, grouped by severity.
class ExpiryScreen extends StatefulWidget {
  const ExpiryScreen({super.key});
  @override
  State<ExpiryScreen> createState() => _ExpiryScreenState();
}

class _ExpiryScreenState extends State<ExpiryScreen> {
  late Future<List<_Item>> _future = _load();

  Future<List<_Item>> _load() async {
    final emps = Scope.can(AppPermissions.employeeView) ? await const DocRepo('employees').fetch() : <Rec>[];
    final empById = {for (final e in emps) e.id: e};
    bool offboarded(String id) => empById[id]?.s('status') == 'Offboarded';
    final items = <_Item>[];

    for (final d in await const DocRepo('employee_documents').fetch()) {
      final exp = d.dt('expiryDate');
      if (exp == null || offboarded(d.s('employeeId'))) continue;
      items.add(_Item(d.s('employeeId'), d.s('employeeName', empById[d.s('employeeId')]?.s('name') ?? '-'), d.s('type'), d.s('number'), exp));
    }
    if (Scope.can(AppPermissions.ajeerView)) {
      for (final a in await const DocRepo('ajeer_records').fetch()) {
        final exp = a.dt('endDate');
        if (exp == null || offboarded(a.s('employeeId'))) continue;
        items.add(_Item(a.s('employeeId'), a.s('employeeName'), 'Ajeer contract', a.s('contractNo'), exp));
      }
    }
    for (final e in emps) {
      final exp = e.dt('contractEnd');
      if (exp == null || e.s('status') == 'Offboarded') continue;
      items.add(_Item(e.id, e.s('name'), 'Employment contract', '', exp));
    }
    items.sort((a, b) => a.days.compareTo(b.days));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.expiry,
      title: 'Expiry Alerts',
      actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => setState(() => _future = _load()))],
      body: FutureBuilder<List<_Item>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}', style: const TextStyle(color: AppColors.danger)));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!;
          final groups = <String, List<_Item>>{
            'Expired': all.where((i) => i.days < 0).toList(),
            '7 days': all.where((i) => i.days >= 0 && i.days <= 7).toList(),
            '30 days': all.where((i) => i.days > 7 && i.days <= 30).toList(),
            '60+ days': all.where((i) => i.days > 30 && i.days <= 90).toList(),
          };
          return DefaultTabController(
            length: groups.length,
            child: Column(children: [
              TabBar(tabs: [for (final g in groups.entries) Tab(text: '${g.key} (${g.value.length})')]),
              Expanded(
                child: TabBarView(children: [
                  for (final g in groups.entries)
                    g.value.isEmpty
                        ? const Center(child: Text('Nothing here', style: TextStyle(color: Colors.grey)))
                        : ListView(padding: const EdgeInsets.only(top: 12), children: [
                            for (final i in g.value)
                              RecCard(
                                title: i.name,
                                lines: ['${i.kind} ${i.number}', 'Expires ${Fmt.date(i.expiry)}'],
                                trailing: StatusChip(i.days < 0 ? '${-i.days} d ago' : '${i.days} d',
                                    color: i.days < 0 ? Colors.red : (i.days <= 7 ? Colors.deepOrange : (i.days <= 30 ? Colors.orange : Colors.blue))),
                                onTap: Scope.can(AppPermissions.employeeView)
                                    ? () => Get.toNamed(AppRoutes.employeeDetails, arguments: i.employeeId)
                                    : null,
                              ),
                          ]),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}
