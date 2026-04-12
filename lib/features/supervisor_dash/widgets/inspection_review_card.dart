import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/inspection.dart';

class InspectionReviewCard extends StatelessWidget {
  final Inspection inspection;
  const InspectionReviewCard({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InfoChip(
                  label: 'Score',
                  value: '${inspection.totalScore.round()}/100'),
              const SizedBox(width: 8),
              _InfoChip(
                  label: 'Geofence',
                  value: inspection.geofencePass ? 'PASS' : 'FAIL'),
              const SizedBox(width: 8),
              _InfoChip(
                  label: 'Status',
                  value: inspection.status.label),
              if (inspection.urgentFlag) ...[
                const SizedBox(width: 8),
                _InfoChip(label: 'Urgent', value: 'YES'),
              ],
            ],
          ),
          if (inspection.urgentReason != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FimmsColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Urgent: ${inspection.urgentReason}',
                style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: FimmsColors.secondary),
              ),
            ),
          ],
          if (inspection.sections.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Section Scores',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final s in inspection.sections)
              if (!s.skipped)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(s.title,
                            style: const TextStyle(fontSize: 12)),
                      ),
                      Text(
                        '${s.rawScore.toStringAsFixed(1)} / ${s.maxScore.toStringAsFixed(1)}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'Section details not available in demo data',
              style: TextStyle(
                  fontSize: 12,
                  color: FimmsColors.textMuted,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FimmsColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: FimmsColors.textMuted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
