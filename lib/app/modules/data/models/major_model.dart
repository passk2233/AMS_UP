class MajorModel {
  int id;
  String majorCode;
  String majorNameLao;
  String? majorNameEng;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  MajorModel({
    required this.id,
    required this.majorCode,
    required this.majorNameLao,
    this.majorNameEng,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory MajorModel.fromJson(Map<String, dynamic> json) {
    return MajorModel(
      id: json['id'] as int? ?? 0,
      majorCode: json['major_code'] as String? ?? '',
      majorNameLao: json['major_name_lao'] as String? ?? '',
      majorNameEng: json['major_name_eng'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'major_code': majorCode,
      'major_name_lao': majorNameLao,
      'major_name_eng': majorNameEng,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
