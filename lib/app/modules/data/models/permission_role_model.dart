import 'permission_model.dart';
import 'role_model.dart';

class PermissionRoleModel {
  int id;
  int permissionId;
  int roleId;
  PermissionModel? permission;
  RoleModel? role;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  PermissionRoleModel({
    required this.id,
    required this.permissionId,
    required this.roleId,
    this.permission,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory PermissionRoleModel.fromJson(Map<String, dynamic> json) {
    return PermissionRoleModel(
      id: json['id'] as int? ?? 0,
      permissionId: json['permission_id'] as int? ?? 0,
      roleId: json['role_id'] as int? ?? 0,
      permission: json['permission'] != null ? PermissionModel.fromJson(json['permission']) : null,
      role: json['role'] != null ? RoleModel.fromJson(json['role']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'permission_id': permissionId,
      'role_id': roleId,
      'permission': permission?.toJson(),
      'role': role?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
