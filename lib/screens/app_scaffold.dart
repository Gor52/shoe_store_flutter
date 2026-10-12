import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../state/auth_notifier.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  List<({IconData icon, String label, String route})> _getDestinations(String role) {
    final dests = [
      (icon: Icons.store, label: 'Каталог', route: '/'),
      (icon: Icons.shopping_cart, label: 'Заказы', route: '/orders'),
      (icon: Icons.person, label: 'Профиль', route: '/profile'),
    ];
    if (role == 'admin' || role == 'manager') {
      dests.add((icon: Icons.admin_panel_settings, label: 'Админка', route: '/admin'));
    }
    return dests;
  }

  int _calculateSelectedIndex(BuildContext context, List<({IconData icon, String label, String route})> dests) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < dests.length; i++) {
      if (location.startsWith(dests[i].route) && dests[i].route != '/') return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    final role = context.watch<AuthNotifier>().userRole;
    final destinations = _getDestinations(role);
    final selectedIndex = _calculateSelectedIndex(context, destinations);

    if (size == ScreenSize.compact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (idx) => context.go(destinations[idx].route),
          destinations: destinations.map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label)).toList(),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (idx) => context.go(destinations[idx].route),
            extended: size == ScreenSize.expanded,
            labelType: size == ScreenSize.expanded ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            destinations: destinations.map((d) => NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label))).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}