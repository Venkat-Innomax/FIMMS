import '../models/form_schema.dart';
import '../models/inspection.dart';

/// Response values used across the form. Kept as a Map of primitives so
/// the scoring engine is a pure function of schema + responses.
typedef Responses = Map<String, dynamic>;

/// Result per section after scoring.
class ScoredSection {
  final String sectionId;
  final String title;
  final double rawScore; // 0..weighted max
  final double adjustedMaxScore; // max after Kitchen redistribution
  final double originalMaxScore;
  final bool skipped;

  const ScoredSection({
    required this.sectionId,
    required this.title,
    required this.rawScore,
    required this.adjustedMaxScore,
    required this.originalMaxScore,
    required this.skipped,
  });
}

/// Scoring result for a full inspection.
class ScoringResult {
  final List<ScoredSection> sections;
  final double totalOutOf100;
  final Grade grade;

  const ScoringResult({
    required this.sections,
    required this.totalOutOf100,
    required this.grade,
  });
}

/// Pure scoring engine implementing spec §4.2.
///
/// Field-type rules:
///   yes_no                 : yes = full, no = 0
///   yes_no_na              : yes = full, no = 0, na = excluded from scoring
///   good_avg_poor          : good = full, avg = half, poor = 0
///   avail_partial_na       : avail = full, partial = half, na/unavail = 0
///   regular_interrupted_na : regular = full, interrupted = half, na = 0
///   staff_table            : per-role (present >= sanctioned) = full,
///                            (>= 75%) = half, else 0. Averaged across rows.
///   number / text / dropdown (unscored): not counted.
class ScoringEngine {
  /// Compute the section-by-section score using the schema + responses.
  /// [subType] governs conditional visibility (spec §4.4 showFor/hideFor).
  static ScoringResult compute({
    required FormSchema schema,
    required Responses responses,
    required String subType,
    required Set<String> skippedSections,
  }) {
    final scored = <ScoredSection>[];

    for (final section in schema.sections) {
      final skipped = skippedSections.contains(section.id);
      double sectionRaw = 0;
      double sectionMax = 0;

      if (!skipped) {
        for (final field in section.fields) {
          if (!field.isVisibleFor(subType)) continue;
          if (!field.scored) continue;

          final response = responses['${section.id}.${field.id}'];
          final fieldMax = field.weight;

          final rule = _scoreField(field, response);
          if (rule.excluded) continue; // NA and similar — excluded from max
          sectionMax += fieldMax;
          sectionRaw += fieldMax * rule.fraction;
        }
      }

      scored.add(ScoredSection(
        sectionId: section.id,
        title: section.title,
        rawScore: sectionRaw,
        adjustedMaxScore: sectionMax, // may still be refined below
        originalMaxScore: section.maxScore,
        skipped: skipped,
      ));
    }

    // Normalize each section to its spec max (or 0 if skipped).
    // Then redistribute skipped section weight proportionally across the
    // rest (spec §4.3 note).
    final totalOriginalMax =
        schema.sections.fold<double>(0, (s, x) => s + x.maxScore);
    final skippedMax = scored
        .where((s) => s.skipped)
        .fold<double>(0, (s, x) => s + x.originalMaxScore);
    final remainingMax = totalOriginalMax - skippedMax;

    double totalOutOf100 = 0;

    for (final s in scored) {
      if (s.skipped) continue;
      final normalizedWithinSection =
          s.adjustedMaxScore == 0 ? 0 : s.rawScore / s.adjustedMaxScore;
      final sectionOutOf100 = remainingMax == 0
          ? 0
          : (s.originalMaxScore / remainingMax) * 100;
      totalOutOf100 += (normalizedWithinSection * sectionOutOf100);
    }

    totalOutOf100 = totalOutOf100.clamp(0, 100).toDouble();
    final grade = GradeX.fromScore(totalOutOf100);

    return ScoringResult(
      sections: scored,
      totalOutOf100: totalOutOf100,
      grade: grade,
    );
  }

  static _ScoreRule _scoreField(FormField field, dynamic response) {
    if (response == null) return const _ScoreRule(0);

    switch (field.type) {
      case FieldType.yesNo:
        // For the "expired meds" question (and similar) "yes" is the
        // non-compliant answer. We look at the helper text containing
        // "non-compliant" as an inversion signal.
        final invert =
            (field.helper ?? '').toLowerCase().contains('non-compliant');
        final yes = response == 'yes' || response == true;
        final pass = invert ? !yes : yes;
        return _ScoreRule(pass ? 1.0 : 0.0);

      case FieldType.yesNoNa:
        if (response == 'na') return const _ScoreRule.excluded();
        final yes = response == 'yes';
        return _ScoreRule(yes ? 1.0 : 0.0);

      case FieldType.goodAvgPoor:
        if (response == 'good') return const _ScoreRule(1.0);
        if (response == 'average') return const _ScoreRule(0.5);
        return const _ScoreRule(0.0);

      case FieldType.availPartialNa:
        if (response == 'available') return const _ScoreRule(1.0);
        if (response == 'partial') return const _ScoreRule(0.5);
        return const _ScoreRule(0.0);

      case FieldType.regularInterruptedNa:
        if (response == 'regular') return const _ScoreRule(1.0);
        if (response == 'interrupted') return const _ScoreRule(0.5);
        return const _ScoreRule(0.0);

      case FieldType.staffTable:
        if (response is! List || response.isEmpty) {
          return const _ScoreRule(0.0);
        }
        double fractionSum = 0;
        int counted = 0;
        for (final row in response) {
          if (row is! Map) continue;
          final sanctioned = (row['sanctioned'] as num?)?.toDouble() ?? 0;
          final present = (row['present'] as num?)?.toDouble() ?? 0;
          if (sanctioned <= 0) continue;
          counted++;
          final ratio = present / sanctioned;
          if (ratio >= 1.0) {
            fractionSum += 1.0;
          } else if (ratio >= 0.75) {
            fractionSum += 0.5;
          } else {
            fractionSum += 0.0;
          }
        }
        if (counted == 0) return const _ScoreRule(0.0);
        return _ScoreRule(fractionSum / counted);

      case FieldType.number:
      case FieldType.text:
      case FieldType.date:
      case FieldType.time:
      case FieldType.dropdown:
        return const _ScoreRule.excluded();
    }
  }
}

class _ScoreRule {
  final double fraction; // 0..1
  final bool excluded;
  const _ScoreRule(this.fraction) : excluded = false;
  const _ScoreRule.excluded()
      : fraction = 0,
        excluded = true;
}
