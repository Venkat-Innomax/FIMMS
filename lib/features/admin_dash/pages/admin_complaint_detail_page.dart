import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/assignment_repository.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/facility_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/assignment.dart';
import '../../../models/complaint.dart';
import '../../../models/facility.dart';
import '../../../models/user.dart';
import '../../../services/mock_auth_service.dart';
import '../../grievance/widgets/complaint_timeline.dart';
import '../../grievance_admin/widgets/resolution_form.dart';

class AdminComplaintDetailPage extends ConsumerWidget {
  final Complaint complaint;
  final String facilityName;

  const AdminComplaintDetailPage({
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
                        if (liveComplaint.escalatedBy != null)
                          _InfoChip(
                              label: 'Escalated by',
                              value: liveComplaint.escalatedBy!),
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
                        ComplaintStatus.escalatedToDistrict ||
                    liveComplaint.status ==
                        ComplaintStatus.inspectionRequested)
                  FilledButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _AssignInspectionSheet(
                        complaint: liveComplaint,
                        facilityName: facilityName,
                      ),
                    ),
                    icon: const Icon(Icons.assignment_add, size: 16),
                    label: const Text('Assign Inspection'),
                  ),
                OutlinedButton.icon(
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

class _AssignInspectionSheet extends ConsumerStatefulWidget {
  final Complaint complaint;
  final String facilityName;

  const _AssignInspectionSheet({
    required this.complaint,
    required this.facilityName,
  });

  @override
  ConsumerState<_AssignInspectionSheet> createState() =>
      _AssignInspectionSheetState();
}

class _AssignInspectionSheetState
    extends ConsumerState<_AssignInspectionSheet> {
  User? _selectedOfficer;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _dueDate = DateTime.now().add(const Duration(days: 3));
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final users = usersAsync.valueOrNull ?? <User>[];
    final facilities = facilitiesAsync.valueOrNull ?? <Facility>[];
    final facilityMap = {for (final f in facilities) f.id: f};
    final facility = facilityMap[widget.complaint.facilityId];

    // Filter field officers, preferring those in the same mandal
    final fieldOfficers =
        users.where((u) => u.role == Role.fieldOfficer).toList();
    final mandalOfficers = facility != null
        ? fieldOfficers
            .where((u) => u.mandalId == facility.mandalId)
            .toList()
        : fieldOfficers;
    final displayOfficers =
        mandalOfficers.isNotEmpty ? mandalOfficers : fieldOfficers;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_add,
                  size: 18, color: FimmsColors.primary),
              const SizedBox(width: 8),
              Text(
                'ASSIGN INSPECTION',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: FimmsColors.primary,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Facility (pre-filled, read-only)
          const Text('Facility',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: FimmsColors.textMuted)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FimmsColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FimmsColors.outline),
            ),
            child: Text(widget.facilityName,
                style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 14),

          // Field Officer dropdown
          const Text('Field Officer',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: FimmsColors.textMuted)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FimmsColors.outline),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<User>(
                isExpanded: true,
                hint: const Text('Select officer',
                    style: TextStyle(fontSize: 13)),
                value: _selectedOfficer,
                items: displayOfficers
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(
                            '${u.name}${u.mandalId != null ? ' (${u.mandalId})' : ''}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: (u) =>
                    setState(() => _selectedOfficer = u),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Due Date
          const Text('Due Date',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: FimmsColors.textMuted)),
          const SizedBox(height: 4),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime.now(),
                lastDate:
                    DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FimmsColors.outline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: FimmsColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(_dueDate),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Assign button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selectedOfficer != null
                  ? () => _assign(context, ref)
                  : null,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Assign Inspection'),
            ),
          ),
        ],
      ),
    );
  }

  void _assign(BuildContext context, WidgetRef ref) {
    final user = ref.read(authStateProvider);
    final assignment = Assignment(
      id: 'asgn_${DateTime.now().millisecondsSinceEpoch}',
      facilityId: widget.complaint.facilityId,
      officerId: _selectedOfficer!.id,
      assignedBy: user?.id ?? 'u_admin',
      dueDate: _dueDate,
      status: AssignmentStatus.pending,
    );
    ref.read(assignmentListProvider.notifier).add(assignment);

    final updated = widget.complaint.copyWith(
      status: ComplaintStatus.inspectionAssigned,
      timeline: [
        ...widget.complaint.timeline,
        StatusChange(
          status: ComplaintStatus.inspectionAssigned,
          datetime: DateTime.now(),
          comment:
              'Inspection assigned to ${_selectedOfficer!.name}, due ${DateFormat('dd MMM yyyy').format(_dueDate)}',
          changedBy: user?.id ?? 'u_admin',
        ),
      ],
    );
    ref.read(complaintListProvider.notifier).update(updated);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Inspection assigned to ${_selectedOfficer!.name}',
        ),
        backgroundColor: FimmsColors.success,
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
