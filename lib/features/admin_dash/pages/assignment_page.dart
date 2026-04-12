import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/assignment_repository.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/assignment.dart';
import '../../../models/facility.dart';
import '../../../models/user.dart';

final _assignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  return ref.read(assignmentRepositoryProvider).loadAll();
});

class AssignmentPage extends ConsumerStatefulWidget {
  const AssignmentPage({super.key});

  @override
  ConsumerState<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends ConsumerState<AssignmentPage> {
  AssignmentStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(_assignmentsProvider);
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final usersAsync = ref.watch(usersProvider);

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assignments) {
        final facilities = facilitiesAsync.valueOrNull ?? <Facility>[];
        final users = usersAsync.valueOrNull ?? <User>[];

        final facilityMap = {for (final f in facilities) f.id: f};
        final userMap = {for (final u in users) u.id: u};

        var filtered = assignments;
        if (_statusFilter != null) {
          filtered =
              filtered.where((a) => a.status == _statusFilter).toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('${filtered.length} assignments',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FimmsColors.textMuted)),
                  const Spacer(),
                  _StatusFilter(
                    selected: _statusFilter,
                    onChanged: (s) => setState(() => _statusFilter = s),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final a = filtered[index];
                  final facility = facilityMap[a.facilityId];
                  final officer = userMap[a.officerId];
                  return _AssignmentCard(
                    assignment: a,
                    facilityName: facility?.name ?? a.facilityId,
                    officerName: officer?.name ?? a.officerId,
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

class _StatusFilter extends StatelessWidget {
  final AssignmentStatus? selected;
  final ValueChanged<AssignmentStatus?> onChanged;
  const _StatusFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: selected == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final s in AssignmentStatus.values)
          FilterChip(
            label: Text(s.label),
            selected: selected == s,
            onSelected: (_) => onChanged(s),
          ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final String facilityName;
  final String officerName;

  const _AssignmentCard({
    required this.assignment,
    required this.facilityName,
    required this.officerName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: FimmsColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (assignment.isReinspection)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: FimmsColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('RE-INSPECT',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: FimmsColors.secondary)),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(facilityName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Officer: $officerName',
                      style: const TextStyle(
                          fontSize: 12, color: FimmsColors.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusChip(status: assignment.status),
                const SizedBox(height: 4),
                Text(
                  'Due: ${DateFormat('dd MMM').format(assignment.dueDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: assignment.dueDate.isBefore(DateTime.now())
                        ? FimmsColors.danger
                        : FimmsColors.textMuted,
                    fontWeight: assignment.dueDate.isBefore(DateTime.now())
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AssignmentStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (status) {
      AssignmentStatus.pending => (Colors.blue, Icons.schedule),
      AssignmentStatus.inProgress => (Colors.orange, Icons.play_arrow),
      AssignmentStatus.completed => (FimmsColors.success, Icons.check_circle),
      AssignmentStatus.overdue => (FimmsColors.danger, Icons.warning),
      AssignmentStatus.cancelled => (Colors.grey, Icons.cancel),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
