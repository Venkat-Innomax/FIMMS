/// Status of a compliance item raised from an inspection.
enum ComplianceStatus { pending, submitted, accepted, rejected }

extension ComplianceStatusX on ComplianceStatus {
  String get label {
    switch (this) {
      case ComplianceStatus.pending:
        return 'Pending';
      case ComplianceStatus.submitted:
        return 'Submitted';
      case ComplianceStatus.accepted:
        return 'Accepted';
      case ComplianceStatus.rejected:
        return 'Rejected';
    }
  }

  static ComplianceStatus fromString(String raw) {
    switch (raw) {
      case 'pending':
        return ComplianceStatus.pending;
      case 'submitted':
        return ComplianceStatus.submitted;
      case 'accepted':
        return ComplianceStatus.accepted;
      case 'rejected':
        return ComplianceStatus.rejected;
      default:
        return ComplianceStatus.pending;
    }
  }
}

/// A single compliance observation derived from an inspection section.
class ComplianceItem {
  final String id;
  final String inspectionId;
  final String facilityId;
  final String sectionId;
  final String observation;
  final String? facilityResponse;
  final List<String> evidencePaths;
  final ComplianceStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const ComplianceItem({
    required this.id,
    required this.inspectionId,
    required this.facilityId,
    required this.sectionId,
    required this.observation,
    this.facilityResponse,
    this.evidencePaths = const [],
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory ComplianceItem.fromJson(Map<String, dynamic> json) => ComplianceItem(
        id: json['id'] as String,
        inspectionId: json['inspection_id'] as String,
        facilityId: json['facility_id'] as String,
        sectionId: json['section_id'] as String,
        observation: json['observation'] as String,
        facilityResponse: json['facility_response'] as String?,
        evidencePaths:
            (json['evidence_paths'] as List?)?.cast<String>() ?? const [],
        status: ComplianceStatusX.fromString(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        respondedAt: json['responded_at'] != null
            ? DateTime.parse(json['responded_at'] as String)
            : null,
      );
}
