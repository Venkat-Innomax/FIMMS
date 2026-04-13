import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../services/mock_auth_service.dart';
import 'pages/facility_master_page.dart';
import 'pages/user_management_page.dart';
import 'pages/form_builder_page.dart';
import 'pages/assignment_page.dart';
import 'pages/assign_inspection_page.dart';
import 'pages/admin_grievance_page.dart';
import 'pages/sla_monitor_page.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedIndex = 0;

  static const _sections = [
    _NavItem(icon: Icons.business, label: 'Facilities'),
    _NavItem(icon: Icons.people, label: 'Users'),
    _NavItem(icon: Icons.dynamic_form, label: 'Forms'),
    _NavItem(icon: Icons.assignment, label: 'Assignments'),
    _NavItem(icon: Icons.assignment_add, label: 'Assign Inspection'),
    _NavItem(icon: Icons.timer, label: 'SLA'),
    _NavItem(icon: Icons.report_problem, label: 'Grievances'),
  ];

  static const _pages = <Widget>[
    FacilityMasterPage(),
    UserManagementPage(),
    FormBuilderPage(),
    AssignmentPage(),
    AssignInspectionPage(),
    SlaMonitorPage(),
    AdminGrievancePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        color: FimmsColors.primary, size: 28),
                    const SizedBox(height: 4),
                    Text('Admin',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: FimmsColors.primary)),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => ref
                          .read(authStateProvider.notifier)
                          .signOut(),
                    ),
                  ),
                ),
              ),
              destinations: [
                for (final s in _sections)
                  NavigationRailDestination(
                    icon: Icon(s.icon),
                    label: Text(s.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: _pages[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_sections[_selectedIndex].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          for (final s in _sections)
            NavigationDestination(icon: Icon(s.icon), label: s.label),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
