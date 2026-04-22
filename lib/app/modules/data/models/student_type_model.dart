class StudentTypeModel {
  int id;
  String stdTypeCode;
  String stdTypeNameLao;
  String stdTypeNameEng;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  StudentTypeModel({
    required this.id,
    required this.stdTypeCode,
    required this.stdTypeNameLao,
    required this.stdTypeNameEng,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory StudentTypeModel.fromJson(Map<String, dynamic> json) {
    return StudentTypeModel(
      id: json['id'] as int? ?? 0,
      stdTypeCode: json['std_type_code'] as String? ?? '',
      stdTypeNameLao: json['std_type_name_lao'] as String? ?? '',
      stdTypeNameEng: json['std_type_name_eng'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'std_type_code': stdTypeCode,
      'std_type_name_lao': stdTypeNameLao,
      'std_type_name_eng': stdTypeNameEng,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
