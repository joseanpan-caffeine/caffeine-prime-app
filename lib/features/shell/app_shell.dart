import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';

/// Casca com a barra de abas (Início, Rotina, Prime IA, Perfil).
/// Abas de engajamento respeitam as feature flags de GET /config.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool routineOn = ref.watch(appConfigValueProvider).feature('routine');
    final bool assistantOn = ref.watch(appConfigValueProvider).feature('assistant');

    // Índices dos branches: 0 home, 1 rotina, 2 assistente, 3 perfil.
    final List<_Tab> tabs = <_Tab>[
      const _Tab(0, 'Início', Icons.home_outlined, Icons.home_rounded),
      if (routineOn) const _Tab(1, 'Rotina', Icons.check_circle_outline_rounded, Icons.check_circle_rounded),
      if (assistantOn) const _Tab(2, 'Prime IA', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
      const _Tab(3, 'Perfil', Icons.person_outline_rounded, Icons.person_rounded),
    ];
    int selected = tabs.indexWhere((t) => t.branch == navigationShell.currentIndex);
    if (selected < 0) selected = 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (int index) {
          final int branch = tabs[index].branch;
          navigationShell.goBranch(branch, initialLocation: branch == navigationShell.currentIndex);
        },
        destinations: tabs
            .map(
              (t) => NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selectedIcon), label: t.label),
            )
            .toList(),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.branch, this.label, this.icon, this.selectedIcon);

  final int branch;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
