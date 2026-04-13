import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../models/complaint.dart';
import '../../../services/mock_auth_service.dart';
import '../../grievance/widgets/complaint_timeline.dart';
import '../../grievance_admin/widgets/escalation_dialog.dart';
import '../../grievance_admin/widgets/resolution_form.dart';

class MandalComplaintDetailPage extends ConsumerWidget {
  final Complaint complaint;
  final String facilityName;

  const MandalComplaintDetailPage({
    super.key,
    required this.complaint,
    required this.facilityName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaints = ref.watch(complaintListProvider);
    final liveComplaint =
        complaints.where((c) => c.id == complaint.id).firstOrNull ??
            complaint;

    return Scaffold(
      appBar: AppBar(title: Text('Complaint ${liveComplaint.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
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
                        Expanded(
                          child: Text(facilityName,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ),
                        _StatusBadge(status: liveComplaint.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _InfoChip(
                            label: 'Category',
                            value: liveComplaint.category.label),
                        _InfoChip(
                            label: 'Priority',
                            value: liveComplaint.priority.label),
                        _InfoChip(
                            label: 'By',
                            value: liveComplaint.submittedBy),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            const Text('Description',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FimmsColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(liveComplaint.description,
                  style: const TextStyle(fontSize: 13)),
            ),

            if (liveComplaint.evidencePaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                  'Evidence (${liveComplaint.evidencePaths.length} files)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0;
                      i < liveComplaint.evidencePaths.length;
                      i++)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: FimmsColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: FimmsColors.outline),
                      ),
                      child: const Center(
                        child: Icon(Icons.image,
                            size: 30, color: FimmsColors.textMuted),
                      ),
                    ),
                ],
              ),
            ],

            if (liveComplaint.resolution != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      FimmsColors.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          FimmsColors.success.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resolution',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: FimmsColors.success)),
                    const SizedBox(height: 4),
                    Text(liveComplaint.resolution!,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Text('Timeline',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ComplaintTimeline(timeline: liveComplaint.timeline),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text('Actions',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (liveComplaint.status ==
                    ComplaintStatus.escalatedToMandal) ...[
                  OutlinedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => EscalationDialog(
                        title: 'Escalate to District Admin',
                        description:
                            'This complaint will be forwarded to the District Admin for district-level action and oversight.',
                        onConfirm: (comment) {
                          final user = ref.read(authStateProvider);
                          final updated = liveComplaint.copyWith(
                            status:
                                ComplaintStatus.escalatedToDistrict,
                            escalatedTo: 'u_admin',
                            escalatedBy: user?.id,
                            timeline: [
                              ...liveComplaint.timeline,
                              StatusChange(
                                status: ComplaintStatus
                                    .escalatedToDistrict,
                                datetime: DateTime.now(),
                                comment: comment ??
                                    'Escalated to District Admin',
                                changedBy: user?.id ?? 'unknown',
                              ),
                            ],
                          );
                          ref
                              .read(complaintListProvider.notifier)
                              .update(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Complaint escalated to District Admin'),
                              backgroundColor: FimmsColors.success,
                            ),
                          );
                        },
                      ),
                    ),
                    icon: const Icon(Icons.north_east, size: 16),
                    label: const Text('Escalate to District'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => EscalationDialog(
                        title: 'Request Inspection',
                        description:
                            'Request a formal facility inspection from the District Admin to investigate this complaint on-site.',
                        onConfirm: (comment) {
                          final user = ref.read(authStateProvider);
                          final updated = liveComplaint.copyWith(
                            status:
                                ComplaintStatus.inspectionRequested,
                            escalatedTo: 'u_admin',
                            escalatedBy: user?.id,
                            timeline: [
                              ...liveComplaint.timeline,
                              StatusChange(
                                status: ComplaintStatus
                                    .inspectionRequested,
                                datetime: DateTime.now(),
                                comment: comment ??
                                    'Inspection requested',
                                changedBy: user?.id ?? 'unknown',
                              ),
                            ],
                          );
                          ref
                              .read(complaintListProvider.notifier)
                              .update(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Inspection request sent'),
                              backgroundColor: FimmsColors.success,
                            ),
                          );
                        },
                      ),
                    ),
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Request Inspection'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal),
                  ),
                ],
                FilledButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => const ResolutionForm(),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Mark Resolved'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ComplaintStatus status;
  const _StatusBadge({required this.status});

  Color get _color => switch (status) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FimmsColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$label: $value',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
