import 'user_model.dart';

class UserDeviceModel {
  int id;
  int userId;
  String deviceToken;
  String? platform;
  int isActive;
  DateTime? createdAt;
  DateTime? updatedAt;
  UserModel? user;

  UserDeviceModel({
    required this.id,
    required this.userId,
    required this.deviceToken,
    this.platform,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory UserDeviceModel.fromJson(Map<String, dynamic> json) {
    return UserDeviceModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      deviceToken: json['device_token'] as String? ?? '',
      platform: json['platform'] as String?,
      isActive: json['is_active'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_token': deviceToken,
      'platform': platform,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}
