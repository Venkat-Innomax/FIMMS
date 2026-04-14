import 'package:flutter/material.dart' hide FormField;
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/facility.dart';
import '../../models/form_schema.dart';
import '../../models/inspection.dart';
import '../../services/geolocation_service.dart';
import '../../services/scoring_engine.dart';
import '../inspection_form/inspection_form_notifier.dart';
import '../shared_widgets/grade_chip.dart';

/// Full read-only preview of a completed inspection form.
/// Pushed (not go-routed) on top of [InspectionPage] so the form state stays
/// alive. The officer can pop back to edit or confirm to submit.
class InspectionPreviewPage extends StatelessWidget {
  final Facility facility;
  final FormSchema schema;
  final InspectionFormState formState;
  final GpsFix? gpsFix;
  final bool geofencePass;
  final String officerName;
  final VoidCallback onConfirmSubmit;

  const InspectionPreviewPage({
    super.key,
    required this.facility,
    required this.schema,
    required this.formState,
    required this.gpsFix,
    required this.geofencePass,
    required this.officerName,
    required this.onConfirmSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final scoring = ScoringEngine.compute(
      schema: schema,
      responses: formState.responses,
      subType: facility.subType,
      skippedSections: formState.skippedSections,
    );

    final completedCount = schema.sections
        .where((s) => !formState.skippedSections.contains(s.id))
        .length;
    final skippedCount = formState.skippedSections.length;

    return Scaffold(
      backgroundColor: FimmsColors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to edit',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Review Inspection'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.edit_outlined, size: 16,
                color: Colors.white),
            label: const Text('Edit',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Banner ───────────────────────────────────────────────
                  _ReviewBanner(
                      completedCount: completedCount,
                      skippedCount: skippedCount,
                      scoring: scoring),
                  const SizedBox(height: 14),

                  // ── Inspection header ─────────────────────────────────────
                  _HeaderCard(
                    facility: facility,
                    officerName: officerName,
                    gpsFix: gpsFix,
                    geofencePass: geofencePass,
                  ),
                  const SizedBox(height: 14),

                  // ── Urgent flag ───────────────────────────────────────────
                  if (formState.urgentFlag)
                    _UrgentCard(reason: formState.urgentReason),
                  if (formState.urgentFlag) const SizedBox(height: 14),

                  // ── Sections ─────────────────────────────────────────────
                  for (int i = 0; i < schema.sections.length; i++) ...[
                    _SectionPreviewCard(
                      index: i,
                      section: schema.sections[i],
                      subType: facility.subType,
                      responses: formState.responses,
                      remarks: formState.remarksBySection[
                          schema.sections[i].id],
                      photoCount: formState.photosBySection[
                              schema.sections[i].id]
                          ?.length ??
                          0,
                      skipped: formState.skippedSections
                          .contains(schema.sections[i].id),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),

          // ── Sticky bottom action bar ──────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionBar(
              scoring: scoring,
              onEdit: () => Navigator.of(context).pop(),
              onSubmit: () => _confirmDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline,
            color: FimmsColors.gradeExcellent, size: 44),
        title: const Text('Submit Inspection?',
            textAlign: TextAlign.center),
        content: const Text(
          'Once submitted, this inspection cannot be modified.\n\n'
          'Make sure all details are correct before confirming.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Go Back'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirmSubmit();
            },
            icon: const Icon(Icons.send_outlined, size: 16),
            label: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review banner — summary stats at the top
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewBanner extends StatelessWidget {
  final int completedCount;
  final int skippedCount;
  final ScoringResult scoring;

  const _ReviewBanner({
    required this.completedCount,
    required this.skippedCount,
    required this.scoring,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FimmsColors.primary,
            FimmsColors.primary.withValues(alpha: 0.80),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined,
                  color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'INSPECTION REVIEW',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BannerStat(
                  label: 'Sections Done',
                  value: '$completedCount'),
              const SizedBox(width: 16),
              if (skippedCount > 0) ...[
                _BannerStat(
                    label: 'Skipped', value: '$skippedCount'),
                const SizedBox(width: 16),
              ],
              _BannerStat(
                  label: 'Est. Score',
                  value:
                      '${scoring.totalOutOf100.toStringAsFixed(0)}/100'),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Grade',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70)),
                  const SizedBox(height: 2),
                  GradeChip(grade: scoring.grade),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  const _BannerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header card — facility info + GPS + officer
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final Facility facility;
  final String officerName;
  final GpsFix? gpsFix;
  final bool geofencePass;

  const _HeaderCard({
    required this.facility,
    required this.officerName,
    required this.gpsFix,
    required this.geofencePass,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _typeBadge(facility.type.label),
              const SizedBox(width: 8),
              Text(facility.subTypeLabel,
                  style: const TextStyle(
                      fontSize: 11.5, color: FimmsColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(facility.name,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          Text(
            '${facility.village}, ${_cap(facility.mandalId)} Mandal',
            style: const TextStyle(
                fontSize: 12, color: FimmsColors.textMuted),
          ),
          const Divider(height: 20),
          _Row(Icons.person_outline, 'Officer', officerName),
          _Row(Icons.calendar_today_outlined, 'Date',
              DateFormat('EEE, d MMM yyyy · h:mm a').format(now)),
          _Row(
            Icons.my_location,
            'GPS',
            gpsFix == null
                ? 'Not captured'
                : '${gpsFix!.position.latitude.toStringAsFixed(5)}, '
                    '${gpsFix!.position.longitude.toStringAsFixed(5)}'
                    '${gpsFix!.simulated ? " (simulated)" : ""}',
          ),
          const SizedBox(height: 8),
          _GeofencePill(passed: geofencePass),
        ],
      ),
    );
  }

  Widget _typeBadge(String label) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: FimmsColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: FimmsColors.primary,
          ),
        ),
      );

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: FimmsColors.textMuted),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11.5,
                    color: FimmsColors.textMuted,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _GeofencePill extends StatelessWidget {
  final bool passed;
  const _GeofencePill({required this.passed});

  @override
  Widget build(BuildContext context) {
    final color =
        passed ? FimmsColors.gradeExcellent : FimmsColors.gradeCritical;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              passed
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              size: 13,
              color: color),
          const SizedBox(width: 5),
          Text(
            passed ? 'Geo-fence PASSED' : 'Geo-fence FAILED',
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Urgent card
// ─────────────────────────────────────────────────────────────────────────────

class _UrgentCard extends StatelessWidget {
  final String? reason;
  const _UrgentCard({this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FimmsColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: FimmsColors.secondary, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_fire_department,
              color: FimmsColors.secondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('URGENT FLAG SET',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: FimmsColors.secondary,
                        letterSpacing: 0.5)),
                if (reason != null && reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(reason!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: FimmsColors.textPrimary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section preview card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionPreviewCard extends StatefulWidget {
  final int index;
  final FormSection section;
  final String subType;
  final Map<String, dynamic> responses;
  final String? remarks;
  final int photoCount;
  final bool skipped;

  const _SectionPreviewCard({
    required this.index,
    required this.section,
    required this.subType,
    required this.responses,
    required this.remarks,
    required this.photoCount,
    required this.skipped,
  });

  @override
  State<_SectionPreviewCard> createState() =>
      _SectionPreviewCardState();
}

class _SectionPreviewCardState extends State<_SectionPreviewCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final visibleFields = section.fields
        .where((f) => f.isVisibleFor(widget.subType))
        .toList();

    final answeredCount = visibleFields
        .where((f) =>
            widget.responses.containsKey('${section.id}.${f.id}'))
        .length;

    return Container(
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.skipped
              ? FimmsColors.outline
              : answeredCount == visibleFields.length
                  ? FimmsColors.gradeExcellent.withValues(alpha: 0.4)
                  : FimmsColors.warning.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Section header — tappable to expand/collapse
          InkWell(
            onTap: widget.skipped
                ? null
                : () =>
                    setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  // Section number badge
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          FimmsColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: FimmsColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        Text(
                          widget.skipped
                              ? 'Skipped'
                              : '$answeredCount / ${visibleFields.length} fields answered',
                          style: const TextStyle(
                              fontSize: 11,
                              color: FimmsColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  _SectionStatusChip(
                      skipped: widget.skipped,
                      answered: answeredCount,
                      total: visibleFields.length),
                  if (!widget.skipped) ...[
                    const SizedBox(width: 6),
                    Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: FimmsColors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Field answers
          if (!widget.skipped && _expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in visibleFields) ...[
                    _FieldAnswerRow(
                      field: f,
                      value: widget.responses[
                          '${section.id}.${f.id}'],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Remarks
                  if (widget.remarks != null &&
                      widget.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const Divider(),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_outlined,
                            size: 13,
                            color: FimmsColors.textMuted),
                        const SizedBox(width: 6),
                        const Text('Remarks:  ',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: FimmsColors.textMuted)),
                        Expanded(
                          child: Text(widget.remarks!,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],

                  // Photos
                  if (widget.photoCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.photo_camera_outlined,
                            size: 13,
                            color: FimmsColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.photoCount} photo${widget.photoCount == 1 ? '' : 's'} attached',
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: FimmsColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionStatusChip extends StatelessWidget {
  final bool skipped;
  final int answered;
  final int total;
  const _SectionStatusChip(
      {required this.skipped,
      required this.answered,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    if (skipped) {
      color = FimmsColors.textMuted;
      label = 'SKIPPED';
      icon = Icons.block;
    } else if (answered == total) {
      color = FimmsColors.gradeExcellent;
      label = 'COMPLETE';
      icon = Icons.check_circle_outline;
    } else {
      color = FimmsColors.warning;
      label = 'PARTIAL';
      icon = Icons.pending_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field answer row — label + read-only value
// ─────────────────────────────────────────────────────────────────────────────

class _FieldAnswerRow extends StatelessWidget {
  final FormField field;
  final dynamic value;

  const _FieldAnswerRow({required this.field, required this.value});

  @override
  Widget build(BuildContext context) {
    final displayValue = _format(value);
    final hasValue = displayValue != null && displayValue.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: hasValue
            ? FimmsColors.surface
            : FimmsColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasValue
              ? FimmsColors.outline
              : FimmsColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              field.label,
              style: const TextStyle(
                  fontSize: 12, color: FimmsColors.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: hasValue
                ? Text(
                    displayValue!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700),
                  )
                : const Text(
                    'Not answered',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: FimmsColors.warning,
                        fontStyle: FontStyle.italic),
                  ),
          ),
        ],
      ),
    );
  }

  String? _format(dynamic v) {
    if (v == null) return null;
    if (field.type == FieldType.staffTable) {
      if (v is List) {
        return '${v.length} staff row${v.length == 1 ? '' : 's'} recorded';
      }
      return null;
    }
    return v.toString().isEmpty ? null : v.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky bottom action bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final ScoringResult scoring;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;

  const _BottomActionBar({
    required this.scoring,
    required this.onEdit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        border: const Border(
            top: BorderSide(color: FimmsColors.outline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score preview pill
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  scoring.grade.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: scoring.grade.color
                      .withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scoring.totalOutOf100.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scoring.grade.color,
                  ),
                ),
                Text(
                  scoring.grade.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: scoring.grade.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Edit button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Form'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Submit button
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text('Confirm & Submit'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
