import 'department_model.dart';

class DivisionModel {
  int id;
  String divisionCode;
  String divisionNameLao;
  String? divisionNameEng;
  int deptId;
  DepartmentModel? department;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  DivisionModel({
    required this.id,
    required this.divisionCode,
    required this.divisionNameLao,
    this.divisionNameEng,
    required this.deptId,
    this.department,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory DivisionModel.fromJson(Map<String, dynamic> json) {
    return DivisionModel(
      id: json['id'] as int? ?? 0,
      divisionCode: json['division_code'] as String? ?? '',
      divisionNameLao: json['division_name_lao'] as String? ?? '',
      divisionNameEng: json['division_name_eng'] as String?,
      deptId: json['dept_id'] as int? ?? 0,
      department: json['department'] != null ? DepartmentModel.fromJson(json['department']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'division_code': divisionCode,
      'division_name_lao': divisionNameLao,
      'division_name_eng': divisionNameEng,
      'dept_id': deptId,
      'department': department?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
