import '../core/constants.dart';
import '../models/form_schema.dart';
import 'scoring_engine.dart';

class ValidationIssue {
  final String sectionId;
  final String? fieldId;
  final String message;
  const ValidationIssue({
    required this.sectionId,
    required this.message,
    this.fieldId,
  });
}

class ValidationResult {
  final List<ValidationIssue> issues;
  final bool passed;
  const ValidationResult(this.issues) : passed = issues.length == 0;
}

/// Implements the client-side subset of spec §5 rules:
/// * geo-fence 100m (checked externally — validator receives the result)
/// * mandatory photo per section
/// * mandatory remarks >= 10 chars per section
/// * non-compliant answers force remarks
/// * urgent flag -> reason required
/// * min checklist completion (all visible scored fields answered)
class InspectionValidator {
  static ValidationResult validate({
    required FormSchema schema,
    required Responses responses,
    required Map<String, String> remarksBySection,
    required Map<String, List<String>> photosBySection,
    required Set<String> skippedSections,
    required String subType,
    required bool urgentFlag,
    required String? urgentReason,
    required bool geofencePassed,
  }) {
    final issues = <ValidationIssue>[];

    if (!geofencePassed) {
      issues.add(const ValidationIssue(
        sectionId: '__header',
        message:
            'Geo-fence check failed — officer is outside ${AppConstants.geofenceRadiusMeters}m of the facility',
      ));
    }

    if (urgentFlag) {
      if (urgentReason == null || urgentReason.trim().length < 5) {
        issues.add(const ValidationIssue(
          sectionId: '__header',
          fieldId: 'urgent_reason',
          message: 'Urgent flag requires a reason (min 5 characters)',
        ));
      }
    }

    for (final section in schema.sections) {
      if (skippedSections.contains(section.id)) continue;

      bool sectionHasNonCompliant = false;

      for (final field in section.fields) {
        if (!field.isVisibleFor(subType)) continue;
        final key = '${section.id}.${field.id}';
        final response = responses[key];

        // Completeness
        if (field.scored) {
          if (field.type == FieldType.staffTable) {
            final rows = response is List ? response : const [];
            if (rows.isEmpty) {
              issues.add(ValidationIssue(
                sectionId: section.id,
                fieldId: field.id,
                message:
                    '${section.title}: staff roster requires at least one row',
              ));
            }
          } else if (response == null || response == '') {
            issues.add(ValidationIssue(
              sectionId: section.id,
              fieldId: field.id,
              message: '${section.title}: "${field.label}" is required',
            ));
          }
        }

        if (_isNonCompliant(field, response)) {
          sectionHasNonCompliant = true;
        }
      }

      // Remarks
      if (section.requiresRemarks) {
        final remarks = (remarksBySection[section.id] ?? '').trim();
        if (remarks.length < AppConstants.minRemarksChars) {
          issues.add(ValidationIssue(
            sectionId: section.id,
            fieldId: 'remarks',
            message:
                '${section.title}: remarks must be at least ${AppConstants.minRemarksChars} characters',
          ));
        }
      }

      if (sectionHasNonCompliant) {
        final remarks = (remarksBySection[section.id] ?? '').trim();
        if (remarks.length < AppConstants.minRemarksChars) {
          issues.add(ValidationIssue(
            sectionId: section.id,
            message:
                '${section.title}: non-compliant findings require explanatory remarks',
          ));
        }
      }

      // Photos
      if (section.requiresPhoto) {
        final photos = photosBySection[section.id] ?? const [];
        if (photos.length < AppConstants.minPhotosPerSection) {
          issues.add(ValidationIssue(
            sectionId: section.id,
            fieldId: 'photos',
            message:
                '${section.title}: at least ${AppConstants.minPhotosPerSection} photo required',
          ));
        }
      }
    }

    return ValidationResult(issues);
  }

  static bool _isNonCompliant(FormField field, dynamic response) {
    if (response == null) return false;
    switch (field.type) {
      case FieldType.goodAvgPoor:
        return response == 'poor';
      case FieldType.availPartialNa:
        return response == 'not_available';
      case FieldType.yesNo:
        // "No" is non-compliant EXCEPT when the helper text marks it as
        // the compliant answer (e.g. "expired medicines: yes is
        // non-compliant").
        final invert =
            (field.helper ?? '').toLowerCase().contains('non-compliant');
        return invert ? response == 'yes' : response == 'no';
      case FieldType.yesNoNa:
        return response == 'no';
      case FieldType.regularInterruptedNa:
        return response == 'not_available';
      default:
        return false;
    }
  }
}
