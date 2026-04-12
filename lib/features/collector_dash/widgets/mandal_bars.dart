import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../models/inspection.dart';
import '../../../models/mandal.dart';

/// Horizontal bars showing per-mandal average score, sorted descending.
class MandalBars extends StatelessWidget {
  final List<Mandal> mandals;
  final Map<String, double>
      scoresByMandalId; // 0..100, only for mandals with inspections
  final String? highlightMandalId;

  const MandalBars({
    super.key,
    required this.mandals,
    required this.scoresByMandalId,
    this.highlightMandalId,
  });

  @override
  Widget build(BuildContext context) {
    final rows = mandals
        .where((m) => scoresByMandalId.containsKey(m.id))
        .map((m) => (m, scoresByMandalId[m.id]!))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart,
                  size: 16, color: FimmsColors.textMuted),
              const SizedBox(width: 8),
              Text(
                'MANDAL SCORES',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: FimmsColors.textMuted,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            Text(
              'No inspection data yet',
              style: TextStyle(
                color: FimmsColors.textMuted,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            )
          else
            for (final (mandal, score) in rows)
              _Bar(
                mandal: mandal,
                score: score,
                highlight: highlightMandalId == mandal.id,
              ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final Mandal mandal;
  final double score;
  final bool highlight;
  const _Bar({
    required this.mandal,
    required this.score,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final grade = GradeX.fromScore(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => context.go('/mandal/${mandal.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mandal.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            highlight ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    score.round().toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: grade.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      color: FimmsColors.surface,
                    ),
                    FractionallySizedBox(
                      widthFactor: (score / 100).clamp(0, 1).toDouble(),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: grade.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
