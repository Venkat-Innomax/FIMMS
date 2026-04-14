import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../models/complaint.dart';
import '../../../models/user.dart';
import '../../../services/mock_auth_service.dart';
import '../../grievance/widgets/complaint_timeline.dart';
import 'escalation_dialog.dart';
import 'merge_dialog.dart';
import 'resolution_form.dart';

// ---------------------------------------------------------------------------
// Identity masking utilities
// ---------------------------------------------------------------------------

String _maskName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.map((p) {
    if (p.length <= 1) return p;
    return '${p[0]}${'*' * (p.length - 2)}${p[p.length - 1]}';
  }).join(' ');
}


bool _canViewIdentity(Role? role) =>
    role == Role.grievanceOfficer || role == Role.collector || role == Role.admin;

// ---------------------------------------------------------------------------

class ComplaintDetailPage extends ConsumerWidget {
  final Complaint complaint;
  final String facilityName;

  const ComplaintDetailPage({
    super.key,
    required this.complaint,
    required this.facilityName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider);
    final showIdentity = _canViewIdentity(currentUser?.role);
    return Scaffold(
      appBar: AppBar(title: Text('Complaint ${complaint.id}')),
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
                        _StatusBadge(status: complaint.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _InfoChip(
                            label: 'Category',
                            value: complaint.category.label),
                        _InfoChip(
                            label: 'Priority',
                            value: complaint.priority.label),
                        _InfoChip(
                            label: 'By',
                            value: showIdentity
                                ? complaint.submittedBy
                                : _maskName(complaint.submittedBy)),
                        if (!showIdentity)
                          const _InfoChip(
                              label: 'Identity',
                              value: '🔒 Restricted'),
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
              child: Text(complaint.description,
                  style: const TextStyle(fontSize: 13)),
            ),

            if (complaint.evidencePaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Evidence (${complaint.evidencePaths.length} files)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < complaint.evidencePaths.length; i++)
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

            if (complaint.resolution != null) ...[
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
                    Text(complaint.resolution!,
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
            ComplaintTimeline(timeline: complaint.timeline),

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
                OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => EscalationDialog(
                      title: 'Escalate to Mandal Officer',
                      description:
                          'This complaint will be forwarded to the Mandal Officer responsible for the facility\'s mandal for review and action.',
                      onConfirm: (comment) {
                        final user = ref.read(authStateProvider);
                        final updated = complaint.copyWith(
                          status: ComplaintStatus.escalatedToMandal,
                          escalatedBy: user?.id,
                          timeline: [
                            ...complaint.timeline,
                            StatusChange(
                              status: ComplaintStatus.escalatedToMandal,
                              datetime: DateTime.now(),
                              comment: comment ??
                                  'Escalated to Mandal Officer',
                              changedBy: user?.id ?? 'unknown',
                            ),
                          ],
                        );
                        ref
                            .read(complaintListProvider.notifier)
                            .update(updated);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Complaint escalated to Mandal Officer'),
                            backgroundColor: FimmsColors.success,
                          ),
                        );
                      },
                    ),
                  ),
                  icon: const Icon(Icons.north_east, size: 16),
                  label: const Text('Escalate to Mandal'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange),
                ),
                FilledButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => const ResolutionForm(),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Mark Resolved'),
                ),
                OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => MergeDialog(
                        currentComplaintId: complaint.id,
                        facilityId: complaint.facilityId),
                  ),
                  icon: const Icon(Icons.merge, size: 16),
                  label: const Text('Merge with...'),
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
