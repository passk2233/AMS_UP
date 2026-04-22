import 'student_model.dart';
import 'study_plan_model.dart';

class EnrollmentModel {
  int id;
  int studyPlanId;
  int stdId;
  String status;
  int? attencdScore;
  int? assignmentScore;
  int? midtermScore;
  int? finalScore;
  String? grade;
  String? remark;
  StudyPlanModel? studyPlan;
  StudentModel? student;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  EnrollmentModel({
    required this.id,
    required this.studyPlanId,
    required this.stdId,
    required this.status,
    this.attencdScore,
    this.assignmentScore,
    this.midtermScore,
    this.finalScore,
    this.grade,
    this.remark,
    this.studyPlan,
    this.student,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'] as int? ?? 0,
      studyPlanId: json['study_plan_id'] as int? ?? 0,
      stdId: json['std_id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      attencdScore: json['attencd_score'] as int?,
      assignmentScore: json['assignment_score'] as int?,
      midtermScore: json['midterm_score'] as int?,
      finalScore: json['final_score'] as int?,
      grade: json['grade'] as String?,
      remark: json['remark'] as String?,
      studyPlan: json['study_plan'] != null ? StudyPlanModel.fromJson(json['study_plan']) : null,
      student: json['student'] != null ? StudentModel.fromJson(json['student']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'study_plan_id': studyPlanId,
      'std_id': stdId,
      'status': status,
      'attencd_score': attencdScore,
      'assignment_score': assignmentScore,
      'midterm_score': midtermScore,
      'final_score': finalScore,
      'grade': grade,
      'remark': remark,
      'study_plan': studyPlan?.toJson(),
      'student': student?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
