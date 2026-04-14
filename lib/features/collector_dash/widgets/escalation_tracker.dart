import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';

// ---------------------------------------------------------------------------
// Mock escalation data
// ---------------------------------------------------------------------------

enum _EscSeverity { low, medium, high, critical }
enum _EscStatus { open, atDistrict, resolved, closed }

class _DistrictEscalation {
  final String id;
  final String facilityId;
  final String facilityName;
  final String mandalId;
  final String module; // 'Hostel' or 'Hospital'
  final _EscSeverity severity;
  final _EscStatus status;
  final String escalatedBy;
  final DateTime raisedOn;

  const _DistrictEscalation({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    required this.mandalId,
    required this.module,
    required this.severity,
    required this.status,
    required this.escalatedBy,
    required this.raisedOn,
  });
}

final _mockDistrictEscalations = <_DistrictEscalation>[
  _DistrictEscalation(
    id: 'DE-2024-001',
    facilityId: 'f1',
    facilityName: 'SW Boys Hostel, Bhongir',
    mandalId: 'bhongir',
    module: 'Hostel',
    severity: _EscSeverity.critical,
    status: _EscStatus.open,
    escalatedBy: 'MRO Bhongir',
    raisedOn: DateTime.now().subtract(const Duration(days: 2)),
  ),
  _DistrictEscalation(
    id: 'DE-2024-002',
    facilityId: 'f2',
    facilityName: 'PHC Mothkur',
    mandalId: 'mothkur',
    module: 'Hospital',
    severity: _EscSeverity.high,
    status: _EscStatus.atDistrict,
    escalatedBy: 'MRO Mothkur',
    raisedOn: DateTime.now().subtract(const Duration(days: 4)),
  ),
  _DistrictEscalation(
    id: 'DE-2024-003',
    facilityId: 'f3',
    facilityName: 'BC Girls Hostel, Alair',
    mandalId: 'alair',
    module: 'Hostel',
    severity: _EscSeverity.medium,
    status: _EscStatus.resolved,
    escalatedBy: 'MRO Alair',
    raisedOn: DateTime.now().subtract(const Duration(days: 10)),
  ),
  _DistrictEscalation(
    id: 'DE-2024-004',
    facilityId: 'f4',
    facilityName: 'CHC Alair',
    mandalId: 'alair',
    module: 'Hospital',
    severity: _EscSeverity.high,
    status: _EscStatus.open,
    escalatedBy: 'DMHO Office',
    raisedOn: DateTime.now().subtract(const Duration(days: 1)),
  ),
  _DistrictEscalation(
    id: 'DE-2024-005',
    facilityId: 'f5',
    facilityName: 'Min Girls Hostel, Yadagirigutta',
    mandalId: 'yadagirigutta',
    module: 'Hostel',
    severity: _EscSeverity.low,
    status: _EscStatus.closed,
    escalatedBy: 'MRO Yadagirigutta',
    raisedOn: DateTime.now().subtract(const Duration(days: 20)),
  ),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class EscalationTracker extends ConsumerStatefulWidget {
  const EscalationTracker({super.key});

  @override
  ConsumerState<EscalationTracker> createState() =>
      _EscalationTrackerState();
}

class _EscalationTrackerState extends ConsumerState<EscalationTracker> {
  String _mandal = 'All';
  String _module = 'All';
  String _status = 'All';

  List<_DistrictEscalation> get _filtered {
    return _mockDistrictEscalations.where((e) {
      if (_mandal != 'All' && e.mandalId != _mandal) return false;
      if (_module != 'All' && e.module != _module) return false;
      if (_status != 'All' && _statusLabel(e.status) != _status) return false;
      return true;
    }).toList();
  }

  String _statusLabel(_EscStatus s) => switch (s) {
        _EscStatus.open => 'Open',
        _EscStatus.atDistrict => 'At District',
        _EscStatus.resolved => 'Resolved',
        _EscStatus.closed => 'Closed',
      };

  @override
  Widget build(BuildContext context) {
    final mandals = _mockDistrictEscalations.map((e) => e.mandalId).toSet().toList();
    final filtered = _filtered;

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          color: FimmsColors.surface,
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _FilterDropdown(
                label: 'Mandal',
                value: _mandal,
                items: ['All', ...mandals.map((m) => _cap(m))],
                rawItems: ['All', ...mandals],
                onChanged: (v) => setState(() => _mandal = v ?? 'All'),
              ),
              _FilterDropdown(
                label: 'Module',
                value: _module,
                items: const ['All', 'Hostel', 'Hospital'],
                onChanged: (v) => setState(() => _module = v ?? 'All'),
              ),
              _FilterDropdown(
                label: 'Status',
                value: _status,
                items: const ['All', 'Open', 'At District', 'Resolved', 'Closed'],
                onChanged: (v) => setState(() => _status = v ?? 'All'),
              ),
            ],
          ),
        ),

        // Summary row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: FimmsColors.surfaceAlt,
          child: Row(
            children: [
              Text(
                '${filtered.length} escalation${filtered.length != 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FimmsColors.textPrimary),
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                label: 'Open',
                count: filtered
                    .where((e) => e.status == _EscStatus.open)
                    .length,
                color: FimmsColors.danger,
              ),
              const SizedBox(width: 6),
              _SummaryChip(
                label: 'Critical',
                count: filtered
                    .where((e) => e.severity == _EscSeverity.critical)
                    .length,
                color: FimmsColors.danger,
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: FimmsColors.success),
                      SizedBox(height: 12),
                      Text('No escalations match the filter',
                          style: TextStyle(color: FimmsColors.textMuted)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _EscalationRow(esc: filtered[index]),
                ),
        ),
      ],
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _EscalationRow extends StatelessWidget {
  final _DistrictEscalation esc;
  const _EscalationRow({required this.esc});

  Color get _sevColor => switch (esc.severity) {
        _EscSeverity.critical => FimmsColors.danger,
        _EscSeverity.high => Colors.deepOrange,
        _EscSeverity.medium => FimmsColors.warning,
        _EscSeverity.low => FimmsColors.textMuted,
      };

  String get _sevLabel => switch (esc.severity) {
        _EscSeverity.critical => 'Critical',
        _EscSeverity.high => 'High',
        _EscSeverity.medium => 'Medium',
        _EscSeverity.low => 'Low',
      };

  Color get _statusColor => switch (esc.status) {
        _EscStatus.open => FimmsColors.danger,
        _EscStatus.atDistrict => FimmsColors.warning,
        _EscStatus.resolved => FimmsColors.success,
        _EscStatus.closed => FimmsColors.textMuted,
      };

  String get _statusLabel => switch (esc.status) {
        _EscStatus.open => 'Open',
        _EscStatus.atDistrict => 'At District',
        _EscStatus.resolved => 'Resolved',
        _EscStatus.closed => 'Closed',
      };

  @override
  Widget build(BuildContext context) {
    final daysOpen = DateTime.now().difference(esc.raisedOn).inDays;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esc.status == _EscStatus.open || esc.status == _EscStatus.atDistrict
              ? _sevColor.withValues(alpha: 0.3)
              : FimmsColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(label: _sevLabel, color: _sevColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(esc.facilityName,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
              _Chip(label: _statusLabel, color: _statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _MetaChip(Icons.map_outlined, _cap(esc.mandalId)),
              _MetaChip(Icons.business_outlined, esc.module),
              _MetaChip(Icons.person_outline, esc.escalatedBy),
              _MetaChip(Icons.calendar_today_outlined,
                  DateFormat('d MMM yyyy').format(esc.raisedOn)),
              _MetaChip(Icons.hourglass_top_outlined,
                  '$daysOpen day${daysOpen != 1 ? 's' : ''}'),
            ],
          ),
          if (esc.status == _EscStatus.open ||
              esc.status == _EscStatus.atDistrict) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Escalation closed (demo)'),
                      backgroundColor: FimmsColors.success),
                );
              },
              icon: const Icon(Icons.lock_outline, size: 14),
              label: const Text('Close Escalation'),
              style: FilledButton.styleFrom(
                backgroundColor: FimmsColors.success,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                textStyle: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip(this.icon, this.text);

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

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$count $label',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final List<String>? rawItems;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    this.rawItems,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayToRaw = rawItems != null
        ? {for (int i = 0; i < items.length; i++) items[i]: rawItems![i]}
        : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, color: FimmsColors.textMuted)),
        DropdownButton<String>(
          value: displayToRaw != null
              ? (displayToRaw.entries
                  .firstWhere((e) => e.value == value,
                      orElse: () => MapEntry(items.first, value))
                  .key)
              : value,
          isDense: true,
          underline: const SizedBox.shrink(),
          items: items
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: const TextStyle(fontSize: 12)),
                  ))
              .toList(),
          onChanged: (selected) {
            if (selected == null) return;
            final raw = displayToRaw?[selected] ?? selected;
            onChanged(raw);
          },
        ),
      ],
    );
  }
}
