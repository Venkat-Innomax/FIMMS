import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/inspection.dart';

/// Pill-shaped grade chip with a coloured left border bar — the signature
/// visual for grade bands (spec §4.2).
class GradeChip extends StatelessWidget {
  final Grade grade;
  final bool compact;
  final double? scoreOutOf100;

  const GradeChip({
    super.key,
    required this.grade,
    this.compact = false,
    this.scoreOutOf100,
  });

  @override
  Widget build(BuildContext context) {
    final c = grade.color;
    final text = scoreOutOf100 != null
        ? '${grade.label} · ${scoreOutOf100!.round()}'
        : grade.label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border(left: BorderSide(color: c, width: 3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: c,
          fontSize: compact ? 11 : 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class UrgentBadge extends StatelessWidget {
  const UrgentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FimmsColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FimmsColors.secondary),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department,
              size: 13, color: FimmsColors.secondary),
          SizedBox(width: 4),
          Text(
            'URGENT',
            style: TextStyle(
              color: FimmsColors.secondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
