import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../services/mock_auth_service.dart';

class DmhoDashboardPage extends ConsumerStatefulWidget {
  const DmhoDashboardPage({super.key});

  @override
  ConsumerState<DmhoDashboardPage> createState() => _DmhoDashboardPageState();
}

class _DmhoDashboardPageState extends ConsumerState<DmhoDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);

    final pages = <Widget>[
      _OverviewTab(),
      _FacilityInspectionsTab(),
      _ComplaintsTab(),
      _ComplianceTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DMHO Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              user?.designation ?? 'District Medical & Health Officer',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Inspections'),
          NavigationDestination(icon: Icon(Icons.report_problem_outlined), label: 'Complaints'),
          NavigationDestination(icon: Icon(Icons.verified_outlined), label: 'Compliance'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary stat cards
        _SectionLabel('District Hospital Summary'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: const [
            _StatCard(label: 'Total Facilities', value: '10', icon: Icons.local_hospital, color: FimmsColors.primary),
            _StatCard(label: 'Inspected (Month)', value: '7', icon: Icons.fact_check, color: Colors.teal),
            _StatCard(label: 'Pending Compliance', value: '3', icon: Icons.pending_actions, color: Colors.orange),
            _StatCard(label: 'Open Complaints', value: '5', icon: Icons.report_problem, color: Colors.red),
          ],
        ),
        const SizedBox(height: 20),

        // Facility type breakdown
        _SectionLabel('Facility Type Breakdown'),
        const SizedBox(height: 8),
        _FacilityTypeTable(),
        const SizedBox(height: 20),

        // Dy DMHO zone summary
        _SectionLabel('Dy. DMHO Zone Summary'),
        const SizedBox(height: 8),
        _DyDmhoZoneCard(
          zone: 'Bhongir Zone',
          officer: 'Dr. Shilipini',
          facilities: 6,
          inspected: 4,
          pending: 2,
        ),
        const SizedBox(height: 8),
        _DyDmhoZoneCard(
          zone: 'Choutuppal Zone',
          officer: 'Dr. L. Yashoda',
          facilities: 4,
          inspected: 3,
          pending: 1,
        ),
      ],
    );
  }
}

class _FacilityTypeTable extends StatelessWidget {
  static const _rows = [
    ('District Hospital', '1', '1', '0'),
    ('CHC', '3', '2', '1'),
    ('PHC', '5', '3', '2'),
    ('UPHC', '1', '1', '0'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            _tableHeader(),
            for (final r in _rows) _tableRow(r.$1, r.$2, r.$3, r.$4),
          ],
        ),
      ),
    );
  }

  TableRow _tableHeader() => TableRow(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FimmsColors.outline))),
        children: ['Type', 'Total', 'Inspected', 'Pending']
            .map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(h,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: FimmsColors.textMuted)),
                ))
            .toList(),
      );

  TableRow _tableRow(String type, String total, String insp, String pend) => TableRow(
        children: [type, total, insp, pend]
            .map((v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(v, style: const TextStyle(fontSize: 13)),
                ))
            .toList(),
      );
}

class _DyDmhoZoneCard extends StatelessWidget {
  final String zone;
  final String officer;
  final int facilities;
  final int inspected;
  final int pending;

  const _DyDmhoZoneCard({
    required this.zone,
    required this.officer,
    required this.facilities,
    required this.inspected,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(zone, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(officer, style: const TextStyle(fontSize: 12, color: FimmsColors.textMuted)),
            const SizedBox(height: 10),
            Row(
              children: [
                _ZoneStat(label: 'Facilities', value: '$facilities'),
                const SizedBox(width: 24),
                _ZoneStat(label: 'Inspected', value: '$inspected', color: Colors.teal),
                const SizedBox(width: 24),
                _ZoneStat(label: 'Pending', value: '$pending', color: Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _ZoneStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color ?? FimmsColors.primary)),
        Text(label, style: const TextStyle(fontSize: 10, color: FimmsColors.textMuted)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Facility Inspections Tab
// ---------------------------------------------------------------------------

class _FacilityInspectionsTab extends StatelessWidget {
  static const _inspections = [
    ('District Hospital — Bhongir', 'Submitted', 'Oct 12, 2026', '82%', Colors.green),
    ('CHC — Bhongir', 'Reviewed', 'Oct 10, 2026', '74%', Colors.blue),
    ('CHC — Choutuppal', 'Pending', 'Oct 08, 2026', '—', Colors.orange),
    ('PHC — Yadagirigutta', 'Submitted', 'Oct 07, 2026', '68%', Colors.teal),
    ('PHC — Mothkur', 'Escalated', 'Oct 05, 2026', '45%', Colors.red),
    ('UPHC — Bhuvanagiri', 'Submitted', 'Oct 03, 2026', '77%', Colors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _inspections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (name, status, date, score, color) = _inspections[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.local_hospital, color: color, size: 20),
            ),
            title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(date, style: const TextStyle(fontSize: 11)),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                ),
                if (score != '—') ...[
                  const SizedBox(height: 4),
                  Text(score, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FimmsColors.primary)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Complaints Tab
// ---------------------------------------------------------------------------

class _ComplaintsTab extends StatelessWidget {
  static const _complaints = [
    ('District Hospital — Bhongir', 'Medicine shortage', 'Open', Colors.red),
    ('CHC — Bhongir', 'Staff not available', 'Under Review', Colors.orange),
    ('PHC — Mothkur', 'Unhygienic toilets', 'Resolved', Colors.green),
    ('PHC — Pochampally', 'No drinking water', 'Open', Colors.red),
    ('UPHC — Bhuvanagiri', 'Rude staff behaviour', 'Closed', Colors.grey),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _complaints.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (facility, issue, status, color) = _complaints[i];
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
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Compliance Tab
// ---------------------------------------------------------------------------

class _ComplianceTab extends StatelessWidget {
  static const _items = [
    ('District Hospital — Bhongir', 'BMW disposal issue', 'Complied', Colors.green),
    ('CHC — Bhongir', 'Staff duty roster not displayed', 'Pending', Colors.orange),
    ('PHC — Mothkur', 'Expired medicines found', 'Action Taken', Colors.blue),
    ('PHC — Yadagirigutta', 'Toilet not functional', 'Pending', Colors.orange),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (facility, issue, status, color) = _items[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(Icons.verified, color: color, size: 20),
            ),
            title: Text(facility, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(issue, style: const TextStyle(fontSize: 11)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
                Text(label, style: const TextStyle(fontSize: 10, color: FimmsColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FimmsColors.textMuted, letterSpacing: 0.3));
  }
}
