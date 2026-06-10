import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../data_exporter.dart';

/// Data-access layer for the `room_bookings` resource.
///
/// This is the seam the controllers depend on instead of touching
/// [ApiClient.dio] directly. It owns three things that have no business
/// living in a controller:
/// - the endpoint **paths** and query shape,
/// - the JSON **envelope** unwrapping (bare list vs `{ "data": [...] }`),
/// - the JSON → [RoomBookingModel] **mapping**.
///
/// Methods throw [DioException] on a transport / non-2xx failure — the
/// provider never shows UI. The calling controller decides how to surface
/// the error (snackbar, dialog, inline message).
///
/// Inject a custom [Dio] in tests to exercise the mapping without a network.
class BookingProvider {
  BookingProvider({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// Fetch up to [limit] most-recent room bookings, optionally constrained to
  /// a single [status]. Ordering / further filtering is the caller's concern;
  /// this just returns the parsed rows.
  Future<List<RoomBookingModel>> fetchBookings({
    int limit = 200,
    String? status,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (status != null) query['status'] = status;
    final response = await _dio.get('/room-bookings', queryParameters: query);
    return _extractList(response.data)
        .map((json) => RoomBookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Update a single booking's status (`approved` / `rejected` / `pending` /
  /// `cancelled`). Completes normally on success; throws on failure.
  Future<void> updateStatus(int bookingId, String status) async {
    await _dio.patch(
      '/room-bookings/$bookingId/status',
      data: {'status': status},
    );
  }

  /// POST `/room-bookings`. `user_id` is intentionally omitted — the backend
  /// derives the booker from the JWT subject. [bookingDate] is sent as the
  /// caller pre-formatted it. Returns the new `booking_id` when the server
  /// echoes it, else `null`. Throws on failure.
  Future<int?> createBooking({
    required int roomId,
    required String bookingDate,
    required String startTime,
    required String endTime,
    String? purpose,
  }) async {
    final resp = await _dio.post('/room-bookings', data: {
      'room_id': roomId,
      'booking_date': bookingDate,
      'start_time': startTime,
      'end_time': endTime,
      'purpose': purpose,
    });
    final data = resp.data;
    return (data is Map<String, dynamic>) ? data['booking_id'] as int? : null;
  }

  /// Fetch the room catalog.
  Future<List<RoomModel>> fetchRooms({int limit = 100}) async {
    final response = await _dio.get('/rooms', queryParameters: {'limit': limit});
    return _extractList(response.data)
        .map((json) => RoomModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Total number of rooms — prefers the server's `meta.total`, falling back
  /// to the returned page length.
  Future<int> countRooms({int limit = 100}) async {
    final response = await _dio.get('/rooms', queryParameters: {'limit': limit});
    final raw = response.data;
    if (raw is Map) {
      final metaTotal = raw['meta']?['total'] as int?;
      if (metaTotal != null && metaTotal > 0) return metaTotal;
      if (raw['data'] is List) return (raw['data'] as List).length;
    }
    if (raw is List) return raw.length;
    return 0;
  }

  /// Unwrap either a bare JSON array or a `{ "data": [...] }` envelope into a
  /// plain list; anything else yields an empty list.
  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}
