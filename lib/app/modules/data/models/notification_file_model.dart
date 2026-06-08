/// One uploaded attachment belonging to a notification (a row of the
/// `notification_files` table). [path] is server-relative; resolve it with
/// `resolveMediaUrl` before loading.
class NotificationFileModel {
  final int id;
  final int notiId;
  final String path;
  final String name;
  final String? mime;
  final int? size;

  const NotificationFileModel({
    required this.id,
    required this.notiId,
    required this.path,
    required this.name,
    this.mime,
    this.size,
  });

  factory NotificationFileModel.fromJson(Map<String, dynamic> json) {
    return NotificationFileModel(
      id: json['id'] as int? ?? 0,
      notiId: json['noti_id'] as int? ?? 0,
      path: json['path'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mime: json['mime'] as String?,
      size: (json['size'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'noti_id': notiId,
        'path': path,
        'name': name,
        'mime': mime,
        'size': size,
      };

  /// The shape the backend's create/update `files` field expects (an entry as
  /// returned by POST /notifications/upload).
  Map<String, dynamic> toUploadRef() => {
        'path': path,
        'name': name,
        if (mime != null) 'mime': mime,
        if (size != null) 'size': size,
      };
}
