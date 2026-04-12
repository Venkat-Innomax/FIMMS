/// Lifecycle status of a grievance complaint.
enum ComplaintStatus {
  draft,
  submitted,
  underReview,
  assigned,
  inProgress,
  resolved,
  closed,
}

extension ComplaintStatusX on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.draft:
        return 'Draft';
      case ComplaintStatus.submitted:
        return 'Submitted';
      case ComplaintStatus.underReview:
        return 'Under Review';
      case ComplaintStatus.assigned:
        return 'Assigned';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
    }
  }

  static ComplaintStatus fromString(String raw) {
    switch (raw) {
      case 'draft':
        return ComplaintStatus.draft;
      case 'submitted':
        return ComplaintStatus.submitted;
      case 'under_review':
        return ComplaintStatus.underReview;
      case 'assigned':
        return ComplaintStatus.assigned;
      case 'in_progress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'closed':
        return ComplaintStatus.closed;
      default:
        return ComplaintStatus.submitted;
    }
  }
}

/// Category of a grievance complaint.
enum ComplaintCategory {
  infrastructure,
  food,
  hygiene,
  safety,
  staff,
  medical,
  other,
}

extension ComplaintCategoryX on ComplaintCategory {
  String get label {
    switch (this) {
      case ComplaintCategory.infrastructure:
        return 'Infrastructure';
      case ComplaintCategory.food:
        return 'Food & Nutrition';
      case ComplaintCategory.hygiene:
        return 'Hygiene & Sanitation';
      case ComplaintCategory.safety:
        return 'Safety & Security';
      case ComplaintCategory.staff:
        return 'Staff & Administration';
      case ComplaintCategory.medical:
        return 'Medical Services';
      case ComplaintCategory.other:
        return 'Other';
    }
  }

  static ComplaintCategory fromString(String raw) {
    switch (raw) {
      case 'infrastructure':
        return ComplaintCategory.infrastructure;
      case 'food':
        return ComplaintCategory.food;
      case 'hygiene':
        return ComplaintCategory.hygiene;
      case 'safety':
        return ComplaintCategory.safety;
      case 'staff':
        return ComplaintCategory.staff;
      case 'medical':
        return ComplaintCategory.medical;
      default:
        return ComplaintCategory.other;
    }
  }
}

/// Priority level for a complaint (set during triage).
enum ComplaintPriority { low, medium, high, critical }

extension ComplaintPriorityX on ComplaintPriority {
  String get label {
    switch (this) {
      case ComplaintPriority.low:
        return 'Low';
      case ComplaintPriority.medium:
        return 'Medium';
      case ComplaintPriority.high:
        return 'High';
      case ComplaintPriority.critical:
        return 'Critical';
    }
  }

  static ComplaintPriority fromString(String raw) {
    switch (raw) {
      case 'low':
        return ComplaintPriority.low;
      case 'medium':
        return ComplaintPriority.medium;
      case 'high':
        return ComplaintPriority.high;
      case 'critical':
        return ComplaintPriority.critical;
      default:
        return ComplaintPriority.medium;
    }
  }
}

/// A single status change in the complaint timeline.
class StatusChange {
  final ComplaintStatus status;
  final DateTime datetime;
  final String? comment;
  final String changedBy;

  const StatusChange({
    required this.status,
    required this.datetime,
    this.comment,
    required this.changedBy,
  });

  factory StatusChange.fromJson(Map<String, dynamic> json) => StatusChange(
        status: ComplaintStatusX.fromString(json['status'] as String),
        datetime: DateTime.parse(json['datetime'] as String),
        comment: json['comment'] as String?,
        changedBy: json['changed_by'] as String,
      );
}

/// A grievance complaint lodged by a student/parent/guardian.
class Complaint {
  final String id;
  final String facilityId;
  final String submittedBy;
  final ComplaintCategory category;
  final String description;
  final List<String> evidencePaths;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final DateTime createdAt;
  final List<StatusChange> timeline;
  final String? assignedTo;
  final String? resolution;
  final String? mergedIntoId;

  const Complaint({
    required this.id,
    required this.facilityId,
    required this.submittedBy,
    required this.category,
    required this.description,
    this.evidencePaths = const [],
    required this.status,
    this.priority = ComplaintPriority.medium,
    required this.createdAt,
    this.timeline = const [],
    this.assignedTo,
    this.resolution,
    this.mergedIntoId,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
        id: json['id'] as String,
        facilityId: json['facility_id'] as String,
        submittedBy: json['submitted_by'] as String,
        category:
            ComplaintCategoryX.fromString(json['category'] as String),
        description: json['description'] as String,
        evidencePaths:
            (json['evidence_paths'] as List?)?.cast<String>() ?? const [],
        status: ComplaintStatusX.fromString(json['status'] as String),
        priority: json['priority'] != null
            ? ComplaintPriorityX.fromString(json['priority'] as String)
            : ComplaintPriority.medium,
        createdAt: DateTime.parse(json['created_at'] as String),
        timeline: ((json['timeline'] as List?) ?? const [])
            .map((e) => StatusChange.fromJson(e as Map<String, dynamic>))
            .toList(),
        assignedTo: json['assigned_to'] as String?,
        resolution: json['resolution'] as String?,
        mergedIntoId: json['merged_into_id'] as String?,
      );
}
