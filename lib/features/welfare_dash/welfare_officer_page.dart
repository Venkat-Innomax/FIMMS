import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../services/mock_auth_service.dart';

class WelfareOfficerPage extends ConsumerStatefulWidget {
  const WelfareOfficerPage({super.key});

  @override
  ConsumerState<WelfareOfficerPage> createState() => _WelfareOfficerPageState();
}

class _WelfareOfficerPageState extends ConsumerState<WelfareOfficerPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);

    final pages = <Widget>[
      const _MyInstitutionsTab(),
      const _LatestIssuesTab(),
      const _ComplianceUpdatesTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welfare Officer Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              user?.name ?? 'Welfare Officer',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.house_outlined), label: 'Institutions'),
          NavigationDestination(icon: Icon(Icons.warning_amber_outlined), label: 'Issues'),
          NavigationDestination(icon: Icon(Icons.verified_outlined), label: 'Compliance'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// My Institutions Tab
// ---------------------------------------------------------------------------

class _MyInstitutionsTab extends StatelessWidget {
  const _MyInstitutionsTab();

  static const _institutions = [
    ('Govt BC BH Mothkur', 'Mothkur', 'Last: Oct 05, 2026', true),
    ('KGBV Bhongir', 'Bhongir', 'Last: Oct 08, 2026', true),
    ('Govt SC DD Boys Hostel Alair', 'Alair', 'Not yet inspected', false),
    ('TSWREIS (G) Addagudur', 'Addagudur', 'Last: Sep 28, 2026', true),
    ('Govt BC BH Athmakur', 'Athmakur', 'Not yet inspected', false),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _institutions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (name, mandal, lastInsp, inspected) = _institutions[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (inspected ? Colors.teal : Colors.orange).withValues(alpha: 0.12),
              child: Icon(Icons.house, color: inspected ? Colors.teal : Colors.orange, size: 20),
            ),
            title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text('$mandal • $lastInsp', style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, color: FimmsColors.textMuted),
            onTap: () => _showInstitutionDetails(context, name),
          ),
        );
      },
    );
  }

  void _showInstitutionDetails(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Text(name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _DetailRow(label: 'Last Inspection', value: 'Oct 08, 2026'),
            _DetailRow(label: 'Score', value: '74 / 100'),
            _DetailRow(label: 'Status', value: 'Under Review'),
            _DetailRow(label: 'Open Issues', value: '3'),
            const SizedBox(height: 16),
            const Text('Recent Issues',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            _IssueChip(label: 'Sanitation — Soak pit not functional', severity: 'High'),
            const SizedBox(height: 6),
            _IssueChip(label: 'Food — No menu chart displayed', severity: 'Medium'),
            const SizedBox(height: 6),
            _IssueChip(label: 'Staff — 2 vacancies in cook post', severity: 'Medium'),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: FimmsColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _IssueChip extends StatelessWidget {
  final String label;
  final String severity;
  const _IssueChip({required this.label, required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = severity == 'High' ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(severity,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Latest Issues Tab
// ---------------------------------------------------------------------------

class _LatestIssuesTab extends StatelessWidget {
  const _LatestIssuesTab();

  static const _issues = [
    ('Govt BC BH Mothkur', 'Kitchen wash area not clean', 'High', 'Oct 05'),
    ('KGBV Bhongir', 'Police patrolling not regular', 'Medium', 'Oct 08'),
    ('TSWREIS Addagudur', 'Sick boarders without medical attention', 'High', 'Sep 28'),
    ('Govt SC DD Alair', 'Dormitories not cleaned properly', 'Medium', 'Sep 20'),
    ('Govt BC BH Bhongir', 'Staff vacancy — 2 cooks missing', 'Low', 'Sep 15'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _issues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (hostel, issue, severity, date) = _issues[i];
        final color = switch (severity) {
          'High' => Colors.red,
          'Medium' => Colors.orange,
          _ => Colors.blue,
        };
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(hostel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(severity,
                          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(issue, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Flagged: $date',
                        style: const TextStyle(fontSize: 11, color: FimmsColors.textMuted)),
                    TextButton(
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                      onPressed: () => _showComplianceForm(context, hostel, issue),
                      child: const Text('Add Compliance Update', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComplianceForm(BuildContext context, String hostel, String issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: _ComplianceForm(hostel: hostel, issue: issue),
      ),
    );
  }
}

class _ComplianceForm extends StatefulWidget {
  final String hostel;
  final String issue;
  const _ComplianceForm({required this.hostel, required this.issue});

  @override
  State<_ComplianceForm> createState() => _ComplianceFormState();
}

class _ComplianceFormState extends State<_ComplianceForm> {
  final _remarksCtrl = TextEditingController();
  String _status = 'Action Taken';
  bool _submitted = false;

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.teal),
            SizedBox(height: 12),
            Text('Compliance update submitted!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Compliance Update',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(widget.hostel,
              style: const TextStyle(fontSize: 12, color: FimmsColors.textMuted)),
          Text('Issue: ${widget.issue}',
              style: const TextStyle(fontSize: 12, color: FimmsColors.textMuted)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Compliance Status',
              border: OutlineInputBorder(),
            ),
            items: ['Action Taken', 'Partial Compliance', 'Not Complied', 'Escalated']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarksCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Remarks / Action Taken',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.attach_file, color: FimmsColors.textMuted, size: 18),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo upload — not wired in demo'))),
                child: const Text('Attach Proof Photo'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => setState(() => _submitted = true),
              child: const Text('Submit Compliance Update'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compliance Updates Tab
// ---------------------------------------------------------------------------

class _ComplianceUpdatesTab extends StatelessWidget {
  const _ComplianceUpdatesTab();

  static const _updates = [
    ('Govt BC BH Mothkur', 'Kitchen cleaned and algae removed', 'Action Taken', 'Oct 06', Colors.teal),
    ('KGBV Bhongir', 'Police contacted — patrolling resumed', 'Action Taken', 'Oct 09', Colors.teal),
    ('TSWREIS Addagudur', 'Medical officer visit arranged', 'Partial Compliance', 'Oct 01', Colors.orange),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _updates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final (hostel, action, status, date, color) = _updates[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(hostel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(status,
                          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(action, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text('Submitted: $date',
                    style: const TextStyle(fontSize: 11, color: FimmsColors.textMuted)),
              ],
            ),
          ),
        );
      },
    );
  }
}
