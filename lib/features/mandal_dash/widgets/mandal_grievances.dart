import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../models/complaint.dart';
import '../../../models/facility.dart';
import 'mandal_complaint_detail_page.dart';

class MandalGrievances extends ConsumerWidget {
  final String mandalId;
  const MandalGrievances({super.key, required this.mandalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaints = ref.watch(complaintListProvider);
    final facilitiesAsync = ref.watch(moduleFacilitiesProvider);
    final facilities = facilitiesAsync.valueOrNull ?? <Facility>[];
    final facilityMap = {for (final f in facilities) f.id: f};

    final mandalComplaints = complaints.where((c) {
      final facility = facilityMap[c.facilityId];
      if (facility == null || facility.mandalId != mandalId) return false;
      return c.status == ComplaintStatus.escalatedToMandal ||
          c.status == ComplaintStatus.escalatedToDistrict ||
          c.status == ComplaintStatus.inspectionRequested ||
          c.status == ComplaintStatus.inspectionAssigned;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mandalComplaints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: FimmsColors.textMuted),
            SizedBox(height: 12),
            Text('No escalated grievances',
                style: TextStyle(color: FimmsColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mandalComplaints.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = mandalComplaints[index];
        final facility = facilityMap[c.facilityId];
        return _MandalComplaintRow(
          complaint: c,
          facilityName: facility?.name ?? c.facilityId,
        );
      },
    );
  }
}

class _MandalComplaintRow extends StatelessWidget {
  final Complaint complaint;
  final String facilityName;

  const _MandalComplaintRow({
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
        ComplaintStatus.escalatedToMandal => Colors.deepOrange,
        ComplaintStatus.escalatedToDistrict => Colors.red.shade700,
        ComplaintStatus.inspectionRequested => Colors.teal,
        ComplaintStatus.inspectionAssigned => FimmsColors.primary,
        ComplaintStatus.resolved => FimmsColors.success,
        _ => Colors.grey,
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
            builder: (_) => MandalComplaintDetailPage(
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
            ],
          ),
        ),
      ),
    );
  }
}
