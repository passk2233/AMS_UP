import 'open_exam_model.dart';
import 'stock_question_model.dart';
import 'user_model.dart';

class ExamAnswerModel {
  int id;
  int userId;
  int qId;
  int? openExId;
  String? answer;
  int? scored;
  UserModel? user;
  StockQuestionModel? question;
  OpenExamModel? openExam;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  ExamAnswerModel({
    required this.id,
    required this.userId,
    required this.qId,
    this.openExId,
    this.answer,
    this.scored,
    this.user,
    this.question,
    this.openExam,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory ExamAnswerModel.fromJson(Map<String, dynamic> json) {
    return ExamAnswerModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      qId: json['q_id'] as int? ?? 0,
      openExId: json['open_ex_id'] as int?,
      answer: json['answer'] as String?,
      scored: json['scored'] as int?,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      question: json['question'] != null ? StockQuestionModel.fromJson(json['question']) : null,
      openExam: json['open_exam'] != null ? OpenExamModel.fromJson(json['open_exam']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'q_id': qId,
      'open_ex_id': openExId,
      'answer': answer,
      'scored': scored,
      'user': user?.toJson(),
      'question': question?.toJson(),
      'open_exam': openExam?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
