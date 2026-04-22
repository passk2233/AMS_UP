class SubjectGroupModel {
  int id;
  String groupCode;
  String groupNameLao;
  String? groupNameEng;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  SubjectGroupModel({
    required this.id,
    required this.groupCode,
    required this.groupNameLao,
    this.groupNameEng,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory SubjectGroupModel.fromJson(Map<String, dynamic> json) {
    return SubjectGroupModel(
      id: json['id'] as int? ?? 0,
      groupCode: json['group_code'] as String? ?? '',
      groupNameLao: json['group_name_lao'] as String? ?? '',
      groupNameEng: json['group_name_eng'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_code': groupCode,
      'group_name_lao': groupNameLao,
      'group_name_eng': groupNameEng,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
