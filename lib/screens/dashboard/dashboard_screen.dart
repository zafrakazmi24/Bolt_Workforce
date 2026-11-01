import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/lookup_controller.dart';
import '../../controllers/permission_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/routes/app_routes.dart';
import '../../models/dashboard_data.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/role_badge.dart';

const _gold = Color(0xFFB8893B);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DashboardController());
    return MainShell(
      currentRoute: AppRoutes.dashboard,
      title: 'Dashboard',
      actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: c.load)],
      body: RefreshIndicator(
        onRefresh: c.load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Obx(() => _content(context, c)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, DashboardController c) {
    final d = c.data.value;
    final user = Get.find<AuthController>().currentUser.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text('Welcome, ${user?.name ?? ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        RoleBadge(role: user?.role ?? '', fontSize: 11),
      ]),
      const SizedBox(height: 14),
      _filters(c),
      const SizedBox(height: 16),
      if (c.error.value.isNotEmpty)
        _message(context, c.error.value, AppColors.danger)
      else if (d == null)
        const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
      else ...[
        _kpiGrid(context, c, d),
        const SizedBox(height: 16),
        _crCard(context),
        if (c.canCost && d.costByDepartment.isNotEmpty) ...[
          const SizedBox(height: 16),
          _BarCard(
            title: 'Fully-Loaded Cost by Department',
            note: 'whole company — filters don\'t narrow this compare view',
            entries: _named(d.costByDepartment, Get.find<LookupController>().departmentName),
            format: Money.sar,
          ),
        ],
        if (c.canEmployees && d.headcountByRegion.isNotEmpty) ...[
          const SizedBox(height: 16),
          _BarCard(
            title: 'Active Headcount by Region',
            note: 'whole company — filters don\'t narrow this compare view',
            entries: _named(d.headcountByRegion, Get.find<LookupController>().regionName),
            format: (v) => '$v',
            color: AppColors.secondary,
          ),
        ],
        if (c.canFinance) ...[
          const SizedBox(height: 16),
          _paidVsOutstanding(context, d),
        ],
        if (c.canExpiry) ...[
          const SizedBox(height: 16),
          _expiryCard(context, d),
        ],
        const SizedBox(height: 12),
        Text('Last updated ${_hhmm(d.loadedAt)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 24),
      ],
    ]);
  }

  // ---------------- filters ----------------
  Widget _filters(DashboardController c) {
    final lookups = Get.find<LookupController>();
    return Obx(() {
      final lockR = c.lockedRegionId, lockD = c.lockedDepartmentId;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        _Dropdown(
          label: 'Region',
          value: lockR ?? c.regionId.value,
          allLabel: 'All Regions',
          options: {for (final r in lookups.activeRegions) r.id: r.name},
          enabled: lockR == null,
          onChanged: c.setRegion,
        ),
        _Dropdown(
          label: 'Department',
          value: lockD ?? c.departmentId.value,
          allLabel: 'All Departments',
          options: {for (final d in lookups.activeDepartments) d.id: d.name},
          enabled: lockD == null,
          onChanged: c.setDepartment,
        ),
        _Dropdown(
          label: 'Month',
          value: c.month.value,
          allLabel: 'All Months',
          options: {for (final m in c.months) m: m},
          onChanged: c.setMonth,
        ),
      ]);
    });
  }

  // ---------------- KPI cards ----------------
  Widget _kpiGrid(BuildContext context, DashboardController c, DashboardData d) {
    final cards = <_Kpi>[
      if (c.canEmployees) ...[
        _Kpi('TOTAL EMPLOYEES', '${d.total}', '${d.active} active · ${d.temporary} temporary · ${d.offboarded} offboarded'),
        _Kpi('ACTIVE HEADCOUNT', '${d.active}', '${d.offboarded} offboarded not counted'),
        _Kpi('MUDAD REGISTERED', '${d.mudad}', 'of ${d.total} total employees'),
        _Kpi('NON-MUDAD (AJEER)', '${d.ajeer}', 'not Mudad-registered (Ajeer tracker)'),
      ],
      if (c.canCost)
        _Kpi('FULLY-LOADED MONTHLY COST', Money.sar(d.fullyLoadedMinor),
            'active roster — basic + allowances + GOSI + EOSB + insurance'),
      if (c.canFinance) ...[
        _Kpi('ACTUALLY PAID', Money.sar(d.paidMinor), '${d.paidRows} fully paid, ${d.openRows} pending/partial'),
        _Kpi('OUTSTANDING PAY', Money.sar(d.outstandingMinor), c.month.value == null ? 'all months' : c.month.value!),
        _Kpi('PENDING EOSB PAYABLE', Money.sar(d.eosbPendingMinor), 'unsettled end-of-service'),
        _Kpi('OUTSTANDING STAFF LOANS', Money.sar(d.loansMinor), 'advances still being recovered'),
      ],
      if (c.canExpiry)
        _Kpi('EXPIRY RED FLAGS', '${d.redFlags}', 'iqama / permit / insurance — expired or due soon',
            accent: AppColors.danger, valueColor: AppColors.danger),
      if (c.canEmployees)
        _Kpi('CONTRACT STATUS WATCH', '${d.contractWatch}', 'pending transfer, cancelled, renewal…'),
    ];
    if (cards.isEmpty) {
      return _message(context, 'Your role has no dashboard widgets assigned.', Colors.grey);
    }
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth >= 1100 ? 4 : (box.maxWidth >= 700 ? 3 : 2);
      const gap = 12.0;
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final k in cards) SizedBox(width: w, child: _KpiCard(k)),
      ]);
    });
  }

  // ---------------- commercial registrations ----------------
  Widget _crCard(BuildContext context) {
    final lookups = Get.find<LookupController>();
    final scopeRegion = Get.find<PermissionController>().scopeRegionId;
    return Obx(() {
      final crs = lookups.crs.where((r) => r.active && (scopeRegion == null || r.regionId == scopeRegion)).toList();
      if (crs.isEmpty) return const SizedBox.shrink();
      return _Card(
        title: 'Commercial Registrations (GOSI)',
        note: 'Bolt runs ${crs.length} separate CR${crs.length == 1 ? '' : 's'} — each pays its own GOSI',
        child: Wrap(spacing: 28, runSpacing: 12, children: [
          for (final r in crs)
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(r.branchName, style: TextStyle(fontSize: 10.5, color: Colors.grey[600], letterSpacing: .4)),
              const SizedBox(height: 3),
              SelectableText(r.crNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ]),
        ]),
      );
    });
  }

  // ---------------- paid vs outstanding ----------------
  Widget _paidVsOutstanding(BuildContext context, DashboardData d) {
    final total = d.paidMinor + d.outstandingMinor;
    final paidFlex = total == 0 ? 1 : (d.paidMinor * 1000 ~/ total).clamp(0, 1000);
    return _Card(
      title: 'Paid vs Outstanding Payroll',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: total == 0
                ? Container(color: Colors.grey.withOpacity(.25))
                : Row(children: [
                    Expanded(flex: paidFlex, child: Container(color: AppColors.success)),
                    Expanded(flex: 1000 - paidFlex, child: Container(color: AppColors.warning)),
                  ]),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 20, children: [
          _legend(AppColors.success, 'Paid ${Money.sar(d.paidMinor)}'),
          _legend(AppColors.warning, 'Outstanding ${Money.sar(d.outstandingMinor)}'),
        ]),
      ]),
    );
  }

  // ---------------- expiry buckets ----------------
  Widget _expiryCard(BuildContext context, DashboardData d) {
    final b = d.expiryBuckets;
    Widget chip(String label, int v, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${v}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ]),
        );
    return _Card(
      title: 'Upcoming Expiries',
      child: Wrap(spacing: 10, runSpacing: 10, children: [
        chip('Expired', b['expired'] ?? 0, AppColors.danger),
        chip('≤ 7 days', b['d7'] ?? 0, const Color(0xFFEA580C)),
        chip('8–30 days', b['d30'] ?? 0, AppColors.warning),
        chip('31–60 days', b['d60'] ?? 0, AppColors.secondary),
        chip('61–90 days', b['d90'] ?? 0, AppColors.primary),
      ]),
    );
  }

  // ---------------- helpers ----------------
  List<MapEntry<String, int>> _named(Map<String, int> m, String Function(String?) name) {
    final list = m.entries.map((e) => MapEntry(name(e.key), e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  Widget _legend(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(t, style: const TextStyle(fontSize: 12.5)),
      ]);

  Widget _message(BuildContext context, String text, Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ======================= small widgets =======================

class _Kpi {
  final String label, value, sub;
  final Color accent, valueColor;
  _Kpi(this.label, this.value, this.sub, {this.accent = _gold, this.valueColor = AppColors.primary});
}

class _KpiCard extends StatelessWidget {
  final _Kpi k;
  const _KpiCard(this.k);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: k.accent, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k.label, style: TextStyle(fontSize: 10, letterSpacing: .6, fontWeight: FontWeight.w700, color: Colors.grey[600])),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(k.value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: k.valueColor)),
        ),
        const SizedBox(height: 6),
        Text(k.sub, style: TextStyle(fontSize: 10.5, color: Colors.grey[600])),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? note;
  final Widget child;
  const _Card({required this.title, this.note, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(note!, style: TextStyle(fontSize: 10.5, color: Colors.grey[500])),
          ],
          const SizedBox(height: 14),
          child,
        ]),
      );
}

class _BarCard extends StatelessWidget {
  final String title;
  final String? note;
  final List<MapEntry<String, int>> entries;
  final String Function(int) format;
  final Color color;
  const _BarCard({required this.title, this.note, required this.entries, required this.format, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    final max = entries.fold<int>(0, (m, e) => e.value > m ? e.value : m);
    return _Card(
      title: title,
      note: note,
      child: Column(children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(width: 110, child: Text(e.key, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
              Expanded(
                child: LayoutBuilder(builder: (_, box) => Stack(children: [
                  Container(height: 12, decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(6))),
                  Container(
                    height: 12,
                    width: max == 0 ? 0 : box.maxWidth * e.value / max,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                  ),
                ])),
              ),
              const SizedBox(width: 10),
              Text(format(e.value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
      ]),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label, allLabel;
  final String? value;
  final Map<String, String> options;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  const _Dropdown({
    required this.label, required this.allLabel, required this.value,
    required this.options, required this.onChanged, this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = options.containsKey(value) ? value : null;
    return SizedBox(
      width: 170,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            isExpanded: true,
            isDense: true,
            value: safeValue,
            onChanged: enabled ? onChanged : null,
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(allLabel, overflow: TextOverflow.ellipsis)),
              for (final e in options.entries)
                DropdownMenuItem<String?>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}
