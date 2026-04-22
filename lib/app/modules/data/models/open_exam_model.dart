import 'study_plan_model.dart';

class OpenExamModel {
  int id;
  String numQuestion;
  String timeDuration;
  DateTime? openTime;
  int? stPlanId;
  DateTime? closeTime;
  int? inactive;
  StudyPlanModel? studyPlan;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  OpenExamModel({
    required this.id,
    required this.numQuestion,
    required this.timeDuration,
    this.openTime,
    this.stPlanId,
    this.closeTime,
    this.inactive,
    this.studyPlan,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory OpenExamModel.fromJson(Map<String, dynamic> json) {
    return OpenExamModel(
      id: json['id'] as int? ?? 0,
      numQuestion: json['num_question'] as String? ?? '',
      timeDuration: json['time_duration'] as String? ?? '',
      openTime: json['open_time'] != null ? DateTime.tryParse(json['open_time'].toString()) : null,
      stPlanId: json['st_plan_id'] as int?,
      closeTime: json['close_time'] != null ? DateTime.tryParse(json['close_time'].toString()) : null,
      inactive: json['inactive'] as int?,
      studyPlan: json['study_plan'] != null ? StudyPlanModel.fromJson(json['study_plan']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'num_question': numQuestion,
      'time_duration': timeDuration,
      'open_time': openTime?.toIso8601String(),
      'st_plan_id': stPlanId,
      'close_time': closeTime?.toIso8601String(),
      'inactive': inactive,
      'study_plan': studyPlan?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
