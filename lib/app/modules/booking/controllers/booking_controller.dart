import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/data_exporter.dart';
import '../../../widgets/app_dialogs.dart';

class BookingController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<RoomModel> rooms = <RoomModel>[].obs;
  final RxList<RoomBookingModel> myBookings = <RoomBookingModel>[].obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  late final Dio _dio;
  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _initDio();
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
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນຜູ້ໃຊ້';
        return;
      }

      final roomResp = await _dio.get('/rooms', queryParameters: {'limit': 200});
      final roomItems = _extractList(roomResp.data);
      rooms.assignAll(roomItems.map((j) => RoomModel.fromJson(j)).toList());

      final bResp =
          await _dio.get('/room-bookings', queryParameters: {'limit': 200});
      final bItems = _extractList(bResp.data);
      final all = bItems.map((j) => RoomBookingModel.fromJson(j)).toList();
      final mine = all.where((b) => b.userId == user.id).toList()
        ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      myBookings.assignAll(mine);
    } on DioException catch (e) {
      debugPrint('Booking Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');

      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        errorMessage.value = 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)';
        Get.offAllNamed('/auth');
        return;
      }
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດການຈອງໄດ້';
    } catch (e) {
      debugPrint('Booking error: $e');
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດການຈອງໄດ້';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() => fetchData();

  Future<void> createBooking({
    required int roomId,
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

      if (!_isValidTime(startTime) || !_isValidTime(endTime)) {
        AppDialogs.showWarning(
          title: 'ຮູບແບບເວລາບໍ່ຖືກ',
          message: 'ກະລຸນາໃສ່ເວລາແບບ HH:mm (ເຊັ່ນ 08:30)',
        );
        return;
      }
      if (!_isStartBeforeEnd(startTime, endTime)) {
        AppDialogs.showWarning(
          title: 'ເວລາບໍ່ຖືກ',
          message: 'ເວລາເລີ່ມຕ້ອງກ່ອນເວລາສິ້ນສຸດ',
        );
        return;
      }

      final resp = await _dio.post('/room-bookings', data: {
        'room_id': roomId,
        'user_id': user.id,
        // Backend expects RFC3339 with timezone (Z or +07:00)
        'booking_date': bookingDate.toUtc().toIso8601String(),
        'start_time': startTime,
        'end_time': endTime,
        'purpose': purpose,
      });

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        AppDialogs.showSuccess(
          title: 'ສົ່ງຄຳຂໍຈອງສຳເລັດ',
          message: 'ກະລຸນາລໍຖ້າການອະນຸມັດ',
        );
        await fetchData();
      } else {
        AppDialogs.showError(
          title: 'ສົ່ງຄຳຂໍບໍ່ສຳເລັດ',
          message: 'ກະລຸນາລອງໃໝ່',
        );
      }
    } on DioException catch (e) {
      final detail = AppDialogs.buildDioErrorDetail(e);
      AppDialogs.showError(
        title: 'ສົ່ງຄຳຂໍບໍ່ສຳເລັດ',
        message: 'ກະລຸນາກວດສອບຂໍ້ມູນແລະລອງໃໝ່',
        detail: detail,
      );
    } finally {
      isLoading.value = false;
    }
  }

  static bool _isValidTime(String v) {
    // HH:mm (00:00 - 23:59)
    final m = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').firstMatch(v.trim());
    return m != null;
  }

  static bool _isStartBeforeEnd(String start, String end) {
    int toMin(String t) {
      final parts = t.split(':');
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }

    return toMin(start.trim()) < toMin(end.trim());
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}
