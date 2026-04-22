import 'province_model.dart';

class DistrictModel {
  int id;
  String districtCode;
  String districtNameLao;
  String? districtNameEng;
  int provinceId;
  ProvinceModel? province;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  DistrictModel({
    required this.id,
    required this.districtCode,
    required this.districtNameLao,
    this.districtNameEng,
    required this.provinceId,
    this.province,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id'] as int? ?? 0,
      districtCode: json['district_code'] as String? ?? '',
      districtNameLao: json['district_name_lao'] as String? ?? '',
      districtNameEng: json['district_name_eng'] as String?,
      provinceId: json['province_id'] as int? ?? 0,
      province: json['province'] != null ? ProvinceModel.fromJson(json['province']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'district_code': districtCode,
      'district_name_lao': districtNameLao,
      'district_name_eng': districtNameEng,
      'province_id': provinceId,
      'province': province?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
