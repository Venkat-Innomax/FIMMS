import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/compliance_item.dart';

class ComplianceStatusCards extends StatelessWidget {
  final List<ComplianceItem> items;
  const ComplianceStatusCards({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final pending =
        items.where((i) => i.status == ComplianceStatus.pending).length;
    final submitted =
        items.where((i) => i.status == ComplianceStatus.submitted).length;
    final accepted =
        items.where((i) => i.status == ComplianceStatus.accepted).length;
    final rejected =
        items.where((i) => i.status == ComplianceStatus.rejected).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StatCard(
              label: 'Total', value: '${items.length}', color: FimmsColors.primary),
          const SizedBox(width: 8),
          _StatCard(
              label: 'Pending', value: '$pending', color: FimmsColors.gradeAverage),
          const SizedBox(width: 8),
          _StatCard(
              label: 'Submitted', value: '$submitted', color: Colors.blue),
          const SizedBox(width: 8),
          _StatCard(
              label: 'Accepted', value: '$accepted', color: FimmsColors.success),
          const SizedBox(width: 8),
          _StatCard(
              label: 'Rejected', value: '$rejected', color: FimmsColors.danger),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: FimmsColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
