/// A review action taken on an inspection by a supervisor or nodal officer.
class ReviewAction {
  final String id;
  final String inspectionId;
  final String reviewerId;
  final String action; // 'approve', 'reject', 'reinspect'
  final String? comments;
  final DateTime datetime;

  const ReviewAction({
    required this.id,
    required this.inspectionId,
    required this.reviewerId,
    required this.action,
    this.comments,
    required this.datetime,
  });

  factory ReviewAction.fromJson(Map<String, dynamic> json) => ReviewAction(
        id: json['id'] as String,
        inspectionId: json['inspection_id'] as String,
        reviewerId: json['reviewer_id'] as String,
        action: json['action'] as String,
        comments: json['comments'] as String?,
        datetime: DateTime.parse(json['datetime'] as String),
      );
}
