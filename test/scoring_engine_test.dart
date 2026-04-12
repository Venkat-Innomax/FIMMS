import 'package:fimms_demo/models/form_schema.dart';
import 'package:fimms_demo/models/inspection.dart';
import 'package:fimms_demo/services/scoring_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A small two-section schema used to validate the scoring logic.
  final schema = FormSchema(
    id: 'test',
    title: 'Test',
    sections: [
      FormSection(
        id: 's1',
        title: 'Sec 1',
        maxScore: 20,
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
            label: 'Good/Avg/Poor',
            type: FieldType.goodAvgPoor,
            scored: true,
            weight: 2,
          ),
        ],
      ),
      FormSection(
        id: 's2',
        title: 'Sec 2',
        maxScore: 10,
        fields: [
          FormField(
            id: 'q3',
            label: 'Avail/Partial/NA',
            type: FieldType.availPartialNa,
            scored: true,
            weight: 2,
          ),
        ],
      ),
    ],
  );

  group('ScoringEngine', () {
    test('perfect answers → 100 / Excellent', () {
      final result = ScoringEngine.compute(
        schema: schema,
        responses: {
          's1.q1': 'yes',
          's1.q2': 'good',
          's2.q3': 'available',
        },
        subType: 'any',
        skippedSections: {},
      );
      expect(result.totalOutOf100, closeTo(100, 0.01));
      expect(result.grade, Grade.excellent);
    });

    test('half marks on good_avg_poor average', () {
      final result = ScoringEngine.compute(
        schema: schema,
        responses: {
          's1.q1': 'yes',
          's1.q2': 'average',
          's2.q3': 'available',
        },
        subType: 'any',
        skippedSections: {},
      );
      // s1: q1 full (2), q2 half (1) => 3/4. s1 max_score = 20.
      // s1 contribution = 3/4 * (20/30 * 100) = 50.
      // s2: full 1/1 => 1. s2 contribution = 1 * (10/30 * 100) = 33.33.
      // Total = 83.33 → Good grade (70-84).
      expect(result.totalOutOf100, closeTo(83.33, 0.5));
      expect(result.grade, Grade.good);
    });

    test('all poor answers → Critical grade', () {
      final result = ScoringEngine.compute(
        schema: schema,
        responses: {
          's1.q1': 'no',
          's1.q2': 'poor',
          's2.q3': 'not_available',
        },
        subType: 'any',
        skippedSections: {},
      );
      expect(result.totalOutOf100, 0);
      expect(result.grade, Grade.critical);
    });

    test('Grade bands from score', () {
      expect(GradeX.fromScore(100), Grade.excellent);
      expect(GradeX.fromScore(85), Grade.excellent);
      expect(GradeX.fromScore(84.99), Grade.good);
      expect(GradeX.fromScore(70), Grade.good);
      expect(GradeX.fromScore(69), Grade.average);
      expect(GradeX.fromScore(50), Grade.average);
      expect(GradeX.fromScore(49), Grade.poor);
      expect(GradeX.fromScore(35), Grade.poor);
      expect(GradeX.fromScore(34), Grade.critical);
      expect(GradeX.fromScore(0), Grade.critical);
    });

    test('skipped section redistributes weight (spec §4.3)', () {
      // Skip s2. s1 should then be worth 100% of the total.
      final result = ScoringEngine.compute(
        schema: schema,
        responses: {
          's1.q1': 'yes',
          's1.q2': 'good',
        },
        subType: 'any',
        skippedSections: {'s2'},
      );
      expect(result.totalOutOf100, closeTo(100, 0.01));
    });

    test('staff_table: present>=sanctioned full, >=75% half, else 0', () {
      final staffSchema = FormSchema(
        id: 'staff',
        title: 'Staff only',
        sections: [
          FormSection(
            id: 'sec',
            title: 'Staff',
            maxScore: 25,
            fields: [
              FormField(
                id: 'table',
                label: 'Roster',
                type: FieldType.staffTable,
                scored: true,
                weight: 25,
                staffRoles: [
                  StaffRole(id: 'a', label: 'A'),
                  StaffRole(id: 'b', label: 'B'),
                  StaffRole(id: 'c', label: 'C'),
                ],
              ),
            ],
          ),
        ],
      );
      final result = ScoringEngine.compute(
        schema: staffSchema,
        responses: {
          'sec.table': [
            {'role_id': 'a', 'sanctioned': 4, 'present': 4}, // full
            {'role_id': 'b', 'sanctioned': 4, 'present': 3}, // 75% → half
            {'role_id': 'c', 'sanctioned': 4, 'present': 2}, // 50% → zero
          ],
        },
        subType: 'any',
        skippedSections: {},
      );
      // Avg fraction = (1 + 0.5 + 0) / 3 = 0.5 → section 50% → total 50.
      expect(result.totalOutOf100, closeTo(50, 0.5));
      expect(result.grade, Grade.average);
    });

    test('conditional visibility hides fields for sub-type', () {
      final schemaWithHide = FormSchema(
        id: 'hide',
        title: 'Hide test',
        sections: [
          FormSection(
            id: 'sec',
            title: 'sec',
            maxScore: 10,
            fields: [
              FormField(
                id: 'always',
                label: 'always',
                type: FieldType.yesNo,
                scored: true,
                weight: 2,
              ),
              FormField(
                id: 'only_dh',
                label: 'only DH',
                type: FieldType.yesNo,
                scored: true,
                weight: 2,
                showFor: ['dh'],
              ),
            ],
          ),
        ],
      );
      // For PHC the only_dh field is hidden — its "no" answer must not
      // drag down the score.
      final phcResult = ScoringEngine.compute(
        schema: schemaWithHide,
        responses: {
          'sec.always': 'yes',
          'sec.only_dh': 'no',
        },
        subType: 'phc',
        skippedSections: {},
      );
      expect(phcResult.totalOutOf100, closeTo(100, 0.01));

      // For DH the field IS included. Score drops to 50%.
      final dhResult = ScoringEngine.compute(
        schema: schemaWithHide,
        responses: {
          'sec.always': 'yes',
          'sec.only_dh': 'no',
        },
        subType: 'dh',
        skippedSections: {},
      );
      expect(dhResult.totalOutOf100, closeTo(50, 0.5));
    });
  });
}
