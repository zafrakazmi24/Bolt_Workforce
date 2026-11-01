import 'package:flutter/material.dart';
import 'app_sidebar.dart';

/// Bonus Feature - Responsive Layout.
/// Wide screens -> permanent sidebar. Narrow (mobile) screens -> Drawer.
class MainShell extends StatelessWidget {
  final String currentRoute;
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const MainShell({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      drawer: isWide ? null : Drawer(child: AppSidebar(currentRoute: currentRoute)),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (isWide) AppSidebar(currentRoute: currentRoute),
          if (isWide) const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
