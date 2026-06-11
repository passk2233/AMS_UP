/// One cancelled occurrence of a recurring study-plan slot — the backend's
/// `class_cancellations` row. A plan with a cancellation on a given date
/// does not occupy its room that day (the booking conflict check skips it),
/// and the teacher's fixed-schedule list renders the occurrence struck out.
class ClassCancellationModel {
  int id;
  int studyPlanId;
  DateTime cancelDate;
  String? reason;
  int createdBy;
  DateTime? createdAt;

  ClassCancellationModel({
    required this.id,
    required this.studyPlanId,
    required this.cancelDate,
    this.reason,
    required this.createdBy,
    this.createdAt,
  });

  factory ClassCancellationModel.fromJson(Map<String, dynamic> json) {
    return ClassCancellationModel(
      id: json['id'] as int? ?? 0,
      studyPlanId: json['study_plan_id'] as int? ?? 0,
      cancelDate: json['cancel_date'] != null ? (DateTime.tryParse(json['cancel_date'].toString()) ?? DateTime.now()) : DateTime.now(),
      reason: json['reason'] as String?,
      createdBy: json['created_by'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'study_plan_id': studyPlanId,
      'cancel_date': cancelDate.toIso8601String(),
      'reason': reason,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
