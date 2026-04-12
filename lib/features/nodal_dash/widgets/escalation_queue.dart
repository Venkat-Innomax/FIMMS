import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/facility.dart';
import '../../../models/inspection.dart';
import '../../../models/user.dart';
import '../../shared_widgets/grade_chip.dart';

class EscalationQueue extends ConsumerWidget {
  const EscalationQueue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionsAsync = ref.watch(inspectionsProvider);
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final usersAsync = ref.watch(usersProvider);

    return inspectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (inspections) {
        final facilities = facilitiesAsync.valueOrNull ?? <Facility>[];
        final users = usersAsync.valueOrNull ?? <User>[];
        final facilityMap = {for (final f in facilities) f.id: f};
        final userMap = {for (final u in users) u.id: u};

        // Escalation: poor/critical grade OR urgent flag
        final escalated = inspections
            .where((i) =>
                i.grade == Grade.critical ||
                i.grade == Grade.poor ||
                i.urgentFlag)
            .toList()
          ..sort((a, b) {
            // Critical first, then poor, then urgent
            final gradeOrder = {
              Grade.critical: 0,
              Grade.poor: 1,
              Grade.average: 2,
              Grade.good: 3,
              Grade.excellent: 4,
            };
            return (gradeOrder[a.grade] ?? 9)
                .compareTo(gradeOrder[b.grade] ?? 9);
          });

        if (escalated.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 48, color: FimmsColors.success),
                SizedBox(height: 12),
                Text('No escalations pending',
                    style: TextStyle(color: FimmsColors.textMuted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: escalated.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final i = escalated[index];
            final facility = facilityMap[i.facilityId];
            final officer = userMap[i.officerId];

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: i.grade == Grade.critical
                      ? FimmsColors.danger.withValues(alpha: 0.4)
                      : FimmsColors.outline,
                ),
              ),
              color: i.grade == Grade.critical
                  ? FimmsColors.danger.withValues(alpha: 0.03)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facility?.name ?? i.facilityId,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Officer: ${officer?.name ?? i.officerId} · '
                            '${DateFormat('dd MMM yyyy').format(i.datetime)}',
                            style: const TextStyle(
                                fontSize: 12, color: FimmsColors.textMuted),
                          ),
                          if (i.urgentReason != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              i.urgentReason!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: FimmsColors.danger,
                                  fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GradeChip(
                            grade: i.grade,
                            compact: true,
                            scoreOutOf100: i.totalScore),
                        if (i.urgentFlag) ...[
                          const SizedBox(height: 4),
                          const UrgentBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
