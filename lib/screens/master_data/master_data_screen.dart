import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/lookup_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/routes/app_routes.dart';
import '../../models/lookup_models.dart';
import '../../repositories/lookup_repository.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/permission_gate.dart';

/// Master data: Regions, Departments, Commercial Registrations (GOSI).
class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LookupController>();
    return MainShell(
      currentRoute: AppRoutes.masterData,
      title: 'Master Data',
      body: DefaultTabController(
        length: 3,
        child: Column(children: [
          const TabBar(tabs: [Tab(text: 'Regions'), Tab(text: 'Departments'), Tab(text: 'CRs (GOSI)')]),
          Expanded(
            child: TabBarView(children: [
              _Section(
                onAdd: () => _regionDialog(c),
                list: Obx(() => _tiles(c.regions.map((r) => _Row(r.name, r.code, r.active, () => _regionDialog(c, r),
                    (v) => c.saveRegion(RegionModel(id: r.id, name: r.name, code: r.code, active: v)))).toList())),
              ),
              _Section(
                onAdd: () => _deptDialog(c),
                list: Obx(() => _tiles(c.departments.map((d) => _Row(d.name, d.costCenter.isEmpty ? '' : 'Cost center ${d.costCenter}', d.active, () => _deptDialog(c, d),
                    (v) => c.saveDepartment(DepartmentModel(id: d.id, name: d.name, costCenter: d.costCenter, active: v)))).toList())),
              ),
              _Section(
                onAdd: () => _crDialog(c),
                list: Obx(() => _tiles(c.crs.map((r) => _Row(r.branchName, '${r.crNumber} · ${c.regionName(r.regionId)}', r.active, () => _crDialog(c, r),
                    (v) => c.saveCr(CommercialRegistration(id: r.id, regionId: r.regionId, branchName: r.branchName, crNumber: r.crNumber, gosiRef: r.gosiRef, status: r.status, notes: r.notes, active: v)))).toList())),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tiles(List<_Row> rows) {
    if (rows.isEmpty) return const Center(child: Text('Nothing here yet'));
    return PermissionGate(
      permission: AppPermissions.lookupManage,
      fallback: _list(rows, false),
      child: _list(rows, true),
    );
  }

  Widget _list(List<_Row> rows, bool canEdit) => ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = rows[i];
          return ListTile(
            title: Text(r.title, style: TextStyle(fontWeight: FontWeight.w600, color: r.active ? null : Colors.grey)),
            subtitle: r.subtitle.isEmpty ? null : Text(r.subtitle),
            onTap: canEdit ? r.onEdit : null,
            trailing: canEdit ? Switch(value: r.active, onChanged: r.onToggle) : null,
          );
        },
      );

  // ---- dialogs ----
  void _regionDialog(LookupController c, [RegionModel? e]) {
    final name = TextEditingController(text: e?.name), code = TextEditingController(text: e?.code);
    _dialog(e == null ? 'Add Region' : 'Edit Region', {'Name': name, 'Code': code}, () async {
      await c.saveRegion(RegionModel(id: e?.id ?? LookupRepository.slug(name.text), name: name.text.trim(), code: code.text.trim(), active: e?.active ?? true));
    }, required: [name]);
  }

  void _deptDialog(LookupController c, [DepartmentModel? e]) {
    final name = TextEditingController(text: e?.name), cc = TextEditingController(text: e?.costCenter);
    _dialog(e == null ? 'Add Department' : 'Edit Department', {'Name': name, 'Cost center': cc}, () async {
      await c.saveDepartment(DepartmentModel(id: e?.id ?? LookupRepository.slug(name.text), name: name.text.trim(), costCenter: cc.text.trim(), active: e?.active ?? true));
    }, required: [name]);
  }

  void _crDialog(LookupController c, [CommercialRegistration? e]) {
    final branch = TextEditingController(text: e?.branchName), cr = TextEditingController(text: e?.crNumber);
    final gosi = TextEditingController(text: e?.gosiRef), notes = TextEditingController(text: e?.notes);
    String? region = e?.regionId;
    _dialog(e == null ? 'Add Commercial Registration' : 'Edit Commercial Registration',
        {'Branch name': branch, 'CR number': cr, 'GOSI account ref': gosi, 'Notes': notes}, () async {
      await c.saveCr(CommercialRegistration(
          id: e?.id ?? LookupRepository.slug(branch.text), regionId: region!, branchName: branch.text.trim(),
          crNumber: cr.text.trim(), gosiRef: gosi.text.trim(), status: e?.status ?? 'Active', notes: notes.text.trim(), active: e?.active ?? true));
    }, required: [branch, cr], extra: (setState) => DropdownButtonFormField<String>(
          initialValue: region,
          decoration: const InputDecoration(labelText: 'Region'),
          items: c.activeRegions.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
          onChanged: (v) => setState(() => region = v),
        ), canSave: () => region != null);
  }

  void _dialog(String title, Map<String, TextEditingController> fields, Future<void> Function() onSave,
      {List<TextEditingController> required = const [], Widget Function(StateSetter)? extra, bool Function()? canSave}) {
    Get.dialog(StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (extra != null) ...[extra(setState), const SizedBox(height: 10)],
              for (final f in fields.entries) ...[
                TextField(controller: f.value, decoration: InputDecoration(labelText: f.key)),
                const SizedBox(height: 10),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (required.any((c) => c.text.trim().isEmpty) || (canSave != null && !canSave())) {
                Get.snackbar('Missing info', 'Please fill the required fields',
                    backgroundColor: AppColors.danger, colorText: Colors.white);
                return;
              }
              try {
                await onSave();
                Get.back();
              } catch (e) {
                Get.snackbar('Error', '$e', backgroundColor: AppColors.danger, colorText: Colors.white);
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    }));
  }
}

class _Row {
  final String title, subtitle;
  final bool active;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  _Row(this.title, this.subtitle, this.active, this.onEdit, this.onToggle);
}

class _Section extends StatelessWidget {
  final Widget list;
  final VoidCallback onAdd;
  const _Section({required this.list, required this.onAdd});

  @override
  Widget build(BuildContext context) => Column(children: [
        PermissionGate(
          permission: AppPermissions.lookupManage,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add')),
            ),
          ),
        ),
        Expanded(child: list),
      ]);
}
