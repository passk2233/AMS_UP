class EvaluationQuestionModel {
  int evaQuestionId;
  String question;
  String? category;
  int isActive;
  DateTime? createAt;

  EvaluationQuestionModel({
    required this.evaQuestionId,
    required this.question,
    this.category,
    required this.isActive,
    this.createAt,
  });

  factory EvaluationQuestionModel.fromJson(Map<String, dynamic> json) {
    return EvaluationQuestionModel(
      evaQuestionId: json['eva_question_id'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      category: json['category'] as String?,
      isActive: json['is_active'] as int? ?? 0,
      createAt: json['create_at'] != null ? DateTime.tryParse(json['create_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eva_question_id': evaQuestionId,
      'question': question,
      'category': category,
      'is_active': isActive,
      'create_at': createAt?.toIso8601String(),
    };
  }
}
