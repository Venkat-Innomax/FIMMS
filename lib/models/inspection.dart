import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';

/// Grade bands from spec §4.2.
enum Grade { excellent, good, average, poor, critical }

extension GradeX on Grade {
  String get label {
    switch (this) {
      case Grade.excellent:
        return 'Excellent';
      case Grade.good:
        return 'Good';
      case Grade.average:
        return 'Average';
      case Grade.poor:
        return 'Poor';
      case Grade.critical:
        return 'Critical';
    }
  }

  /// Grade → colour mapping from spec §4.2.
  Color get color {
    switch (this) {
      case Grade.excellent:
        return FimmsColors.gradeExcellent;
      case Grade.good:
        return FimmsColors.gradeGood;
      case Grade.average:
        return FimmsColors.gradeAverage;
      case Grade.poor:
        return FimmsColors.gradePoor;
      case Grade.critical:
        return FimmsColors.gradeCritical;
    }
  }

  /// Action column text from spec §4.2.
  String get action {
    switch (this) {
      case Grade.excellent:
        return 'No action required';
      case Grade.good:
        return 'Monitor';
      case Grade.average:
        return 'Follow-up required';
      case Grade.poor:
        return 'Reinspection within 7 days';
      case Grade.critical:
        return 'Immediate escalation to Collector';
    }
  }

  /// Apply grade bands from spec §4.2.
  static Grade fromScore(double totalOutOf100) {
    if (totalOutOf100 >= 85) return Grade.excellent;
    if (totalOutOf100 >= 70) return Grade.good;
    if (totalOutOf100 >= 50) return Grade.average;
    if (totalOutOf100 >= 35) return Grade.poor;
    return Grade.critical;
  }

  static Grade fromString(String raw) {
    switch (raw) {
      case 'excellent':
        return Grade.excellent;
      case 'good':
        return Grade.good;
      case 'average':
        return Grade.average;
      case 'poor':
        return Grade.poor;
      case 'critical':
        return Grade.critical;
      default:
        throw ArgumentError('Unknown grade: $raw');
    }
  }
}

class SectionResult {
  final String sectionId;
  final String title;
  final double rawScore;
  final double maxScore;
  final double normalizedOutOf100;
  final Map<String, dynamic> fieldResponses;
  final String remarks;
  final List<String> photoPaths;
  final bool skipped;

  const SectionResult({
    required this.sectionId,
    required this.title,
    required this.rawScore,
    required this.maxScore,
    required this.normalizedOutOf100,
    required this.fieldResponses,
    required this.remarks,
    required this.photoPaths,
    required this.skipped,
  });

  factory SectionResult.fromJson(Map<String, dynamic> json) => SectionResult(
        sectionId: json['section_id'] as String,
        title: json['title'] as String? ?? '',
        rawScore: (json['raw_score'] as num).toDouble(),
        maxScore: (json['max_score'] as num).toDouble(),
        normalizedOutOf100:
            (json['normalized'] as num?)?.toDouble() ?? 0,
        fieldResponses:
            (json['field_responses'] as Map?)?.cast<String, dynamic>() ?? {},
        remarks: json['remarks'] as String? ?? '',
        photoPaths: (json['photo_paths'] as List?)?.cast<String>() ?? const [],
        skipped: json['skipped'] as bool? ?? false,
      );
}

class Inspection {
  final String id;
  final String facilityId;
  final String officerId;
  final DateTime datetime;
  final LatLng gps;
  final bool geofencePass;
  final bool urgentFlag;
  final String? urgentReason;
  final List<SectionResult> sections;
  final double totalScore; // 0–100
  final Grade grade;

  const Inspection({
    required this.id,
    required this.facilityId,
    required this.officerId,
    required this.datetime,
    required this.gps,
    required this.geofencePass,
    required this.urgentFlag,
    required this.sections,
    required this.totalScore,
    required this.grade,
    this.urgentReason,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) => Inspection(
        id: json['id'] as String,
        facilityId: json['facility_id'] as String,
        officerId: json['officer_id'] as String,
        datetime: DateTime.parse(json['datetime'] as String),
        gps: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        geofencePass: json['geofence_pass'] as bool? ?? true,
        urgentFlag: json['urgent_flag'] as bool? ?? false,
        urgentReason: json['urgent_reason'] as String?,
        sections: ((json['sections'] as List?) ?? const [])
            .map((e) => SectionResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalScore: (json['total_score'] as num).toDouble(),
        grade: GradeX.fromString(json['grade'] as String),
      );
}
