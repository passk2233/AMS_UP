import 'role_model.dart';
import 'user_model.dart';

class UserRoleModel {
  int id;
  int roleId;
  int userId;
  RoleModel? role;
  UserModel? user;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  UserRoleModel({
    required this.id,
    required this.roleId,
    required this.userId,
    this.role,
    this.user,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(
      id: json['id'] as int? ?? 0,
      roleId: json['role_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      role: json['role'] != null ? RoleModel.fromJson(json['role']) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_id': roleId,
      'user_id': userId,
      'role': role?.toJson(),
      'user': user?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
