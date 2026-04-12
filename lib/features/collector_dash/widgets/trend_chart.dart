import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/inspection.dart';

/// Simple bar-based trend view showing score progression for inspections.
/// Uses Container-based bars instead of fl_chart to avoid additional deps.
class TrendChart extends StatelessWidget {
  final List<Inspection> inspections;

  const TrendChart({super.key, required this.inspections});

  @override
  Widget build(BuildContext context) {
    if (inspections.isEmpty) {
      return const Center(
        child: Text('No inspection data',
            style: TextStyle(color: FimmsColors.textMuted)),
      );
    }

    // Sort by date ascending
    final sorted = List.of(inspections)
      ..sort((a, b) => a.datetime.compareTo(b.datetime));

    // Take last 15 inspections
    final recent = sorted.length > 15 ? sorted.sublist(sorted.length - 15) : sorted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Text('Recent Inspection Scores',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int idx = 0; idx < recent.length; idx++) ...[
                  if (idx > 0) const SizedBox(width: 4),
                  Expanded(
                    child: _ScoreBar(inspection: recent[idx]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final Inspection inspection;
  const _ScoreBar({required this.inspection});

  @override
  Widget build(BuildContext context) {
    final fraction = inspection.totalScore / 100;
    final color = inspection.grade.color;

    return Tooltip(
      message:
          '${DateFormat('dd MMM').format(inspection.datetime)} — '
          '${inspection.totalScore.round()}/100 (${inspection.grade.label})',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${inspection.totalScore.round()}',
            style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: FractionallySizedBox(
              heightFactor: fraction.clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('d/M').format(inspection.datetime),
            style: const TextStyle(
                fontSize: 7, color: FimmsColors.textMuted),
          ),
        ],
      ),
    );
  }
}
