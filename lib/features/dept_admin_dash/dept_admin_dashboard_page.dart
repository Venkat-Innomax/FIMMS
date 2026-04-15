import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/repositories/facility_repository.dart';
import '../../models/facility.dart';
import '../../services/mock_auth_service.dart';

class DeptAdminDashboardPage extends ConsumerStatefulWidget {
  const DeptAdminDashboardPage({super.key});

  @override
  ConsumerState<DeptAdminDashboardPage> createState() =>
      _DeptAdminDashboardPageState();
}

class _DeptAdminDashboardPageState
    extends ConsumerState<DeptAdminDashboardPage> {
  int _selectedIndex = 0;
  int _drawerPage = -1;

  static const _drawerTitles = ['Reports', 'Complaints'];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final dept = user?.department ?? 'Department';
    final facilitiesAsync = ref.watch(facilitiesProvider);

    Widget buildBody(List<Facility> allFacilities) {
      final deptFacilities = allFacilities
          .where((f) => f.type == FacilityType.hostel && f.department == dept)
          .toList();

      final bottomPages = <Widget>[
        _OverviewTab(dept: dept, facilities: deptFacilities),
        _FacilityListTab(dept: dept, facilities: deptFacilities),
        _InspectionQueueTab(dept: dept),
        _PendingTab(dept: dept, facilities: deptFacilities),
      ];

      final drawerPages = <Widget>[
        _ReportsTab(dept: dept),
        _ComplaintsTab(dept: dept),
      ];

      if (_drawerPage >= 0 && _drawerPage < drawerPages.length) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_drawerTitles[_drawerPage]),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _drawerPage = -1),
            ),
            actions: [_logoutButton()],
          ),
          body: drawerPages[_drawerPage],
        );
      }

      return Scaffold(
        body: IndexedStack(index: _selectedIndex, children: bottomPages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
            NavigationDestination(icon: Icon(Icons.list_outlined), label: 'Facilities'),
            NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Inspections'),
            NavigationDestination(icon: Icon(Icons.pending_actions_outlined), label: 'Pending'),
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
                        color: FimmsColors.textMuted, fontWeight: FontWeight.w700),
                  ),
                ),
                const Divider(),
                for (int i = 0; i < _drawerTitles.length; i++)
                  ListTile(
                    leading: Icon(
                      i == 0 ? Icons.bar_chart : Icons.report_problem,
                      color: FimmsColors.primary,
                    ),
                    title: Text(_drawerTitles[i], style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _drawerPage = i);
                    },
                  ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dept, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Text('Department Admin', style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            _logoutButton(),
          ],
        ),
      );
    }

    return facilitiesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: buildBody,
    );
  }

  Widget _logoutButton() => IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () => ref.read(authStateProvider.notifier).signOut(),
      );
}

// ---------------------------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  final String dept;
  final List<Facility> facilities;

  const _OverviewTab({required this.dept, required this.facilities});

  @override
  Widget build(BuildContext context) {
    final total = facilities.length;
    final inspected = facilities.where((f) => f.lastInspectionId != null).length;
    final pending = total - inspected;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(dept,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FimmsColors.primary)),
        const SizedBox(height: 4),
        Text('$total facilities across Yadadri Bhuvanagiri District',
            style: const TextStyle(fontSize: 12, color: FimmsColors.textMuted)),
        const SizedBox(height: 16),

        // KPI row
        Row(children: [
          Expanded(child: _KpiCard(label: 'Total', value: '$total', color: FimmsColors.primary)),
          const SizedBox(width: 10),
          Expanded(child: _KpiCard(label: 'Inspected', value: '$inspected', color: Colors.teal)),
          const SizedBox(width: 10),
          Expanded(child: _KpiCard(label: 'Pending', value: '$pending', color: Colors.orange)),
        ]),
        const SizedBox(height: 20),

        // Mandal breakdown
        const Text('Mandal Breakdown',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FimmsColors.textMuted)),
        const SizedBox(height: 8),
        ..._mandalBreakdown(facilities),
      ],
    );
  }

  List<Widget> _mandalBreakdown(List<Facility> facilities) {
    final Map<String, List<Facility>> byMandal = {};
    for (final f in facilities) {
      byMandal.putIfAbsent(f.mandalId, () => []).add(f);
    }
    return byMandal.entries.map((e) {
      final insp = e.value.where((f) => f.lastInspectionId != null).length;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined, color: FimmsColors.primary, size: 18),
            title: Text(
              e.key.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            trailing: Text(
              '$insp / ${e.value.length} inspected',
              style: const TextStyle(fontSize: 12, color: FimmsColors.textMuted),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Facility List Tab
// ---------------------------------------------------------------------------

class _FacilityListTab extends StatelessWidget {
  final String dept;
  final List<Facility> facilities;

  const _FacilityListTab({required this.dept, required this.facilities});

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.house_outlined, size: 48, color: FimmsColors.textMuted),
            const SizedBox(height: 12),
            Text('No facilities found for $dept',
                style: const TextStyle(color: FimmsColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: facilities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final f = facilities[i];
        final inspected = f.lastInspectionId != null;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (inspected ? Colors.teal : Colors.orange).withValues(alpha: 0.12),
              child: Icon(
                Icons.house_outlined,
                color: inspected ? Colors.teal : Colors.orange,
                size: 20,
              ),
            ),
            title: Text(f.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${f.mandalId.replaceAll('_', ' ')} • ${f.gender ?? ''}'.trim(),
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (inspected ? Colors.teal : Colors.orange).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                inspected ? 'Inspected' : 'Pending',
                style: TextStyle(
                  fontSize: 10,
                  color: inspected ? Colors.teal : Colors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Inspection Queue Tab
// ---------------------------------------------------------------------------

class _InspectionQueueTab extends StatelessWidget {
  final String dept;

  const _InspectionQueueTab({required this.dept});

  static const _queue = [
    ('Submitted', 'Oct 12, 2026', '78%', Colors.teal),
    ('Under Review', 'Oct 10, 2026', '65%', Colors.blue),
    ('Escalated', 'Oct 07, 2026', '42%', Colors.red),
    ('Submitted', 'Oct 05, 2026', '83%', Colors.teal),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _queue.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (status, date, score, color) = _queue[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.fact_check, color: color, size: 20),
            ),
            title: Text('Inspection #${1000 + i}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(date, style: const TextStyle(fontSize: 11)),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(status,
                      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 4),
                Text(score,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: FimmsColors.primary)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pending Inspections Tab
// ---------------------------------------------------------------------------

class _PendingTab extends StatelessWidget {
  final String dept;
  final List<Facility> facilities;

  const _PendingTab({required this.dept, required this.facilities});

  @override
  Widget build(BuildContext context) {
    final pending = facilities.where((f) => f.lastInspectionId == null).toList();
    if (pending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.teal),
            SizedBox(height: 12),
            Text('All facilities inspected!',
                style: TextStyle(color: FimmsColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final f = pending[i];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x1FFF9800),
              child: Icon(Icons.pending_actions, color: Colors.orange, size: 20),
            ),
            title: Text(f.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(f.mandalId.replaceAll('_', ' '),
                style: const TextStyle(fontSize: 11)),
            trailing: const Text('Not Inspected',
                style: TextStyle(fontSize: 11, color: Colors.orange)),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Reports Tab (drawer)
// ---------------------------------------------------------------------------

class _ReportsTab extends StatelessWidget {
  final String dept;

  const _ReportsTab({required this.dept});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ReportRow(title: '$dept — Inspection Summary', subtitle: 'Oct 2026'),
        _ReportRow(title: '$dept — Compliance Status', subtitle: 'Oct 2026'),
        _ReportRow(title: '$dept — Pending Facilities', subtitle: 'Oct 2026'),
        _ReportRow(title: '$dept — Officer Performance', subtitle: 'Oct 2026'),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ReportRow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file_outlined, color: FimmsColors.primary),
        title: Text(title, style: const TextStyle(fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.download_outlined, color: FimmsColors.textMuted),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report download — not wired in demo')),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Complaints Tab (drawer)
// ---------------------------------------------------------------------------

class _ComplaintsTab extends StatelessWidget {
  final String dept;

  const _ComplaintsTab({required this.dept});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _ComplaintCard(
          facility: 'Hostel — Bhongir',
          issue: 'Food quality complaint',
          status: 'Open',
          color: Colors.red,
        ),
        SizedBox(height: 8),
        _ComplaintCard(
          facility: 'Hostel — Alair',
          issue: 'Sanitation issues',
          status: 'Under Review',
          color: Colors.orange,
        ),
        SizedBox(height: 8),
        _ComplaintCard(
          facility: 'Hostel — Mothkur',
          issue: 'Staff vacancy',
          status: 'Resolved',
          color: Colors.green,
        ),
      ],
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final String facility;
  final String issue;
  final String status;
  final Color color;

  const _ComplaintCard({
    required this.facility,
    required this.issue,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Icons.report_problem, color: color, size: 20),
        ),
        title: Text(facility, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(issue, style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(status,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KPI card
// ---------------------------------------------------------------------------

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: FimmsColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
