import 'package:fimms_demo/models/form_schema.dart';
import 'package:fimms_demo/services/inspection_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final schema = FormSchema(
    id: 'test',
    title: 'Test',
    sections: [
      FormSection(
        id: 's1',
        title: 'Sec 1',
        maxScore: 10,
        requiresRemarks: true,
        requiresPhoto: true,
        fields: [
          FormField(
            id: 'q1',
            label: 'Yes/No',
            type: FieldType.yesNo,
            scored: true,
            weight: 2,
          ),
          FormField(
            id: 'q2',
            label: 'Condition',
            type: FieldType.goodAvgPoor,
            scored: true,
            weight: 2,
          ),
        ],
      ),
    ],
  );

  group('InspectionValidator', () {
    test('passes when everything is valid', () {
      final result = InspectionValidator.validate(
        schema: schema,
        responses: {'s1.q1': 'yes', 's1.q2': 'good'},
        remarksBySection: {'s1': 'All fine and clean today'},
        photosBySection: {'s1': ['sample:one']},
        skippedSections: {},
        subType: 'any',
        urgentFlag: false,
        urgentReason: null,
        geofencePassed: true,
      );
      expect(result.passed, isTrue);
    });

    test('geo-fence failure is reported as header issue', () {
      final result = InspectionValidator.validate(
        schema: schema,
        responses: {'s1.q1': 'yes', 's1.q2': 'good'},
        remarksBySection: {'s1': 'All fine and clean today'},
        photosBySection: {'s1': ['sample:one']},
        skippedSections: {},
        subType: 'any',
        urgentFlag: false,
        urgentReason: null,
        geofencePassed: false,
      );
      expect(result.passed, isFalse);
      expect(
        result.issues.any((i) => i.message.toLowerCase().contains('geo-fence')),
        isTrue,
      );
    });

    test('missing remarks blocks submission', () {
      final result = InspectionValidator.validate(
        schema: schema,
        responses: {'s1.q1': 'yes', 's1.q2': 'good'},
        remarksBySection: {'s1': 'short'},
        photosBySection: {'s1': ['sample:one']},
        skippedSections: {},
        subType: 'any',
        urgentFlag: false,
        urgentReason: null,
        geofencePassed: true,
      );
      expect(result.passed, isFalse);
    });

    test('missing photos blocks submission', () {
      final result = InspectionValidator.validate(
        schema: schema,
        responses: {'s1.q1': 'yes', 's1.q2': 'good'},
        remarksBySection: {'s1': 'All fine and clean today'},
        photosBySection: {'s1': []},
        skippedSections: {},
        subType: 'any',
        urgentFlag: false,
        urgentReason: null,
        geofencePassed: true,
      );
      expect(result.passed, isFalse);
      expect(
        result.issues.any((i) => i.message.toLowerCase().contains('photo')),
        isTrue,
      );
    });

    test('poor answer forces remarks (already required, still enforced)', () {
      final result = InspectionValidator.validate(
        schema: schema,
        responses: {'s1.q1': 'yes', 's1.q2': 'poor'},
        remarksBySection: {'s1': ''},
        photosBySection: {'s1': ['sample:one']},
        skippedSections: {},
        subType: 'any',
        urgentFlag: false,
        urgentReason: null,
        geofencePassed: true,
      );
      expect(result.passed, isFalse);
    });

    test('urgent flag without reason blocks submission', () {
      final result = InspectionValidator.validate(
        schema: schema,
        responses: {'s1.q1': 'yes', 's1.q2': 'good'},
        remarksBySection: {'s1': 'All fine and clean today'},
        photosBySection: {'s1': ['sample:one']},
        skippedSections: {},
        subType: 'any',
        urgentFlag: true,
        urgentReason: null,
        geofencePassed: true,
      );
      expect(result.passed, isFalse);
      expect(
        result.issues.any((i) => i.message.toLowerCase().contains('urgent')),
        isTrue,
      );
    });

    test('incomplete answer blocks submission', () {
      final result = InspectionValidator.validate(
        schema: schema,
        responses: {'s1.q1': 'yes'}, // q2 missing
        remarksBySection: {'s1': 'All fine and clean today'},
        photosBySection: {'s1': ['sample:one']},
        skippedSections: {},
        subType: 'any',
        urgentFlag: false,
        urgentReason: null,
        geofencePassed: true,
      );
      expect(result.passed, isFalse);
    });
  });
}
