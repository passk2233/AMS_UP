import 'evaluation_question_model.dart';
import 'student_model.dart';
import 'study_plan_model.dart';

class EvaluationResultModel {
  int evaResultsId;
  int studyPlanId;
  int studentId;
  int evaQuestionId;
  int? score;
  String? comment;
  DateTime? createAt;
  StudyPlanModel? studyPlan;
  StudentModel? student;
  EvaluationQuestionModel? evaQuestion;

  EvaluationResultModel({
    required this.evaResultsId,
    required this.studyPlanId,
    required this.studentId,
    required this.evaQuestionId,
    this.score,
    this.comment,
    this.createAt,
    this.studyPlan,
    this.student,
    this.evaQuestion,
  });

  factory EvaluationResultModel.fromJson(Map<String, dynamic> json) {
    return EvaluationResultModel(
      evaResultsId: json['eva_results_id'] as int? ?? 0,
      studyPlanId: json['study_plan_id'] as int? ?? 0,
      studentId: json['student_id'] as int? ?? 0,
      evaQuestionId: json['eva_question_id'] as int? ?? 0,
      score: json['score'] as int?,
      comment: json['comment'] as String?,
      createAt: json['create_at'] != null ? DateTime.tryParse(json['create_at'].toString()) : null,
      studyPlan: json['study_plan'] != null ? StudyPlanModel.fromJson(json['study_plan']) : null,
      student: json['student'] != null ? StudentModel.fromJson(json['student']) : null,
      evaQuestion: json['eva_question'] != null ? EvaluationQuestionModel.fromJson(json['eva_question']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eva_results_id': evaResultsId,
      'study_plan_id': studyPlanId,
      'student_id': studentId,
      'eva_question_id': evaQuestionId,
      'score': score,
      'comment': comment,
      'create_at': createAt?.toIso8601String(),
      'study_plan': studyPlan?.toJson(),
      'student': student?.toJson(),
      'eva_question': evaQuestion?.toJson(),
    };
  }
}
