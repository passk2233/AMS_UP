import 'evaluation_question_model.dart';
import 'study_plan_model.dart';

/// Privacy-critical: this model intentionally OMITS `student_id` and the
/// nested `student` object. Per project hard rule, the client must never
/// surface the identity of the student who submitted an evaluation — and
/// since anything we parse here ends up in memory, network traces, and
/// crash reports, the safest move is to drop those fields entirely on the
/// way in. The backend is responsible for not returning them on
/// teacher-facing endpoints; this is the second line of defence.
class EvaluationResultModel {
  int evaResultsId;
  int studyPlanId;
  int evaQuestionId;
  int? score;
  String? comment;
  DateTime? createAt;
  StudyPlanModel? studyPlan;
  EvaluationQuestionModel? evaQuestion;

  EvaluationResultModel({
    required this.evaResultsId,
    required this.studyPlanId,
    required this.evaQuestionId,
    this.score,
    this.comment,
    this.createAt,
    this.studyPlan,
    this.evaQuestion,
  });

  factory EvaluationResultModel.fromJson(Map<String, dynamic> json) {
    return EvaluationResultModel(
      evaResultsId: json['eva_results_id'] as int? ?? 0,
      studyPlanId: json['study_plan_id'] as int? ?? 0,
      evaQuestionId: json['eva_question_id'] as int? ?? 0,
      score: json['score'] as int?,
      comment: json['comment'] as String?,
      createAt: json['create_at'] != null
          ? DateTime.tryParse(json['create_at'].toString())
          : null,
      studyPlan: json['study_plan'] != null
          ? StudyPlanModel.fromJson(json['study_plan'])
          : null,
      evaQuestion: json['eva_question'] != null
          ? EvaluationQuestionModel.fromJson(json['eva_question'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eva_results_id': evaResultsId,
      'study_plan_id': studyPlanId,
      'eva_question_id': evaQuestionId,
      'score': score,
      'comment': comment,
      'create_at': createAt?.toIso8601String(),
      'study_plan': studyPlan?.toJson(),
      'eva_question': evaQuestion?.toJson(),
    };
  }
}
