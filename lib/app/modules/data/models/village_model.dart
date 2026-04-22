import 'district_model.dart';

class VillageModel {
  int id;
  String villageCode;
  String villageNameLao;
  String? villageNameEng;
  int districtId;
  DistrictModel? district;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  VillageModel({
    required this.id,
    required this.villageCode,
    required this.villageNameLao,
    this.villageNameEng,
    required this.districtId,
    this.district,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory VillageModel.fromJson(Map<String, dynamic> json) {
    return VillageModel(
      id: json['id'] as int? ?? 0,
      villageCode: json['village_code'] as String? ?? '',
      villageNameLao: json['village_name_lao'] as String? ?? '',
      villageNameEng: json['village_name_eng'] as String?,
      districtId: json['district_id'] as int? ?? 0,
      district: json['district'] != null ? DistrictModel.fromJson(json['district']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'village_code': villageCode,
      'village_name_lao': villageNameLao,
      'village_name_eng': villageNameEng,
      'district_id': districtId,
      'district': district?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
