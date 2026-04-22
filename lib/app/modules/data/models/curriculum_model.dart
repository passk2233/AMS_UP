import 'major_model.dart';

class CurriculumModel {
  int id;
  String curriCode;
  String curriNameLao;
  String? curriNameEng;
  String? curriNameLaoAbb;
  int majorId;
  MajorModel? major;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  CurriculumModel({
    required this.id,
    required this.curriCode,
    required this.curriNameLao,
    this.curriNameEng,
    this.curriNameLaoAbb,
    required this.majorId,
    this.major,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory CurriculumModel.fromJson(Map<String, dynamic> json) {
    return CurriculumModel(
      id: json['id'] as int? ?? 0,
      curriCode: json['curri_code'] as String? ?? '',
      curriNameLao: json['curri_name_lao'] as String? ?? '',
      curriNameEng: json['curri_name_eng'] as String?,
      curriNameLaoAbb: json['curri_name_lao_abb'] as String?,
      majorId: json['major_id'] as int? ?? 0,
      major: json['major'] != null ? MajorModel.fromJson(json['major']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'curri_code': curriCode,
      'curri_name_lao': curriNameLao,
      'curri_name_eng': curriNameEng,
      'curri_name_lao_abb': curriNameLaoAbb,
      'major_id': majorId,
      'major': major?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
