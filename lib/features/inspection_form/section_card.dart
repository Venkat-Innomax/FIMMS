import 'package:flutter/material.dart' hide FormField;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/form_schema.dart';
import 'field_renderer.dart';
import 'inspection_form_notifier.dart';
import 'section_footer.dart';

/// Renders a single form section. Shows a status chip (incomplete / ready /
/// skipped), the per-field list, and a footer with remarks + photos.
class SectionCard extends ConsumerWidget {
  final FormSchema schema;
  final FormSection section;
  final String subType;
  final int index;

  const SectionCard({
    super.key,
    required this.schema,
    required this.section,
    required this.subType,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspectionFormProvider(schema));
    final notifier = ref.read(inspectionFormProvider(schema).notifier);

    final visibleFields =
        section.fields.where((f) => f.isVisibleFor(subType)).toList();
    final skipped = state.skippedSections.contains(section.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: FimmsColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            number: index + 1,
            title: section.title,
            maxScore: section.maxScore,
            status: _statusOf(state, visibleFields),
            skipped: skipped,
          ),
          if (skipped)
            const _SkippedBanner()
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in visibleFields) ...[
                    FieldRenderer(
                      field: f,
                      value: state.responses['${section.id}.${f.id}'],
                      onChanged: (v) =>
                          notifier.setResponse(section.id, f.id, v),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Divider(),
                  const SizedBox(height: 8),
                  SectionFooter(schema: schema, section: section),
                ],
              ),
            ),
        ],
      ),
    );
  }

  _SectionStatus _statusOf(
    InspectionFormState state,
    List<FormField> visibleFields,
  ) {
    if (state.skippedSections.contains(section.id)) {
      return _SectionStatus.skipped;
    }
    // Determine if every scored field has a response.
    bool allAnswered = true;
    for (final f in visibleFields) {
      if (!f.scored) continue;
      final key = '${section.id}.${f.id}';
      final v = state.responses[key];
      if (f.type == FieldType.staffTable) {
        if (v is! List || v.isEmpty) {
          allAnswered = false;
          break;
        }
      } else if (v == null || v == '') {
        allAnswered = false;
        break;
      }
    }
    final remarksOk = (state.remarksBySection[section.id] ?? '').trim().length >=
        AppConstants.minRemarksChars;
    final photosOk = (state.photosBySection[section.id]?.length ?? 0) >=
        AppConstants.minPhotosPerSection;
    if (allAnswered && remarksOk && photosOk) return _SectionStatus.ready;
    return _SectionStatus.incomplete;
  }
}

enum _SectionStatus { incomplete, ready, skipped }

class _Header extends StatelessWidget {
  final int number;
  final String title;
  final double maxScore;
  final _SectionStatus status;
  final bool skipped;

  const _Header({
    required this.number,
    required this.title,
    required this.maxScore,
    required this.status,
    required this.skipped,
  });

  @override
  Widget build(BuildContext context) {
    late Color statusColor;
    late String statusLabel;
    late IconData icon;
    switch (status) {
      case _SectionStatus.incomplete:
        statusColor = FimmsColors.gradeAverage;
        statusLabel = 'INCOMPLETE';
        icon = Icons.pending_outlined;
        break;
      case _SectionStatus.ready:
        statusColor = FimmsColors.gradeExcellent;
        statusLabel = 'READY';
        icon = Icons.check_circle_outline;
        break;
      case _SectionStatus.skipped:
        statusColor = FimmsColors.textMuted;
        statusLabel = 'SKIPPED';
        icon = Icons.block;
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FimmsColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              number.toString(),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: FimmsColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Max score ${maxScore.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: FimmsColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkippedBanner extends StatelessWidget {
  const _SkippedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      decoration: BoxDecoration(
        color: FimmsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: const Row(
        children: [
          Icon(Icons.block, size: 16, color: FimmsColors.textMuted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Section skipped. Weight will be redistributed across the other sections (spec §4.3).',
              style: TextStyle(
                fontSize: 12,
                color: FimmsColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
