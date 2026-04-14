import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';

// ---------------------------------------------------------------------------
// Mock escalation data
// ---------------------------------------------------------------------------

enum _EscStatus { open, escalatedToDistrict, resolved, closed }

class _Escalation {
  final String id;
  final String facilityName;
  final String severity;
  final String raisedBy;
  final DateTime raisedOn;
  _EscStatus status;

  _Escalation({
    required this.id,
    required this.facilityName,
    required this.severity,
    required this.raisedBy,
    required this.raisedOn,
    this.status = _EscStatus.open,
  });
}

final _mockEscalations = <_Escalation>[
  _Escalation(
    id: 'ESC-2024-001',
    facilityName: 'SW Boys Hostel, Bhongir',
    severity: 'High',
    raisedBy: 'Insp. Suresh Kumar',
    raisedOn: DateTime.now().subtract(const Duration(days: 3)),
  ),
  _Escalation(
    id: 'ESC-2024-002',
    facilityName: 'PHC Mothkur',
    severity: 'Critical',
    raisedBy: 'Dr. Narasimha Rao',
    raisedOn: DateTime.now().subtract(const Duration(days: 6)),
    status: _EscStatus.escalatedToDistrict,
  ),
  _Escalation(
    id: 'ESC-2024-003',
    facilityName: 'BC Girls Hostel, Alair',
    severity: 'Medium',
    raisedBy: 'Insp. Padmavathi',
    raisedOn: DateTime.now().subtract(const Duration(days: 10)),
    status: _EscStatus.resolved,
  ),
  _Escalation(
    id: 'ESC-2024-004',
    facilityName: 'CHC Alair',
    severity: 'High',
    raisedBy: 'Dr. Srinivas',
    raisedOn: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class MandalEscalationPage extends StatefulWidget {
  final String mandalId;
  const MandalEscalationPage({super.key, required this.mandalId});

  @override
  State<MandalEscalationPage> createState() => _MandalEscalationPageState();
}

class _MandalEscalationPageState extends State<MandalEscalationPage> {
  final _escalations = List<_Escalation>.from(_mockEscalations);

  void _escalateToDistrict(String id) {
    setState(() {
      final e = _escalations.firstWhere((e) => e.id == id);
      e.status = _EscStatus.escalatedToDistrict;
    });
    _showSnack('Escalated to District level', FimmsColors.warning);
  }

  void _markResolved(String id) {
    setState(() {
      final e = _escalations.firstWhere((e) => e.id == id);
      e.status = _EscStatus.resolved;
    });
    _showSnack('Escalation marked as resolved', FimmsColors.success);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$msg (demo)'), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openCount =
        _escalations.where((e) => e.status == _EscStatus.open).length;

    return Column(
      children: [
        // Header bar
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: FimmsColors.surface,
          child: Row(
            children: [
              _StatPill(
                  label: 'Open',
                  count: openCount,
                  color: FimmsColors.danger),
              const SizedBox(width: 10),
              _StatPill(
                  label: 'At District',
                  count: _escalations
                      .where((e) =>
                          e.status == _EscStatus.escalatedToDistrict)
                      .length,
                  color: FimmsColors.warning),
              const SizedBox(width: 10),
              _StatPill(
                  label: 'Resolved',
                  count: _escalations
                      .where((e) => e.status == _EscStatus.resolved)
                      .length,
                  color: FimmsColors.success),
            ],
          ),
        ),
        Expanded(
          child: _escalations.isEmpty
              ? const Center(
                  child: Text('No escalations',
                      style: TextStyle(color: FimmsColors.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _escalations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final e = _escalations[index];
                    return _EscalationCard(
                      escalation: e,
                      onEscalate: e.status == _EscStatus.open
                          ? () => _escalateToDistrict(e.id)
                          : null,
                      onResolve: (e.status == _EscStatus.open ||
                              e.status == _EscStatus.escalatedToDistrict)
                          ? () => _markResolved(e.id)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EscalationCard extends StatelessWidget {
  final _Escalation escalation;
  final VoidCallback? onEscalate;
  final VoidCallback? onResolve;
  const _EscalationCard(
      {required this.escalation, this.onEscalate, this.onResolve});

  Color get _severityColor => switch (escalation.severity) {
        'Critical' => FimmsColors.danger,
        'High' => Colors.deepOrange,
        'Medium' => FimmsColors.warning,
        _ => FimmsColors.textMuted,
      };

  Color get _statusColor => switch (escalation.status) {
        _EscStatus.open => FimmsColors.danger,
        _EscStatus.escalatedToDistrict => FimmsColors.warning,
        _EscStatus.resolved => FimmsColors.success,
        _EscStatus.closed => FimmsColors.textMuted,
      };

  String get _statusLabel => switch (escalation.status) {
        _EscStatus.open => 'Open',
        _EscStatus.escalatedToDistrict => 'At District',
        _EscStatus.resolved => 'Resolved',
        _EscStatus.closed => 'Closed',
      };

  @override
  Widget build(BuildContext context) {
    final daysOpen =
        DateTime.now().difference(escalation.raisedOn).inDays;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: escalation.status == _EscStatus.open
              ? _severityColor.withValues(alpha: 0.3)
              : FimmsColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(label: escalation.severity, color: _severityColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  escalation.facilityName,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _Chip(label: _statusLabel, color: _statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _MetaText(Icons.person_outline, escalation.raisedBy),
              _MetaText(
                  Icons.calendar_today_outlined,
                  DateFormat('d MMM yyyy')
                      .format(escalation.raisedOn)),
              _MetaText(
                  Icons.hourglass_top_outlined,
                  '$daysOpen day${daysOpen != 1 ? 's' : ''} pending'),
              _MetaText(Icons.tag, escalation.id),
            ],
          ),
          if (onEscalate != null || onResolve != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (onEscalate != null)
                  OutlinedButton.icon(
                    onPressed: onEscalate,
                    icon: const Icon(Icons.north_east, size: 14),
                    label: const Text('Escalate to District'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      side: BorderSide(
                          color:
                              Colors.deepOrange.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                  ),
                if (onResolve != null)
                  FilledButton.icon(
                    onPressed: onResolve,
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Mark Resolved'),
                    style: FilledButton.styleFrom(
                      backgroundColor: FimmsColors.success,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaText(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: FimmsColors.textMuted),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 11, color: FimmsColors.textMuted)),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatPill(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
