import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../data/repositories/facility_repository.dart';
import '../../models/complaint.dart';
import '../../models/facility.dart';
import '../../services/mock_auth_service.dart';
import 'widgets/intake_queue.dart';

class GrievanceAdminPage extends ConsumerStatefulWidget {
  const GrievanceAdminPage({super.key});

  @override
  ConsumerState<GrievanceAdminPage> createState() =>
      _GrievanceAdminPageState();
}

class _GrievanceAdminPageState extends ConsumerState<GrievanceAdminPage> {
  int _selectedIndex = 0;

  static const _sections = [
    _NavItem(icon: Icons.inbox, label: 'Inbox'),
    _NavItem(icon: Icons.pending, label: 'In Progress'),
    _NavItem(icon: Icons.north_east, label: 'Escalated'),
    _NavItem(icon: Icons.check_circle, label: 'Resolved'),
  ];

  @override
  Widget build(BuildContext context) {
    final complaints = ref.watch(complaintListProvider);
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    Widget body;
    if (complaints.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final facilities = facilitiesAsync.valueOrNull ?? <Facility>[];
      final facilityMap = {for (final f in facilities) f.id: f};

      final filtered = switch (_selectedIndex) {
        0 => complaints
            .where((c) =>
                c.status == ComplaintStatus.submitted ||
                c.status == ComplaintStatus.underReview)
            .toList(),
        1 => complaints
            .where((c) =>
                c.status == ComplaintStatus.assigned ||
                c.status == ComplaintStatus.inProgress)
            .toList(),
        2 => complaints
            .where((c) =>
                c.status == ComplaintStatus.escalatedToMandal ||
                c.status == ComplaintStatus.escalatedToDistrict ||
                c.status == ComplaintStatus.inspectionRequested ||
                c.status == ComplaintStatus.inspectionAssigned)
            .toList(),
        3 => complaints
            .where((c) =>
                c.status == ComplaintStatus.resolved ||
                c.status == ComplaintStatus.closed)
            .toList(),
        _ => <Complaint>[],
      };

      body = AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: IntakeQueue(complaints: filtered, facilityMap: facilityMap),
        ),
      );
    }

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) =>
                  setState(() => _selectedIndex = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.support_agent,
                        color: FimmsColors.primary, size: 28),
                    const SizedBox(height: 4),
                    Text('Grievance',
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
            Expanded(child: body),
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
      body: body,
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
