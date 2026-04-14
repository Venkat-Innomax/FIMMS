import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../services/mock_auth_service.dart';

// Shared module badge shown in app bars
class ModuleBadge extends ConsumerWidget {
  const ModuleBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(moduleProvider);
    final isHostel = module == AppModule.hostel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHostel ? Icons.house_outlined : Icons.local_hospital_outlined,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            module.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class NavItem {
  final String label;
  final IconData icon;
  final String route;
  const NavItem({required this.label, required this.icon, required this.route});
}

/// Scaffold that renders a top bar plus an adaptive navigation surface:
/// * Mobile  → BottomNavigationBar
/// * Tablet+ → left NavigationRail
/// Designed for multi-destination shells (Field Officer home tabs).
class ResponsiveScaffold extends ConsumerWidget {
  final String title;
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.items,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = Responsive.isMobile(context);
    final user = ref.watch(authStateProvider);

    // Smooth fade when switching between tab bodies.
    final animatedBody = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: ValueKey(currentIndex),
        child: body,
      ),
    );

    final signOut = IconButton(
      tooltip: 'Sign out',
      icon: const Icon(Icons.logout),
      onPressed: () {
        ref.read(authStateProvider.notifier).signOut();
        context.go('/login');
      },
    );

    final appBar = AppBar(
      title: Text(title),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        const ModuleBadge(),
        const SizedBox(width: 4),
        ...?actions,
        signOut,
      ],
    );

    if (isMobile) {
      return Scaffold(
        appBar: appBar,
        body: animatedBody,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width >= 1280,
            minExtendedWidth: 220,
            backgroundColor: FimmsColors.surfaceAlt,
            indicatorColor: FimmsColors.primary.withValues(alpha: 0.12),
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            leading: const SizedBox(height: 12),
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: animatedBody),
        ],
      ),
    );
  }
}

/// Lightweight scaffold for single-page dashboards that don't need nav rail.
class DashboardScaffold extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Widget body;
  final List<Widget>? actions;

  const DashboardScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.role.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const ModuleBadge(),
          const SizedBox(width: 4),
          ...?actions,
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: body,
    );
  }
}

/// Simple title used in full-screen placeholders.
class FimmsBrandMark extends StatelessWidget {
  final double fontSize;
  const FimmsBrandMark({super.key, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: fontSize + 4,
          decoration: BoxDecoration(
            color: FimmsColors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: FimmsColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
