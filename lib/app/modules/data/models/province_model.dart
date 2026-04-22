class ProvinceModel {
  int id;
  String provinceCode;
  String provinceNameLao;
  String? provinceNameEng;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  ProvinceModel({
    required this.id,
    required this.provinceCode,
    required this.provinceNameLao,
    this.provinceNameEng,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      id: json['id'] as int? ?? 0,
      provinceCode: json['province_code'] as String? ?? '',
      provinceNameLao: json['province_name_lao'] as String? ?? '',
      provinceNameEng: json['province_name_eng'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'province_code': provinceCode,
      'province_name_lao': provinceNameLao,
      'province_name_eng': provinceNameEng,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
