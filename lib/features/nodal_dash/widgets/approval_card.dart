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

class ApprovalList extends ConsumerWidget {
  const ApprovalList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionsAsync = ref.watch(inspectionsProvider);
    final facilitiesAsync = ref.watch(moduleFacilitiesProvider);
    final usersAsync = ref.watch(usersProvider);

    return inspectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (inspections) {
        final facilities = facilitiesAsync.valueOrNull ?? <Facility>[];
        final users = usersAsync.valueOrNull ?? <User>[];
        final facilityMap = {for (final f in facilities) f.id: f};
        final userMap = {for (final u in users) u.id: u};

        final pending = inspections
            .where((i) =>
                i.status == InspectionStatus.submitted ||
                i.status == InspectionStatus.underReview)
            .toList()
          ..sort((a, b) => b.datetime.compareTo(a.datetime));

        if (pending.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 48, color: FimmsColors.success),
                SizedBox(height: 12),
                Text('All inspections approved',
                    style: TextStyle(color: FimmsColors.textMuted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final i = pending[index];
            final facility = facilityMap[i.facilityId];
            final officer = userMap[i.officerId];

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: FimmsColors.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(facility?.name ?? i.facilityId,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                'By: ${officer?.name ?? i.officerId} · '
                                '${DateFormat('dd MMM yyyy, HH:mm').format(i.datetime)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: FimmsColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        GradeChip(
                            grade: i.grade,
                            scoreOutOf100: i.totalScore),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        i.status.label,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Rejected (demo mode)')),
                          ),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: FimmsColors.danger),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Approved (demo mode)')),
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                        ),
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
