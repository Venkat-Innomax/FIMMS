import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// A row of 5 stat cards for the Collector dashboard. Each card has a left
/// accent stripe in the stat's contextual colour — the signature look from
/// the design spec.
class StatCardRow extends StatelessWidget {
  final int districtScore;
  final int totalFacilities;
  final int criticalCount;
  final int urgentCount;
  final int inspectedToday;

  const StatCardRow({
    super.key,
    required this.districtScore,
    required this.totalFacilities,
    required this.criticalCount,
    required this.urgentCount,
    required this.inspectedToday,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        label: 'District Score',
        value: districtScore.toString(),
        suffix: '/ 100',
        accent: _scoreAccent(districtScore.toDouble()),
      ),
      _StatCard(
        label: 'Total Facilities',
        value: totalFacilities.toString(),
        accent: FimmsColors.primary,
      ),
      _StatCard(
        label: 'Critical',
        value: criticalCount.toString(),
        accent: FimmsColors.gradeCritical,
      ),
      _StatCard(
        label: 'Urgent Flags',
        value: urgentCount.toString(),
        accent: FimmsColors.secondary,
      ),
      _StatCard(
        label: 'Inspected Today',
        value: inspectedToday.toString(),
        accent: FimmsColors.gradeGood,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in cards)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(width: 180, child: c),
                  ),
              ],
            ),
          );
        }
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  static Color _scoreAccent(double score) {
    if (score >= 85) return FimmsColors.gradeExcellent;
    if (score >= 70) return FimmsColors.gradeGood;
    if (score >= 50) return FimmsColors.gradeAverage;
    if (score >= 35) return FimmsColors.gradePoor;
    return FimmsColors.gradeCritical;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final Color accent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FimmsColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      // IntrinsicHeight forces the Row to measure its intrinsic height
      // first (from the text column) before laying out children, so the
      // left accent stripe can match the card's content height without
      // the Row inheriting unbounded-height constraints from its parents.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: FimmsColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: FimmsColors.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        if (suffix != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            suffix!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: FimmsColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
