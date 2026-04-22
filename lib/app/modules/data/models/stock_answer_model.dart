import 'stock_question_model.dart';

class StockAnswerModel {
  int id;
  String opStatement;
  int correctAns;
  int? qId;
  StockQuestionModel? question;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  StockAnswerModel({
    required this.id,
    required this.opStatement,
    required this.correctAns,
    this.qId,
    this.question,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory StockAnswerModel.fromJson(Map<String, dynamic> json) {
    return StockAnswerModel(
      id: json['id'] as int? ?? 0,
      opStatement: json['op_statement'] as String? ?? '',
      correctAns: json['correct_ans'] as int? ?? 0,
      qId: json['q_id'] as int?,
      question: json['question'] != null ? StockQuestionModel.fromJson(json['question']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'op_statement': opStatement,
      'correct_ans': correctAns,
      'q_id': qId,
      'question': question?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
