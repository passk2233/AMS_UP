import 'study_plan_model.dart';

/// Mirrors the `open_evalu` table — the admin-controlled window during
/// which students may submit faculty evaluations.
///
/// A row is "open" when [inactive] is `0` and the current time falls
/// between [openTime] and [closeTime] (inclusive). When [studyPlanId] is
/// `null` the window is treated as a global gate for every study plan.
class OpenEvaluationModel {
  int id;
  int? studyPlanId;
  DateTime? openTime;
  DateTime? closeTime;
  int inactive;
  StudyPlanModel? studyPlan;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  OpenEvaluationModel({
    required this.id,
    this.studyPlanId,
    this.openTime,
    this.closeTime,
    this.inactive = 0,
    this.studyPlan,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory OpenEvaluationModel.fromJson(Map<String, dynamic> json) {
    return OpenEvaluationModel(
      id: json['id'] as int? ?? 0,
      studyPlanId: json['study_plan_id'] as int?,
      openTime: json['open_time'] != null
          ? DateTime.tryParse(json['open_time'].toString())
          : null,
      closeTime: json['close_time'] != null
          ? DateTime.tryParse(json['close_time'].toString())
          : null,
      inactive: json['inactive'] as int? ?? 0,
      studyPlan: json['study_plan'] != null
          ? StudyPlanModel.fromJson(json['study_plan'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'study_plan_id': studyPlanId,
      'open_time': openTime?.toIso8601String(),
      'close_time': closeTime?.toIso8601String(),
      'inactive': inactive,
      'study_plan': studyPlan?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// `true` when [inactive] is 0 and the current moment lies within the
  /// `[openTime, closeTime]` window. A null bound means "no bound on
  /// that side".
  bool get isOpenNow {
    if (inactive != 0) return false;
    final now = DateTime.now();
    if (openTime != null && now.isBefore(openTime!)) return false;
    if (closeTime != null && now.isAfter(closeTime!)) return false;
    return true;
  }
}
