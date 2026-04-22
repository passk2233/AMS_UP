import 'subject_model.dart';
import 'user_model.dart';

class StockQuestionModel {
  int id;
  String qStatement;
  int level;
  int actived;
  int? subId;
  String? anwserType;
  int? onwer;
  SubjectModel? subject;
  UserModel? owner;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  StockQuestionModel({
    required this.id,
    required this.qStatement,
    required this.level,
    required this.actived,
    this.subId,
    this.anwserType,
    this.onwer,
    this.subject,
    this.owner,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory StockQuestionModel.fromJson(Map<String, dynamic> json) {
    return StockQuestionModel(
      id: json['id'] as int? ?? 0,
      qStatement: json['q_statement'] as String? ?? '',
      level: json['level'] as int? ?? 0,
      actived: json['actived'] as int? ?? 0,
      subId: json['sub_id'] as int?,
      anwserType: json['anwser_type'] as String?,
      onwer: json['onwer'] as int?,
      subject: json['subject'] != null ? SubjectModel.fromJson(json['subject']) : null,
      owner: json['owner'] != null ? UserModel.fromJson(json['owner']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'q_statement': qStatement,
      'level': level,
      'actived': actived,
      'sub_id': subId,
      'anwser_type': anwserType,
      'onwer': onwer,
      'subject': subject?.toJson(),
      'owner': owner?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
