import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../models/inspection.dart';
import '../../shared_widgets/grade_chip.dart';

class PendingInspections extends ConsumerWidget {
  final String mandalId;
  const PendingInspections({super.key, required this.mandalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return facilitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (facilities) {
        final inspections = inspectionsAsync.valueOrNull ?? <Inspection>[];
        final mandalFacilities =
            facilities.where((f) => f.mandalId == mandalId).toList();

        // Latest inspection per facility
        final latestByFacility = <String, Inspection>{};
        for (final i in inspections) {
          final existing = latestByFacility[i.facilityId];
          if (existing == null || i.datetime.isAfter(existing.datetime)) {
            latestByFacility[i.facilityId] = i;
          }
        }

        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));

        // Facilities not inspected in the last 7 days
        final pending = mandalFacilities.where((f) {
          final latest = latestByFacility[f.id];
          return latest == null || latest.datetime.isBefore(weekAgo);
        }).toList();

        if (pending.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 40, color: FimmsColors.success),
                  SizedBox(height: 8),
                  Text('All facilities inspected this week',
                      style: TextStyle(color: FimmsColors.textMuted)),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '${pending.length} pending inspections',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FimmsColors.textMuted),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: pending.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final f = pending[index];
                  final latest = latestByFacility[f.id];
                  final daysSince = latest != null
                      ? now.difference(latest.datetime).inDays
                      : null;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: FimmsColors.outline),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(f.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(
                        latest != null
                            ? 'Last: ${DateFormat('dd MMM').format(latest.datetime)} ($daysSince days ago)'
                            : 'Never inspected',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: latest != null
                          ? GradeChip(grade: latest.grade, compact: true)
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('NEW',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey)),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
