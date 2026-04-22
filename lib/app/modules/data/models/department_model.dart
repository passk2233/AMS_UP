class DepartmentModel {
  int id;
  String departmentCode;
  String deptNameLao;
  String? deptNameEng;
  String? telephone;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  DepartmentModel({
    required this.id,
    required this.departmentCode,
    required this.deptNameLao,
    this.deptNameEng,
    this.telephone,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as int? ?? 0,
      departmentCode: json['department_code'] as String? ?? '',
      deptNameLao: json['dept_name_lao'] as String? ?? '',
      deptNameEng: json['dept_name_eng'] as String?,
      telephone: json['telephone'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department_code': departmentCode,
      'dept_name_lao': deptNameLao,
      'dept_name_eng': deptNameEng,
      'telephone': telephone,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
