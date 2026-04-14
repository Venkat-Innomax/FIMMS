import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../services/mock_auth_service.dart';
import '../collector_dash/collector_dashboard_page.dart';
import 'widgets/facility_list.dart';
import 'widgets/mandal_escalation_page.dart';
import 'widgets/mandal_grievances.dart';
import 'widgets/mandal_reinspection_page.dart';
import 'widgets/mandal_reports_page.dart';
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
  // Drawer pages: 5=Reinspection, 6=Escalation, 7=Reports
  int _drawerPage = -1; // -1 = not in drawer mode

  static const _drawerTitles = ['Reinspection', 'Escalations', 'Reports'];

  @override
  Widget build(BuildContext context) {
    final bottomPages = <Widget>[
      CollectorDashboardPage(
        mandalScopeId: widget.mandalId,
        showMandalFilter: false,
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text('Inspections'),
          actions: [_menuButton(context), _logoutButton()],
        ),
        body: PendingInspections(mandalId: widget.mandalId),
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text('Facility List'),
          actions: [_menuButton(context), _logoutButton()],
        ),
        body: FacilityListView(mandalId: widget.mandalId),
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text('Officer Load'),
          actions: [_menuButton(context), _logoutButton()],
        ),
        body: OfficerLoad(mandalId: widget.mandalId),
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text('Grievances'),
          actions: [_menuButton(context), _logoutButton()],
        ),
        body: MandalGrievances(mandalId: widget.mandalId),
      ),
    ];

    final drawerPages = <Widget>[
      Scaffold(
        appBar: AppBar(
          title: const Text('Reinspection Requests'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _drawerPage = -1),
          ),
          actions: [_logoutButton()],
        ),
        body: MandalReinspectionPage(mandalId: widget.mandalId),
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text('Escalations'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _drawerPage = -1),
          ),
          actions: [_logoutButton()],
        ),
        body: MandalEscalationPage(mandalId: widget.mandalId),
      ),
      Scaffold(
        appBar: AppBar(
          title: const Text('Mandal Reports'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _drawerPage = -1),
          ),
          actions: [_logoutButton()],
        ),
        body: MandalReportsPage(mandalId: widget.mandalId),
      ),
    ];

    if (_drawerPage >= 0 && _drawerPage < drawerPages.length) {
      return drawerPages[_drawerPage];
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: bottomPages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(
              icon: Icon(Icons.fact_check), label: 'Inspections'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Facilities'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart), label: 'Load'),
          NavigationDestination(
              icon: Icon(Icons.report_problem), label: 'Grievances'),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'More',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: FimmsColors.textMuted,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(),
              for (int i = 0; i < _drawerTitles.length; i++)
                ListTile(
                  leading: Icon(_drawerIcon(i), color: FimmsColors.primary),
                  title: Text(_drawerTitles[i],
                      style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _drawerPage = i);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _drawerIcon(int i) {
    return switch (i) {
      0 => Icons.refresh,
      1 => Icons.north_east,
      _ => Icons.bar_chart_outlined,
    };
  }

  Widget _menuButton(BuildContext context) => Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      );

  Widget _logoutButton() => IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () => ref.read(authStateProvider.notifier).signOut(),
      );
}
