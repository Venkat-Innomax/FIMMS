import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/mock_auth_service.dart';
import '../collector_dash/collector_dashboard_page.dart';
import 'widgets/facility_list.dart';
import 'widgets/officer_load.dart';
import 'widgets/pending_inspections.dart';

/// Mandal Officer dashboard. Bottom navigation with 4 views:
/// 1. GIS Map — reuses CollectorDashboardPage scoped to this mandal
/// 2. Pending — facilities due for inspection
/// 3. Facilities — sortable list view
/// 4. Officer Load — workload distribution
class MandalDashboardPage extends ConsumerStatefulWidget {
  final String mandalId;
  const MandalDashboardPage({super.key, required this.mandalId});

  @override
  ConsumerState<MandalDashboardPage> createState() =>
      _MandalDashboardPageState();
}

class _MandalDashboardPageState extends ConsumerState<MandalDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      CollectorDashboardPage(
        mandalScopeId: widget.mandalId,
        showMandalFilter: false,
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text('Pending Inspections'),
          actions: [_logoutButton()],
        ),
        body: PendingInspections(mandalId: widget.mandalId),
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text('Facility List'),
          actions: [_logoutButton()],
        ),
        body: FacilityListView(mandalId: widget.mandalId),
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text('Officer Load'),
          actions: [_logoutButton()],
        ),
        body: OfficerLoad(mandalId: widget.mandalId),
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(
              icon: Icon(Icons.pending_actions), label: 'Pending'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Facilities'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart), label: 'Load'),
        ],
      ),
    );
  }

  Widget _logoutButton() => IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () => ref.read(authStateProvider.notifier).signOut(),
      );
}
