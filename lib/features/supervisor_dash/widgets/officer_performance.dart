import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/user.dart';

class OfficerPerformance extends ConsumerWidget {
  const OfficerPerformance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionsAsync = ref.watch(inspectionsProvider);
    final usersAsync = ref.watch(usersProvider);

    return inspectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (inspections) {
        final users = usersAsync.valueOrNull ?? <User>[];
        final fieldOfficers =
            users.where((u) => u.role == Role.fieldOfficer).toList();

        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));

        final stats = fieldOfficers.map((officer) {
          final officerInspections =
              inspections.where((i) => i.officerId == officer.id).toList();
          final thisWeek = officerInspections
              .where((i) => i.datetime.isAfter(weekAgo))
              .length;
          final avgScore = officerInspections.isEmpty
              ? 0.0
              : officerInspections
                      .map((i) => i.totalScore)
                      .reduce((a, b) => a + b) /
                  officerInspections.length;

          return _OfficerStats(
            officer: officer,
            totalInspections: officerInspections.length,
            thisWeek: thisWeek,
            avgScore: avgScore,
          );
        }).toList()
          ..sort(
              (a, b) => b.totalInspections.compareTo(a.totalInspections));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: stats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final s = stats[index];
            return _PerformanceCard(stats: s);
          },
        );
      },
    );
  }
}

class _OfficerStats {
  final User officer;
  final int totalInspections;
  final int thisWeek;
  final double avgScore;

  const _OfficerStats({
    required this.officer,
    required this.totalInspections,
    required this.thisWeek,
    required this.avgScore,
  });
}

class _PerformanceCard extends StatelessWidget {
  final _OfficerStats stats;
  const _PerformanceCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: FimmsColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      FimmsColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    stats.officer.name
                        .replaceAll(RegExp(r'(Smt\.|Sri)'), '')
                        .trim()
                        .split(RegExp(r'\s+'))
                        .take(2)
                        .map((w) => w.isEmpty ? '' : w[0])
                        .join()
                        .toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FimmsColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stats.officer.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(stats.officer.designation,
                          style: const TextStyle(
                              fontSize: 12,
                              color: FimmsColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _MetricBox(
                  label: 'Total',
                  value: '${stats.totalInspections}',
                  color: FimmsColors.primary,
                ),
                const SizedBox(width: 10),
                _MetricBox(
                  label: 'This Week',
                  value: '${stats.thisWeek}',
                  color: Colors.teal,
                ),
                const SizedBox(width: 10),
                _MetricBox(
                  label: 'Avg Score',
                  value: stats.avgScore.round().toString(),
                  color: _scoreColor(stats.avgScore),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.avgScore / 100,
                backgroundColor: FimmsColors.surface,
                color: _scoreColor(stats.avgScore),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 85) return FimmsColors.gradeExcellent;
    if (score >= 70) return FimmsColors.gradeGood;
    if (score >= 50) return FimmsColors.gradeAverage;
    if (score >= 35) return FimmsColors.gradePoor;
    return FimmsColors.gradeCritical;
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: FimmsColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
