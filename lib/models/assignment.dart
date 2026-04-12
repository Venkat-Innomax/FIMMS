/// Status of an inspection assignment.
enum AssignmentStatus { pending, inProgress, completed, overdue, cancelled }

extension AssignmentStatusX on AssignmentStatus {
  String get label {
    switch (this) {
      case AssignmentStatus.pending:
        return 'Pending';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.completed:
        return 'Completed';
      case AssignmentStatus.overdue:
        return 'Overdue';
      case AssignmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  static AssignmentStatus fromString(String raw) {
    switch (raw) {
      case 'pending':
        return AssignmentStatus.pending;
      case 'in_progress':
        return AssignmentStatus.inProgress;
      case 'completed':
        return AssignmentStatus.completed;
      case 'overdue':
        return AssignmentStatus.overdue;
      case 'cancelled':
        return AssignmentStatus.cancelled;
      default:
        return AssignmentStatus.pending;
    }
  }
}

/// An inspection assignment linking a facility to a field officer.
class Assignment {
  final String id;
  final String facilityId;
  final String officerId;
  final String assignedBy;
  final DateTime dueDate;
  final AssignmentStatus status;
  final bool isReinspection;
  final String? inspectionId;

  const Assignment({
    required this.id,
    required this.facilityId,
    required this.officerId,
    required this.assignedBy,
    required this.dueDate,
    required this.status,
    this.isReinspection = false,
    this.inspectionId,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id'] as String,
        facilityId: json['facility_id'] as String,
        officerId: json['officer_id'] as String,
        assignedBy: json['assigned_by'] as String,
        dueDate: DateTime.parse(json['due_date'] as String),
        status: AssignmentStatusX.fromString(json['status'] as String),
        isReinspection: json['is_reinspection'] as bool? ?? false,
        inspectionId: json['inspection_id'] as String?,
      );
}
