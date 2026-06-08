import 'notification_file_model.dart';

class NotificationModel {
  int notiId;
  String title;
  String message;
  String? type;

  /// Uploaded attachments — one entry per row in `notification_files`.
  /// Resolve each [NotificationFileModel.path] with `resolveMediaUrl`.
  List<NotificationFileModel> files;

  int isRead;
  DateTime? createdAt;
  DateTime? updatedAt;

  NotificationModel({
    required this.notiId,
    required this.title,
    required this.message,
    this.type,
    this.files = const [],
    required this.isRead,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notiId: json['noti_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String?,
      files: (json['files'] as List?)
              ?.map((e) =>
                  NotificationFileModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isRead: json['is_read'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noti_id': notiId,
      'title': title,
      'message': message,
      'type': type,
      'files': files.map((f) => f.toJson()).toList(),
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
