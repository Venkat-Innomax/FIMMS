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
import 'mandal_inspection_detail_page.dart';

enum _InspectionView { pending, completed }

class PendingInspections extends ConsumerStatefulWidget {
  final String mandalId;
  const PendingInspections({super.key, required this.mandalId});

  @override
  ConsumerState<PendingInspections> createState() =>
      _PendingInspectionsState();
}

class _PendingInspectionsState extends ConsumerState<PendingInspections> {
  _InspectionView _view = _InspectionView.pending;

  @override
  Widget build(BuildContext context) {
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);
    final usersAsync = ref.watch(usersProvider);

    return facilitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (facilities) {
        final inspections = inspectionsAsync.valueOrNull ?? <Inspection>[];
        final users = usersAsync.valueOrNull ?? <User>[];
        final userMap = {for (final u in users) u.id: u};
        final mandalFacilities =
            facilities.where((f) => f.mandalId == widget.mandalId).toList();
        final facilityMap = {for (final f in mandalFacilities) f.id: f};

        // Latest inspection per facility
        final latestByFacility = <String, Inspection>{};
        for (final i in inspections) {
          final existing = latestByFacility[i.facilityId];
          if (existing == null || i.datetime.isAfter(existing.datetime)) {
            latestByFacility[i.facilityId] = i;
          }
        }

        // All inspections for mandal facilities
        final mandalInspections = inspections
            .where((i) => facilityMap.containsKey(i.facilityId))
            .toList()
          ..sort((a, b) => b.datetime.compareTo(a.datetime));

        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));

        // Facilities not inspected in last 7 days
        final pendingFacilities = mandalFacilities.where((f) {
          final latest = latestByFacility[f.id];
          return latest == null || latest.datetime.isBefore(weekAgo);
        }).toList();

        return Column(
          children: [
            // Toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SegmentedButton<_InspectionView>(
                segments: [
                  ButtonSegment(
                    value: _InspectionView.pending,
                    icon: const Icon(Icons.pending_actions, size: 16),
                    label: Text('Pending (${pendingFacilities.length})'),
                  ),
                  ButtonSegment(
                    value: _InspectionView.completed,
                    icon: const Icon(Icons.fact_check, size: 16),
                    label: Text('Inspections (${mandalInspections.length})'),
                  ),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
              ),
            ),
            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _view == _InspectionView.pending
                    ? _PendingList(
                        key: const ValueKey('pending'),
                        pending: pendingFacilities,
                        latestByFacility: latestByFacility,
                      )
                    : _InspectionList(
                        key: const ValueKey('inspections'),
                        inspections: mandalInspections,
                        facilityMap: facilityMap,
                        userMap: userMap,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PendingList extends StatelessWidget {
  final List<Facility> pending;
  final Map<String, Inspection> latestByFacility;

  const _PendingList({
    super.key,
    required this.pending,
    required this.latestByFacility,
  });

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 40, color: FimmsColors.success),
            SizedBox(height: 8),
            Text('All facilities inspected this week',
                style: TextStyle(color: FimmsColors.textMuted)),
          ],
        ),
      );
    }

    final now = DateTime.now();

    return ListView.separated(
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
    );
  }
}

class _InspectionList extends StatelessWidget {
  final List<Inspection> inspections;
  final Map<String, Facility> facilityMap;
  final Map<String, User> userMap;

  const _InspectionList({
    super.key,
    required this.inspections,
    required this.facilityMap,
    required this.userMap,
  });

  Color _statusColor(InspectionStatus status) => switch (status) {
        InspectionStatus.draft => Colors.grey.shade400,
        InspectionStatus.submitted => Colors.blue,
        InspectionStatus.underReview => Colors.amber.shade700,
        InspectionStatus.approved => FimmsColors.success,
        InspectionStatus.rejected => FimmsColors.danger,
        InspectionStatus.reinspectionOrdered => Colors.deepOrange,
      };

  @override
  Widget build(BuildContext context) {
    if (inspections.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 40, color: FimmsColors.textMuted),
            SizedBox(height: 8),
            Text('No inspections found',
                style: TextStyle(color: FimmsColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: inspections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final insp = inspections[index];
        final facility = facilityMap[insp.facilityId];
        final officer = userMap[insp.officerId];

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: FimmsColors.outline),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MandalInspectionDetailPage(
                  inspection: insp,
                  facilityName: facility?.name ?? insp.facilityId,
                  officerName: officer?.name ?? insp.officerId,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Grade bar
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: insp.grade.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility?.name ?? insp.facilityId,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'By: ${officer?.name ?? insp.officerId}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: FimmsColors.textMuted),
                            ),
                            if (insp.urgentFlag) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.local_fire_department,
                                  size: 13, color: FimmsColors.secondary),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GradeChip(
                        grade: insp.grade,
                        compact: true,
                        scoreOutOf100: insp.totalScore,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(insp.status)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              insp.status.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _statusColor(insp.status),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM').format(insp.datetime),
                            style: const TextStyle(
                                fontSize: 10,
                                color: FimmsColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
