import 'package:cloud_firestore/cloud_firestore.dart';
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

/// PDF 9.3 - Company assets: register, assign / transfer / return, history.
class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  static const _repo = DocRepo('assets', scoped: false);
  static const _asg = DocRepo('asset_assignments');
  static const types = ['Laptop', 'Mobile phone', 'Vehicle', 'Tools', 'Uniform / PPE', 'SIM card', 'Other'];

  Future<void> _edit(Rec? r) async {
    final v = await showFormDialog(r == null ? 'New asset' : 'Edit asset', [
      FieldSpec('code', 'Asset code', required: true, initial: r?.s('code')),
      FieldSpec('type', 'Type', type: FT.dropdown, required: true, choices: Choices.opts(types), initial: r?.s('type')),
      FieldSpec('brandModel', 'Brand / model', initial: r?.s('brandModel')),
      FieldSpec('serialNo', 'Serial number', initial: r?.s('serialNo')),
      FieldSpec('purchaseDate', 'Purchase date', type: FT.date, initial: r?.d['purchaseDate']),
      FieldSpec('purchaseValue', 'Purchase value', type: FT.money, initial: r?.d['purchaseValue']),
      FieldSpec('value', 'Current value', type: FT.money, initial: r?.d['value']),
      FieldSpec('status', 'Status', type: FT.dropdown, required: true,
          choices: Choices.opts(['Available', 'Assigned', 'Under Repair', 'Retired']), initial: r?.s('status', 'Available')),
    ]);
    if (v == null) return;
    if (r == null) {
      await _repo.add(v);
    } else {
      await _repo.update(r.id, v, before: r.d);
    }
  }

  /// Assign (or transfer, if already assigned) to an employee.
  Future<void> _assign(Rec a) async {
    final emps = (await const DocRepo('employees').fetch()).where((e) => e.s('status') != 'Offboarded').toList();
    final transfer = a.s('status') == 'Assigned';
    final v = await showFormDialog(transfer ? 'Transfer ${a.s('code')}' : 'Assign ${a.s('code')}', [
      FieldSpec('employee', 'Employee', type: FT.dropdown, required: true, choices: Choices.employees(emps)),
      FieldSpec('issueDate', 'Issue date', type: FT.date, required: true, initial: DateTime.now()),
      const FieldSpec('condition', 'Condition at issue'),
      const FieldSpec('accessories', 'Accessories'),
    ]);
    if (v == null) return;
    final emp = emps.firstWhere((e) => e.id == v['employee']);
    final batch = DocRepo.db.batch();
    if (transfer) {
      final open = await _asg.fetch(where: {'assetId': a.id});
      for (final o in open.where((o) => o.dt('returnDate') == null)) {
        batch.update(_asg.ref.doc(o.id), {'returnDate': Timestamp.now(), 'returnCondition': 'Transferred'});
      }
    }
    batch.set(_asg.ref.doc(), {
      ...Choices.empRef(emp), 'assetId': a.id, 'assetCode': a.s('code'), 'assetType': a.s('type'),
      'issueDate': v['issueDate'], 'condition': v['condition'] ?? '', 'accessories': v['accessories'] ?? '', 'returnDate': null,
    });
    batch.update(_repo.ref.doc(a.id), {'status': 'Assigned', 'assignedToId': emp.id, 'assignedToName': emp.s('name')});
    await batch.commit();
    await DocRepo.audit('assets', a.id, transfer ? 'transfer' : 'assign', newData: {'employee': emp.s('name')});
  }

  Future<void> _return(Rec a) async {
    final v = await showFormDialog('Return ${a.s('code')}', [
      FieldSpec('returnDate', 'Return date', type: FT.date, required: true, initial: DateTime.now()),
      const FieldSpec('returnCondition', 'Condition at return', required: true),
      const FieldSpec('notes', 'Notes / accessories returned', type: FT.multiline),
    ], saveLabel: 'Return');
    if (v == null) return;
    final open = (await _asg.fetch(where: {'assetId': a.id})).where((o) => o.dt('returnDate') == null);
    final batch = DocRepo.db.batch();
    for (final o in open) {
      batch.update(_asg.ref.doc(o.id), {'returnDate': v['returnDate'], 'returnCondition': v['returnCondition'], 'returnNotes': v['notes'] ?? ''});
    }
    batch.update(_repo.ref.doc(a.id), {'status': 'Available', 'assignedToId': null, 'assignedToName': null});
    await batch.commit();
    await DocRepo.audit('assets', a.id, 'return');
  }

  void _details(Rec a) {
    final canAssign = Scope.can(AppPermissions.assetAssign);
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(Get.context!).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${a.s('code')} · ${a.s('type')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            KV('Brand / model', a.s('brandModel')),
            KV('Serial no.', a.s('serialNo')),
            KV('Purchased', '${Fmt.date(a.dt('purchaseDate'))} · ${Money.sarExact(a.i('purchaseValue'))}'),
            KV('Current value', Money.sarExact(a.i('value'))),
            KV('Status', a.s('status')),
            KV('Assigned to', a.s('assignedToName')),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (canAssign && (a.s('status') == 'Available' || a.s('status') == 'Assigned'))
                ElevatedButton(onPressed: () { Get.back(); _assign(a); }, child: Text(a.s('status') == 'Assigned' ? 'Transfer' : 'Assign')),
              if (canAssign && a.s('status') == 'Assigned') OutlinedButton(onPressed: () { Get.back(); _return(a); }, child: const Text('Return')),
              if (Scope.can(AppPermissions.assetUpdate)) ...[
                OutlinedButton(onPressed: () { Get.back(); _edit(a); }, child: const Text('Edit')),
                if (a.s('status') != 'Assigned') OutlinedButton(onPressed: () async { Get.back(); await _repo.softDelete(a.id); }, child: const Text('Delete')),
              ],
            ]),
            const Divider(height: 28),
            const Text('Issue / return history', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(
              height: 160,
              child: RecStream(
                stream: _asg.watch(where: {'assetId': a.id}),
                builder: (c, rows) {
                  rows.sort((x, y) => (y.dt('issueDate') ?? DateTime(2000)).compareTo(x.dt('issueDate') ?? DateTime(2000)));
                  return ListView(children: [
                    for (final r in rows)
                      ListTile(
                        dense: true,
                        title: Text(r.s('employeeName')),
                        subtitle: Text('Issued ${Fmt.date(r.dt('issueDate'))} (${r.s('condition')})${r.dt('returnDate') == null ? '' : '\nReturned ${Fmt.date(r.dt('returnDate'))} (${r.s('returnCondition')})'}'),
                      ),
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
      currentRoute: AppRoutes.assets,
      title: 'Company Assets',
      floatingActionButton: Scope.can(AppPermissions.assetCreate) ? FloatingActionButton(onPressed: () => _edit(null), child: const Icon(Icons.add)) : null,
      body: RecList(
        stream: _repo.watch(),
        emptyText: 'No assets registered',
        sort: (a, b) => a.s('code').compareTo(b.s('code')),
        searchText: (a) => '${a.s('code')} ${a.s('type')} ${a.s('brandModel')} ${a.s('serialNo')} ${a.s('assignedToName')}',
        filters: {for (final s in ['Available', 'Assigned', 'Under Repair', 'Retired']) s: (a) => a.s('status') == s},
        itemBuilder: (context, a) => RecCard(
          title: '${a.s('code')} · ${a.s('type')}',
          lines: [a.s('brandModel'), if (a.s('assignedToName').isNotEmpty) 'With ${a.s('assignedToName')}'],
          trailing: StatusChip(a.s('status')),
          onTap: () => _details(a),
        ),
      ),
    );
  }
}
