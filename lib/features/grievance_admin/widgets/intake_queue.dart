import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/complaint.dart';
import '../../../models/facility.dart';
import 'complaint_detail_page.dart';
import 'triage_dialog.dart';

class IntakeQueue extends StatelessWidget {
  final List<Complaint> complaints;
  final Map<String, Facility> facilityMap;

  const IntakeQueue({
    super.key,
    required this.complaints,
    required this.facilityMap,
  });

  @override
  Widget build(BuildContext context) {
    if (complaints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 48, color: FimmsColors.textMuted),
            SizedBox(height: 12),
            Text('No complaints in this queue',
                style: TextStyle(color: FimmsColors.textMuted)),
          ],
        ),
      );
    }

    final sorted = List.of(complaints)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = sorted[index];
        final facility = facilityMap[c.facilityId];
        return _ComplaintRow(
          complaint: c,
          facilityName: facility?.name ?? c.facilityId,
        );
      },
    );
  }
}

class _ComplaintRow extends StatelessWidget {
  final Complaint complaint;
  final String facilityName;

  const _ComplaintRow({
    required this.complaint,
    required this.facilityName,
  });

  Color get _priorityColor => switch (complaint.priority) {
        ComplaintPriority.low => Colors.grey,
        ComplaintPriority.medium => Colors.blue,
        ComplaintPriority.high => Colors.orange,
        ComplaintPriority.critical => FimmsColors.danger,
      };

  Color get _statusColor => switch (complaint.status) {
        ComplaintStatus.submitted => Colors.blue,
        ComplaintStatus.underReview => Colors.amber.shade700,
        ComplaintStatus.assigned => Colors.orange,
        ComplaintStatus.inProgress => Colors.purple,
        ComplaintStatus.resolved => FimmsColors.success,
        ComplaintStatus.closed => Colors.grey,
        ComplaintStatus.draft => Colors.grey.shade400,
      };

  @override
  Widget build(BuildContext context) {
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
            builder: (_) => ComplaintDetailPage(
              complaint: complaint,
              facilityName: facilityName,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(facilityName,
                            style: const TextStyle(
                                fontSize: 11,
                                color: FimmsColors.textMuted)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: FimmsColors.surface,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(complaint.category.label,
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(complaint.status.label,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _statusColor)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM').format(complaint.createdAt),
                    style: const TextStyle(
                        fontSize: 10, color: FimmsColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              if (complaint.status == ComplaintStatus.submitted ||
                  complaint.status == ComplaintStatus.underReview)
                IconButton(
                  icon: const Icon(Icons.assignment_turned_in, size: 20),
                  tooltip: 'Triage',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) =>
                        TriageDialog(complaint: complaint),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
