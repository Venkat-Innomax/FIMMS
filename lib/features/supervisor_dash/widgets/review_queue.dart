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
import '../../shared_widgets/empty_state.dart';
import '../../shared_widgets/grade_chip.dart';
import 'inspection_review_card.dart';
import 'reinspect_dialog.dart';

class ReviewQueue extends ConsumerWidget {
  const ReviewQueue({super.key});

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

        final pending = inspections
            .where((i) =>
                i.status == InspectionStatus.submitted ||
                i.status == InspectionStatus.underReview)
            .toList()
          ..sort((a, b) => b.datetime.compareTo(a.datetime));

        if (pending.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Review queue is empty',
            subtitle: 'No inspections are awaiting review.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
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
              child: ExpansionTile(
                title: Text(facility?.name ?? i.facilityId,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                  '${officer?.name ?? i.officerId} · '
                  '${DateFormat('dd MMM, HH:mm').format(i.datetime)}',
                  style: const TextStyle(
                      fontSize: 12, color: FimmsColors.textMuted),
                ),
                trailing: GradeChip(
                    grade: i.grade,
                    compact: true,
                    scoreOutOf100: i.totalScore),
                children: [
                  const Divider(height: 1),
                  InspectionReviewCard(inspection: i),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) =>
                                ReinspectDialog(inspection: i),
                          ),
                          icon: const Icon(Icons.replay, size: 16),
                          label: const Text('Re-inspect'),
                          style: TextButton.styleFrom(
                              foregroundColor: FimmsColors.secondary),
                        ),
                        const SizedBox(width: 8),
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
