import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/complaint.dart';
import 'complaint_timeline.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final String facilityName;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.facilityName,
  });

  IconData get _categoryIcon => switch (complaint.category) {
        ComplaintCategory.infrastructure => Icons.construction,
        ComplaintCategory.food => Icons.restaurant,
        ComplaintCategory.hygiene => Icons.cleaning_services,
        ComplaintCategory.safety => Icons.security,
        ComplaintCategory.staff => Icons.people,
        ComplaintCategory.medical => Icons.medical_services,
        ComplaintCategory.other => Icons.help_outline,
      };

  Color get _statusColor => switch (complaint.status) {
        ComplaintStatus.submitted => Colors.blue,
        ComplaintStatus.underReview => Colors.amber.shade700,
        ComplaintStatus.assigned => Colors.orange,
        ComplaintStatus.inProgress => Colors.purple,
        ComplaintStatus.escalatedToMandal => Colors.deepOrange,
        ComplaintStatus.escalatedToDistrict => Colors.red.shade700,
        ComplaintStatus.inspectionRequested => Colors.teal,
        ComplaintStatus.inspectionAssigned => FimmsColors.primary,
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
      child: ExpansionTile(
        leading: Icon(_categoryIcon, color: FimmsColors.primary, size: 22),
        title: Text(
          complaint.description,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              '$facilityName · ${DateFormat('dd MMM').format(complaint.createdAt)}',
              style: const TextStyle(fontSize: 11, color: FimmsColors.textMuted),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                complaint.status.label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor),
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: FimmsColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(complaint.category.label,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: FimmsColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Priority: ${complaint.priority.label}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(complaint.description,
                    style: const TextStyle(fontSize: 13)),
                if (complaint.evidencePaths.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${complaint.evidencePaths.length} evidence file(s)',
                    style: const TextStyle(
                        fontSize: 11, color: FimmsColors.textMuted),
                  ),
                ],
                if (complaint.resolution != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FimmsColors.success.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: FimmsColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resolution',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: FimmsColors.success)),
                        const SizedBox(height: 4),
                        Text(complaint.resolution!,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Timeline',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ComplaintTimeline(timeline: complaint.timeline),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
