import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../data_exporter.dart';

/// Data-access layer for notifications.
///
/// Covers the two distinct notification surfaces the backend exposes:
/// - the per-user **inbox** (`/user-noti`) — what a signed-in user received,
///   plus the per-row read flag,
/// - the global **broadcast / history** resource (`/notifications`) — compose,
///   edit, delete, attachment upload (added as the admin/announcement flows
///   are migrated).
///
/// Owns the endpoint paths, JSON-envelope unwrapping, newest-first ordering,
/// and JSON → model mapping. Methods throw [DioException] on failure; the
/// calling controller owns the user-facing error handling.
class NotificationProvider {
  NotificationProvider({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// GET `/user-noti` — the signed-in user's personal inbox, returned
  /// newest-first. Each row carries its parent notification when the backend
  /// preloads it.
  Future<List<UserNotiModel>> fetchInbox({int limit = 100}) async {
    final response = await _dio.get(
      '/user-noti',
      queryParameters: {'limit': limit},
    );
    return _extractList(response.data)
        .map((j) => UserNotiModel.fromJson(j as Map<String, dynamic>))
        .toList()
      ..sort(_byNewestFirst);
  }

  /// PATCH `/user-noti/:id/read` — mark one inbox row read. [userNotiId] is
  /// the `user_noti` row id (not the notification id). Throws on failure.
  Future<void> markRead(int userNotiId) async {
    await _dio.patch('/user-noti/$userNotiId/read');
  }

  /// PATCH `/user-noti/read-all` — mark every unread inbox row of the
  /// signed-in user read in one request (server-side bulk badge clear).
  /// Idempotent; throws on failure.
  Future<void> markAllRead() async {
    await _dio.patch('/user-noti/read-all');
  }

  /// POST `/notifications` — create a broadcast for [audience] (e.g.
  /// `students` / `teachers`). The backend persists history and fans out the
  /// FCM push. Throws on failure.
  Future<void> broadcast({
    required String audience,
    required String title,
    required String message,
    String? type,
  }) async {
    await _dio.post(
      '/notifications',
      queryParameters: {'audience': audience},
      data: {
        'title': title,
        'message': message,
        'type': ?type,
      },
    );
  }

  /// POST `/notifications` with no audience fan-out — creates the notification
  /// record and returns its `noti_id` so the caller can attach it to specific
  /// inboxes via [createUserNoti]. Throws on failure.
  Future<int?> create({
    required String title,
    required String message,
    String? type,
    int isRead = 0,
  }) async {
    final resp = await _dio.post('/notifications', data: {
      'title': title,
      'message': message,
      'type': ?type,
      'is_read': isRead,
    });
    final data = resp.data;
    return (data is Map<String, dynamic>) ? data['noti_id'] as int? : null;
  }

  /// POST `/user-noti` — attach an existing notification to one user's inbox.
  /// Throws on failure.
  Future<void> createUserNoti({
    required int userId,
    required int notiId,
    int isRead = 0,
  }) async {
    await _dio.post('/user-noti', data: {
      'user_id': userId,
      'noti_id': notiId,
      'is_read': isRead,
    });
  }

  /// GET `/notifications` — broadcast history, paginated.
  Future<List<NotificationModel>> fetchHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _dio.get(
      '/notifications',
      queryParameters: {'limit': limit, 'page': page},
    );
    return _extractList(resp.data)
        .map((j) => NotificationModel.fromJson(j))
        .toList();
  }

  /// GET `/notifications/estimate-reach` — how many users [query] matches.
  /// Returns the parsed count, or `null` when the body shape is unrecognized.
  /// Throws [DioException] so the caller can fall back on 404/405.
  Future<int?> estimateReach(Map<String, dynamic> query) async {
    final resp = await _dio.get(
      '/notifications/estimate-reach',
      queryParameters: query,
    );
    final data = resp.data;
    if (data is int) return data;
    if (data is Map) {
      final raw = data['count'] ?? data['total'] ?? data['data'];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
    }
    return null;
  }

  /// POST `/notifications/upload` (multipart). Returns the uploaded file refs
  /// (`{path,name,mime?,size?}`), or `null` when the response was malformed.
  Future<List<Map<String, dynamic>>?> uploadAttachments(FormData form) async {
    final response = await _dio.post(
      '/notifications/upload',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = response.data;
    if (data is Map && data['files'] is List) {
      return (data['files'] as List)
          .whereType<Map>()
          .where((m) => m['path'] is String && (m['path'] as String).isNotEmpty)
          .map<Map<String, dynamic>>((m) {
        final ref = <String, dynamic>{'path': m['path'], 'name': m['name']};
        if (m['mime'] != null) ref['mime'] = m['mime'];
        if (m['size'] != null) ref['size'] = m['size'];
        return ref;
      }).toList();
    }
    return null;
  }

  /// POST `/notifications` — send a composed announcement. [query] carries the
  /// audience + filters; [data] the title/message/type/files. Throws on
  /// failure.
  Future<void> send({
    Map<String, dynamic>? query,
    required Map<String, dynamic> data,
  }) async {
    await _dio.post('/notifications', queryParameters: query, data: data);
  }

  /// DELETE `/notifications/:id`. Throws on failure.
  Future<void> delete(int notiId) async {
    await _dio.delete('/notifications/$notiId');
  }

  /// PUT `/notifications/:id`, falling back to DELETE + re-POST when the PUT
  /// route is missing (404/405). Throws on any other failure.
  Future<void> updateOrRecreate({
    required int notiId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _dio.put('/notifications/$notiId', data: data);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) {
        await _dio.delete('/notifications/$notiId');
        await _dio.post('/notifications', data: data);
      } else {
        rethrow;
      }
    }
  }

  /// Newest-first comparator. Prefers the inbox row's own timestamp, falls
  /// back to the parent notification's, then to row id (monotonic) so missing
  /// timestamps and ties still order deterministically.
  static int _byNewestFirst(UserNotiModel a, UserNotiModel b) {
    final epoch = DateTime(2000);
    final at = a.createAt ?? a.notification?.createdAt ?? epoch;
    final bt = b.createAt ?? b.notification?.createdAt ?? epoch;
    final cmp = bt.compareTo(at);
    return cmp != 0 ? cmp : b.id.compareTo(a.id);
  }

  /// Unwrap either a bare JSON array or a `{ "data": [...] }` envelope.
  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}
