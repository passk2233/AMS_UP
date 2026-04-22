import 'notification_model.dart';
import 'user_model.dart';

class UserNotiModel {
  int id;
  int userId;
  int notiId;
  int isRead;
  DateTime? createAt;
  UserModel? user;
  NotificationModel? notification;

  UserNotiModel({
    required this.id,
    required this.userId,
    required this.notiId,
    required this.isRead,
    this.createAt,
    this.user,
    this.notification,
  });

  factory UserNotiModel.fromJson(Map<String, dynamic> json) {
    return UserNotiModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      notiId: json['noti_id'] as int? ?? 0,
      isRead: json['is_read'] as int? ?? 0,
      createAt: json['create_at'] != null ? DateTime.tryParse(json['create_at'].toString()) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      notification: json['notification'] != null ? NotificationModel.fromJson(json['notification']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'noti_id': notiId,
      'is_read': isRead,
      'create_at': createAt?.toIso8601String(),
      'user': user?.toJson(),
      'notification': notification?.toJson(),
    };
  }
}
