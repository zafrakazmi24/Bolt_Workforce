import 'package:flutter/material.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/data/doc_repo.dart';
import '../../core/data/rec.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/choices.dart';
import '../../core/utils/scope.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/rec_list.dart';

/// PDF 9.4 - Trash: soft-deleted records can be restored or (by policy) purged.
/// Payment history and audit logs are never deletable here.
class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});
  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  static const _cols = {
    'employees': 'Employees',
    'loans': 'Loans & Advances',
    'eosb': 'EOSB',
    'expenses': 'Expenses',
    'assets': 'Assets',
    'compliance_costs': 'Compliance Costs',
    'ajeer_records': 'Ajeer records',
  };
  String _col = 'employees';

  String _title(Rec r) {
    for (final k in ['name', 'employeeName', 'code', 'type', 'category']) {
      if (r.s(k).isNotEmpty) return r.s(k);
    }
    return r.id;
  }

  @override
  Widget build(BuildContext context) {
    final repo = DocRepo(_col, scoped: _col != 'assets');
    return MainShell(
      currentRoute: AppRoutes.trash,
      title: 'Trash',
      body: Column(children: [
        DropdownButtonFormField<String>(
          initialValue: _col,
          decoration: const InputDecoration(labelText: 'Record type', isDense: true),
          items: [for (final e in _cols.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: (v) => setState(() => _col = v ?? _col),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RecList(
            key: ValueKey(_col),
            stream: repo.watch(deleted: true),
            emptyText: 'Trash is empty',
            searchText: _title,
            itemBuilder: (context, r) => RecCard(
              title: _title(r),
              lines: [if (r.s('code').isNotEmpty) r.s('code'), r.id],
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (Scope.can(AppPermissions.trashRestore))
                  IconButton(tooltip: 'Restore', icon: const Icon(Icons.restore_rounded), onPressed: () async {
                    await repo.restore(r.id);
                    toast('Restored', _title(r));
                  }),
                if (Scope.can(AppPermissions.trashPurge))
                  IconButton(tooltip: 'Delete permanently', icon: const Icon(Icons.delete_forever_rounded, color: Colors.red), onPressed: () async {
                    if (await confirm('Delete permanently', 'This cannot be undone.', yes: 'Delete forever')) await repo.purge(r.id);
                  }),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
