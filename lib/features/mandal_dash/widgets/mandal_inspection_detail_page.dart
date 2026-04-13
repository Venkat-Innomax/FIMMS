import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/assignment_repository.dart';
import '../../../data/repositories/compliance_repository.dart';
import '../../../models/assignment.dart';
import '../../../models/compliance_item.dart';
import '../../../models/inspection.dart';
import '../../../services/mock_auth_service.dart';
import '../../shared_widgets/grade_chip.dart';

/// Loads compliance items for a specific inspection.
final _inspectionComplianceProvider =
    FutureProvider.family<List<ComplianceItem>, String>(
        (ref, inspectionId) async {
  final all = await ref.read(complianceRepositoryProvider).loadAll();
  return all.where((c) => c.inspectionId == inspectionId).toList();
});

class MandalInspectionDetailPage extends ConsumerWidget {
  final Inspection inspection;
  final String facilityName;
  final String officerName;

  const MandalInspectionDetailPage({
    super.key,
    required this.inspection,
    required this.facilityName,
    required this.officerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complianceAsync =
        ref.watch(_inspectionComplianceProvider(inspection.id));
    final complianceItems = complianceAsync.valueOrNull ?? <ComplianceItem>[];
    final respondedItems =
        complianceItems.where((c) => c.facilityResponse != null).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Inspection ${inspection.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
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
                        GradeChip(
                          grade: inspection.grade,
                          scoreOutOf100: inspection.totalScore,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                            label: 'Officer', value: officerName),
                        _InfoChip(
                            label: 'Date',
                            value: DateFormat('dd MMM yyyy, HH:mm')
                                .format(inspection.datetime)),
                        _InfoChip(
                            label: 'Status',
                            value: inspection.status.label),
                        _InfoChip(
                            label: 'Geofence',
                            value: inspection.geofencePass
                                ? 'Pass'
                                : 'Fail'),
                        if (inspection.urgentFlag)
                          _InfoChip(
                              label: 'Urgent',
                              value:
                                  inspection.urgentReason ?? 'Yes'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Score overview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FimmsColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FimmsColors.outline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    inspection.totalScore.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: inspection.grade.color,
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '/ 100',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: FimmsColors.textMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GradeChip(grade: inspection.grade),
                      const SizedBox(height: 4),
                      Text(
                        inspection.grade.action,
                        style: const TextStyle(
                            fontSize: 11, color: FimmsColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section breakdown
            if (inspection.sections.isNotEmpty) ...[
              const Text('SECTION-WISE BREAKDOWN',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: FimmsColors.textMuted,
                  )),
              const SizedBox(height: 10),
              for (final s in inspection.sections)
                _SectionCard(section: s),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FimmsColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FimmsColors.outline),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: FimmsColors.textMuted),
                    SizedBox(width: 10),
                    Text(
                      'Detailed section data not available for this inspection.',
                      style: TextStyle(
                          fontSize: 12, color: FimmsColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],

            // ── Facility Responses Section ──
            if (respondedItems.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.business,
                      size: 16, color: FimmsColors.primary),
                  const SizedBox(width: 6),
                  const Text('Facility Responses',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: FimmsColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${respondedItems.length}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: FimmsColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Responses submitted by the facility admin on inspection observations. Select responses to attach as evidence when escalating.',
                style: TextStyle(
                    fontSize: 11.5, color: FimmsColors.textMuted),
              ),
              const SizedBox(height: 10),
              for (final item in respondedItems)
                _FacilityResponseCard(item: item),
            ],

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
                FilledButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => _ReinspectDialog(
                      sections: inspection.sections,
                      onConfirm: (feedback, selectedSections) {
                        final user = ref.read(authStateProvider);
                        final assignment = Assignment(
                          id: 'asgn_${DateTime.now().millisecondsSinceEpoch}',
                          facilityId: inspection.facilityId,
                          officerId: inspection.officerId,
                          assignedBy: user?.id ?? 'unknown',
                          dueDate: DateTime.now()
                              .add(const Duration(days: 7)),
                          status: AssignmentStatus.pending,
                          isReinspection: true,
                          inspectionId: inspection.id,
                        );
                        ref
                            .read(assignmentListProvider.notifier)
                            .add(assignment);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Re-inspection ordered'
                              '${selectedSections.isNotEmpty ? ' for ${selectedSections.length} section(s)' : ''}',
                            ),
                            backgroundColor: FimmsColors.success,
                          ),
                        );
                      },
                    ),
                  ),
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Re-inspect'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => _EscalateWithEvidenceDialog(
                      facilityResponses: respondedItems,
                      onConfirm: (comment, attachedIds) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Escalated to District Admin'
                              '${attachedIds.isNotEmpty ? ' with ${attachedIds.length} evidence(s)' : ''}',
                            ),
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
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final SectionResult section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final pct = section.skipped
        ? 0.0
        : (section.maxScore == 0
            ? 0.0
            : section.rawScore / section.maxScore);
    final sectionGrade = GradeX.fromScore(pct * 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FimmsColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FimmsColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (section.skipped)
                  const Text(
                    'SKIPPED',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: FimmsColors.textMuted,
                      letterSpacing: 0.6,
                    ),
                  )
                else
                  Text(
                    '${section.rawScore.toStringAsFixed(0)} / ${section.maxScore.toStringAsFixed(0)}  (${(pct * 100).round()}%)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sectionGrade.color,
                    ),
                  ),
              ],
            ),
            if (!section.skipped) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  children: [
                    Container(height: 6, color: FimmsColors.surface),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0, 1).toDouble(),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: sectionGrade.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (section.remarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes,
                      size: 14, color: FimmsColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      section.remarks,
                      style: const TextStyle(
                          fontSize: 12, color: FimmsColors.textMuted),
                    ),
                  ),
                ],
              ),
            ],
            if (section.photoPaths.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final path in section.photoPaths)
                    _MockPhoto(path: path),
                ],
              ),
            ],
          ],
        ),
      ),
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
          style:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

/// Mock image thumbnail with a colored placeholder based on the file name.
class _MockPhoto extends StatelessWidget {
  final String path;
  const _MockPhoto({required this.path});

  @override
  Widget build(BuildContext context) {
    // Generate a deterministic icon/color from the path
    final hash = path.hashCode;
    final icons = [
      Icons.image,
      Icons.photo_camera,
      Icons.panorama,
      Icons.broken_image_outlined,
      Icons.photo_library,
    ];
    final colors = [
      FimmsColors.primary,
      FimmsColors.secondary,
      Colors.teal,
      Colors.deepOrange,
      Colors.purple,
    ];
    final icon = icons[hash.abs() % icons.length];
    final color = colors[(hash.abs() ~/ 5) % colors.length];
    final fileName = path.split('/').last;

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 64, color: color.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'Mock Evidence Photo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: FimmsColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: FimmsColors.textMuted),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'In production, this would display the actual photo captured by the field officer.',
                        style: TextStyle(
                            fontSize: 11, color: FimmsColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        width: 90,
        height: 72,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 4),
            Text(
              fileName.length > 14
                  ? '${fileName.substring(0, 11)}...'
                  : fileName,
              style: TextStyle(
                fontSize: 8,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Facility response card ──

class _FacilityResponseCard extends StatelessWidget {
  final ComplianceItem item;
  const _FacilityResponseCard({required this.item});

  Color get _statusColor => switch (item.status) {
        ComplianceStatus.pending => FimmsColors.gradeAverage,
        ComplianceStatus.submitted => Colors.blue,
        ComplianceStatus.accepted => FimmsColors.success,
        ComplianceStatus.rejected => FimmsColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FimmsColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FimmsColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.observation,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.status.label,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FimmsColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: FimmsColors.primary.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply,
                          size: 13, color: FimmsColors.primary),
                      SizedBox(width: 4),
                      Text('Facility Response',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: FimmsColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.facilityResponse!,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (item.evidencePaths.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final path in item.evidencePaths)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: FimmsColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: FimmsColors.outline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file,
                              size: 12, color: FimmsColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            path.split('/').last,
                            style: const TextStyle(
                                fontSize: 10,
                                color: FimmsColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (item.respondedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Responded: ${DateFormat('dd MMM yyyy, HH:mm').format(item.respondedAt!)}',
                style: const TextStyle(
                    fontSize: 10, color: FimmsColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Escalate to District with evidence selection ──

class _EscalateWithEvidenceDialog extends StatefulWidget {
  final List<ComplianceItem> facilityResponses;
  final void Function(String? comment, List<String> attachedIds) onConfirm;

  const _EscalateWithEvidenceDialog({
    required this.facilityResponses,
    required this.onConfirm,
  });

  @override
  State<_EscalateWithEvidenceDialog> createState() =>
      _EscalateWithEvidenceDialogState();
}

class _EscalateWithEvidenceDialogState
    extends State<_EscalateWithEvidenceDialog> {
  final _commentController = TextEditingController();
  final _attachedIds = <String>{};

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.north_east, color: Colors.deepOrange, size: 20),
          SizedBox(width: 8),
          Expanded(
              child: Text('Escalate to District Admin',
                  style: TextStyle(fontSize: 16))),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This inspection will be flagged for the District Admin\'s attention for further review and action.',
                style: TextStyle(
                    fontSize: 13, color: FimmsColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: TextStyle(fontSize: 13),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              if (widget.facilityResponses.isNotEmpty) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.attach_file,
                        size: 16, color: FimmsColors.primary),
                    const SizedBox(width: 6),
                    const Text('ATTACH FACILITY RESPONSES',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: FimmsColors.primary,
                        )),
                    const Spacer(),
                    if (_attachedIds.isNotEmpty)
                      Text(
                        '${_attachedIds.length} selected',
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: FimmsColors.primary),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select facility responses to include as supporting evidence.',
                  style: TextStyle(
                      fontSize: 11, color: FimmsColors.textMuted),
                ),
                const SizedBox(height: 8),
                for (final item in widget.facilityResponses)
                  _EvidenceCheckItem(
                    item: item,
                    selected: _attachedIds.contains(item.id),
                    onChanged: (selected) {
                      setState(() {
                        if (selected) {
                          _attachedIds.add(item.id);
                        } else {
                          _attachedIds.remove(item.id);
                        }
                      });
                    },
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_attachedIds.length ==
                            widget.facilityResponses.length) {
                          _attachedIds.clear();
                        } else {
                          _attachedIds.addAll(widget.facilityResponses
                              .map((i) => i.id));
                        }
                      });
                    },
                    icon: Icon(
                      _attachedIds.length ==
                              widget.facilityResponses.length
                          ? Icons.deselect
                          : Icons.select_all,
                      size: 15,
                    ),
                    label: Text(
                      _attachedIds.length ==
                              widget.facilityResponses.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            final comment = _commentController.text.trim();
            widget.onConfirm(
              comment.isEmpty ? null : comment,
              _attachedIds.toList(),
            );
          },
          icon: const Icon(Icons.north_east, size: 16),
          label: Text(
            _attachedIds.isEmpty
                ? 'Escalate'
                : 'Escalate with ${_attachedIds.length} evidence(s)',
            style: const TextStyle(fontSize: 13),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
          ),
        ),
      ],
    );
  }
}

class _EvidenceCheckItem extends StatelessWidget {
  final ComplianceItem item;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _EvidenceCheckItem({
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  Color get _statusColor => switch (item.status) {
        ComplianceStatus.pending => FimmsColors.gradeAverage,
        ComplianceStatus.submitted => Colors.blue,
        ComplianceStatus.accepted => FimmsColors.success,
        ComplianceStatus.rejected => FimmsColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!selected),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? FimmsColors.primary.withValues(alpha: 0.06)
                : FimmsColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? FimmsColors.primary.withValues(alpha: 0.3)
                  : FimmsColors.outline,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 20,
                color: selected
                    ? FimmsColors.primary
                    : FimmsColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.observation,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.facilityResponse!,
                      style: const TextStyle(
                          fontSize: 10.5,
                          color: FimmsColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.evidencePaths.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.attach_file,
                              size: 10,
                              color: FimmsColors.textMuted),
                          const SizedBox(width: 2),
                          Text(
                            '${item.evidencePaths.length} file(s)',
                            style: const TextStyle(
                                fontSize: 9.5,
                                color: FimmsColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(item.status.label,
                    style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: _statusColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for ordering a re-inspection with feedback and section selection.
class _ReinspectDialog extends StatefulWidget {
  final List<SectionResult> sections;
  final void Function(String? feedback, List<String> selectedSections)
      onConfirm;

  const _ReinspectDialog({
    required this.sections,
    required this.onConfirm,
  });

  @override
  State<_ReinspectDialog> createState() => _ReinspectDialogState();
}

class _ReinspectDialogState extends State<_ReinspectDialog> {
  final _feedbackController = TextEditingController();
  final _selectedSections = <String>{};

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.replay, color: Colors.deepOrange, size: 20),
          SizedBox(width: 8),
          Expanded(
              child: Text('Order Re-inspection',
                  style: TextStyle(fontSize: 16))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the sections that need re-inspection and provide feedback for the field officer.',
              style:
                  TextStyle(fontSize: 13, color: FimmsColors.textMuted),
            ),
            if (widget.sections.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('SECTIONS TO RE-INSPECT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: FimmsColors.textMuted,
                  )),
              const SizedBox(height: 6),
              for (final s in widget.sections)
                CheckboxListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(s.title,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '${s.rawScore.toStringAsFixed(0)}/${s.maxScore.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: _selectedSections.contains(s.sectionId),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedSections.add(s.sectionId);
                      } else {
                        _selectedSections.remove(s.sectionId);
                      }
                    });
                  },
                ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (_selectedSections.length ==
                        widget.sections.length) {
                      _selectedSections.clear();
                    } else {
                      _selectedSections.addAll(
                          widget.sections.map((s) => s.sectionId));
                    }
                  });
                },
                icon: Icon(
                  _selectedSections.length == widget.sections.length
                      ? Icons.deselect
                      : Icons.select_all,
                  size: 16,
                ),
                label: Text(
                  _selectedSections.length == widget.sections.length
                      ? 'Deselect All'
                      : 'Select All',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('FEEDBACK / INSTRUCTIONS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: FimmsColors.textMuted,
                )),
            const SizedBox(height: 6),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Provide specific instructions or observations for the field officer...',
                hintStyle: TextStyle(fontSize: 12),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            final feedback = _feedbackController.text.trim();
            widget.onConfirm(
              feedback.isEmpty ? null : feedback,
              _selectedSections.toList(),
            );
          },
          icon: const Icon(Icons.replay, size: 16),
          label: const Text('Order Re-inspection'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.deepOrange,
          ),
        ),
      ],
    );
  }
}
