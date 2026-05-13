import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

class BookingStudentController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<RoomModel> rooms = <RoomModel>[].obs;
  final RxList<RoomBookingModel> allBookings = <RoomBookingModel>[].obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  var selectedDate = DateTime.now().obs;
  var currentWeek = <DateTime>[].obs;
  var selectedSlots = <String, String>{}.obs;
  var selectedBuilding = 'All Rooms'.obs;

  late final Dio _dio;
  String _token = '';

  static const _slotStarts = <String>[
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
  ];

  @override
  void onInit() {
    super.onInit();
    _initDio();
    generateWeek(DateTime.now());
    fetchData();
  }

  void _initDio() {
    final baseUrl = dotenv.env['API_URL'] ?? '';
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ));
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loadToken();

      final me = await _dio.get('/auth/me');
      if (me.statusCode == 200 && me.data is Map<String, dynamic>) {
        currentUser.value = UserModel.fromJson(me.data);
      }
      final user = currentUser.value;
      if (user == null) {
        errorMessage.value = 'User not found.';
        return;
      }

      final roomResp = await _dio.get('/rooms', queryParameters: {'limit': 200});
      final roomItems = _extractList(roomResp.data);
      rooms.assignAll(roomItems.map((j) => RoomModel.fromJson(j)).toList());

      final bResp = await _dio.get('/room-bookings', queryParameters: {'limit': 200});
      final bItems = _extractList(bResp.data);
      allBookings.assignAll(bItems.map((j) => RoomBookingModel.fromJson(j)).toList());
    } on DioException catch (e) {
      debugPrint('BookingStudent Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        errorMessage.value = 'Session expired. Please login again.';
        Get.offAllNamed('/auth');
        return;
      }
      errorMessage.value = 'Failed to load rooms/bookings.';
    } catch (e) {
      debugPrint('BookingStudent error: $e');
      errorMessage.value = 'Failed to load rooms/bookings.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() => fetchData();

  void generateWeek(DateTime startDay) {
    List<DateTime> days = [];
    for (int i = -3; i <= 3; i++) {
      days.add(startDay.add(Duration(days: i)));
    }
    currentWeek.value = days;
  }

  void selectDate(DateTime date) => selectedDate.value = date;

  void selectSlot(String roomName, String time) => selectedSlots[roomName] = time;

  void changeBuilding(String label) => selectedBuilding.value = label;

  List<Map<String, dynamic>> get filteredRooms {
    final selected = selectedDate.value;
    final selectedDay = DateTime(selected.year, selected.month, selected.day);

    bool sameDay(DateTime a) {
      final d = DateTime(a.year, a.month, a.day);
      return d == selectedDay;
    }

    bool isBooked(int roomId, String startTime) {
      return allBookings.any((b) {
        if (b.roomId != roomId) return false;
        if (!sameDay(b.bookingDate)) return false;
        final status = b.status.toLowerCase();
        if (status != 'pending' && status != 'approved') return false;
        return b.startTime.trim() == startTime.trim();
      });
    }

    return rooms.map((r) {
      final slots = _slotStarts.map((start) {
        final parts = start.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final endHour = hour + 1;
        final end = '${endHour.toString().padLeft(2, '0')}:${parts[1]}';
        return {
          'time': start,
          'status': isBooked(r.id, start) ? 'booked' : 'available',
          'start': start,
          'end': end,
        };
      }).toList();

      return {
        'name': r.roomCode,
        'capacity': r.capacity.toString(),
        'facilities': r.description ?? '-',
        'building': 'All Rooms',
        'room_id': r.id,
        'slots': slots,
      };
    }).toList();
  }

  Future<void> createBooking({
    required String roomCode,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
    String? purpose,
  }) async {
    try {
      isLoading.value = true;
      await _loadToken();
      final user = currentUser.value;
      if (user == null) return;

      final room = rooms.firstWhereOrNull((r) => r.roomCode == roomCode);
      if (room == null) {
        AppDialogs.showWarning(title: 'Room not found', message: 'Please try again.');
        return;
      }

      final resp = await _dio.post('/room-bookings', data: {
        'room_id': room.id,
        'user_id': user.id,
        'booking_date': bookingDate.toUtc().toIso8601String(),
        'start_time': startTime,
        'end_time': endTime,
        'purpose': purpose,
      });

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        AppDialogs.showSuccess(
          title: 'Booking request sent',
          message: 'Please wait for approval.',
        );
        await fetchData();
      }
    } on DioException catch (e) {
      final detail = AppDialogs.buildDioErrorDetail(e);
      AppDialogs.showError(
        title: 'Booking failed',
        message: 'Please check and try again.',
        detail: detail,
      );
    } finally {
      isLoading.value = false;
    }
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}