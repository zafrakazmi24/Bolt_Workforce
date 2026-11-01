import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_permissions.dart';
import '../../core/data/doc_repo.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/fmt.dart';
import '../../core/utils/scope.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/rec_list.dart';

class _N {
  final IconData icon;
  final Color color;
  final String title, sub;
  final String route;
  _N(this.icon, this.color, this.title, this.sub, this.route);
}

/// In-app notifications: expiry, approval and payment alerts, limited to what
/// the user is permitted to see (PDF screen list: Notifications).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<_N>> _future = _load();

  Future<List<_N>> _load() async {
    final out = <_N>[];
    if (Scope.can(AppPermissions.expiryView)) {
      final docs = await const DocRepo('employee_documents').fetch();
      var expired = 0, soon = 0;
      for (final d in docs) {
        final e = d.dt('expiryDate');
        if (e == null) continue;
        final days = Fmt.daysUntil(e);
        if (days < 0) {
          expired++;
        } else if (days <= AppConfig.expiryWarningDays) {
          soon++;
        }
      }
      if (expired > 0) out.add(_N(Icons.error_rounded, Colors.red, '$expired document(s) expired', 'Open Expiry Alerts', AppRoutes.expiry));
      if (soon > 0) out.add(_N(Icons.schedule_rounded, Colors.orange, '$soon document(s) expiring within ${AppConfig.expiryWarningDays} days', 'Open Expiry Alerts', AppRoutes.expiry));
    }
    if (Scope.can(AppPermissions.loanApprove)) {
      final n = (await const DocRepo('loans').fetch()).where((l) => l.s('status') == 'Pending').length;
      if (n > 0) out.add(_N(Icons.account_balance_wallet_rounded, Colors.blue, '$n loan/advance request(s) awaiting approval', 'Open Loans', AppRoutes.loans));
    }
    if (Scope.can(AppPermissions.expenseApprove)) {
      final n = (await const DocRepo('expenses').fetch()).where((l) => l.s('status') == 'Submitted').length;
      if (n > 0) out.add(_N(Icons.receipt_long_rounded, Colors.blue, '$n expense(s) awaiting approval', 'Open Expenses', AppRoutes.expenses));
    }
    if (Scope.can(AppPermissions.eosbApprove)) {
      final n = (await const DocRepo('eosb').fetch()).where((l) => l.s('status') == 'Reviewed').length;
      if (n > 0) out.add(_N(Icons.work_history_rounded, Colors.blue, '$n EOSB settlement(s) awaiting approval', 'Open EOSB', AppRoutes.eosb));
    }
    if (Scope.can(AppPermissions.paymentCreate)) {
      final n = (await const DocRepo('payroll_ledger').fetch()).where((l) => l.s('status') == 'Unpaid' || l.s('status') == 'Partial').length;
      if (n > 0) out.add(_N(Icons.payments_rounded, Colors.teal, '$n payroll row(s) unpaid or partially paid', 'Open Ledger', AppRoutes.ledger));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.notifications,
      title: 'Notifications',
      actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => setState(() => _future = _load()))],
      body: FutureBuilder<List<_N>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.isEmpty) return const Center(child: Text('You are all caught up', style: TextStyle(color: Colors.grey)));
          return ListView(children: [
            for (final n in snap.data!)
              RecCard(
                title: n.title,
                lines: [n.sub],
                trailing: Icon(n.icon, color: n.color),
                onTap: () => Get.toNamed(n.route),
              ),
          ]);
        },
      ),
    );
  }
}
