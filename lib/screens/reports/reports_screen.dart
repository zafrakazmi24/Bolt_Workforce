import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/lookup_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/doc_repo.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/rec_list.dart';

/// Reports: workforce headcount summaries (report.view).
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lookups = Get.find<LookupController>();
    return MainShell(
      currentRoute: AppRoutes.reports,
      title: 'Reports',
      body: RecStream(
        stream: const DocRepo('employees').watch(),
        builder: (context, emps) {
          final active = emps.where((e) => e.s('status') == 'Active').toList();
          Map<String, int> group(String field, String Function(String?) name) {
            final m = <String, int>{};
            for (final e in active) {
              final k = name(e.s(field));
              m[k] = (m[k] ?? 0) + 1;
            }
            return m;
          }

          final byDept = group('departmentId', lookups.departmentName);
          final byRegion = group('regionId', lookups.regionName);
          return ListView(children: [
            Row(children: [
              _stat(context, 'Total employees', '${emps.length}', AppColors.primary),
              const SizedBox(width: 12),
              _stat(context, 'Active', '${active.length}', AppColors.success),
              const SizedBox(width: 12),
              _stat(context, 'Mudad', '${emps.where((e) => e.b('isMudad')).length}', AppColors.secondary),
            ]),
            const SizedBox(height: 20),
            _bars(context, 'Active headcount by department', byDept),
            const SizedBox(height: 16),
            _bars(context, 'Active headcount by region', byRegion),
          ]);
        },
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String v, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: c)),
            Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
          ]),
        ),
      );

  Widget _bars(BuildContext context, String title, Map<String, int> data) {
    final max = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final e in data.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: const TextStyle(fontSize: 13)), Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700))]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: e.value / max, minHeight: 9, backgroundColor: AppColors.primary.withOpacity(.1), valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
              ),
            ]),
          ),
      ]),
    );
  }
}
