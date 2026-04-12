import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/inspection.dart';
import '../../services/scoring_engine.dart';
import '../shared_widgets/grade_chip.dart';
import '../shared_widgets/responsive_scaffold.dart';

/// Post-submission summary screen. Shows section-wise scores, total,
/// grade band, and the corresponding action from spec §4.2.
/// Spec §4.2 says the grade is normally hidden from the field officer —
/// the demo shows it anyway and notes the production difference.
class ScoreSummaryPage extends ConsumerWidget {
  final String inspectionId;
  const ScoreSummaryPage({super.key, required this.inspectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = GoRouterState.of(context).extra;
    final scoring = extra is ScoringResult ? extra : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/officer'),
        ),
        title: const Text('Inspection Submitted'),
      ),
      body: scoring == null
          ? const Center(child: Text('No scoring data — navigate back.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FimmsBrandMark(),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: FimmsColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: FimmsColors.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: FimmsColors.gradeExcellent,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Inspection submitted',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  scoring.totalOutOf100.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w800,
                                    color: scoring.grade.color,
                                    height: 1,
                                    letterSpacing: -2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    '/ 100',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: FimmsColors.textMuted,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                GradeChip(grade: scoring.grade),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              scoring.grade.action,
                              style: TextStyle(
                                fontSize: 13,
                                color: FimmsColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _SectionTitle('Section-wise breakdown'),
                      for (final s in scoring.sections)
                        _SectionRow(section: s),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FimmsColors.surface,
                          border: Border.all(color: FimmsColors.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16,
                                color: FimmsColors.textMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'In production, spec §4.2 hides the grade '
                                'and total score from the field officer — '
                                'the demo shows them for walkthrough '
                                'purposes.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: FimmsColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => context.go('/officer'),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Back to assignments'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: FimmsColors.textMuted,
        ),
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final ScoredSection section;
  const _SectionRow({required this.section});

  @override
  Widget build(BuildContext context) {
    final pct = section.skipped
        ? 0.0
        : (section.adjustedMaxScore == 0
            ? 0.0
            : section.rawScore / section.adjustedMaxScore);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FimmsColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FimmsColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (section.skipped)
                  const Text(
                    'SKIPPED',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: FimmsColors.textMuted,
                      letterSpacing: 0.6,
                    ),
                  )
                else
                  Text(
                    '${(pct * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            if (!section.skipped) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  children: [
                    Container(height: 6, color: FimmsColors.surface),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0, 1).toDouble(),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: GradeX.fromScore(pct * 100).color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
