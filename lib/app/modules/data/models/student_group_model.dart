import 'curriculum_model.dart';

class StudentGroupModel {
  int id;
  String stdGroupCode;
  String stdGroupName;
  int curriculumId;
  CurriculumModel? curriculum;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  StudentGroupModel({
    required this.id,
    required this.stdGroupCode,
    required this.stdGroupName,
    required this.curriculumId,
    this.curriculum,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory StudentGroupModel.fromJson(Map<String, dynamic> json) {
    return StudentGroupModel(
      id: json['id'] as int? ?? 0,
      stdGroupCode: json['std_group_code'] as String? ?? '',
      stdGroupName: json['std_group_name'] as String? ?? '',
      curriculumId: json['curriculum_id'] as int? ?? 0,
      curriculum: json['curriculum'] != null ? CurriculumModel.fromJson(json['curriculum']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'std_group_code': stdGroupCode,
      'std_group_name': stdGroupName,
      'curriculum_id': curriculumId,
      'curriculum': curriculum?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
