import 'room_model.dart';
import 'user_model.dart';

class RoomBookingModel {
  int bookingId;
  int roomId;
  int userId;
  DateTime bookingDate;
  String startTime;
  String endTime;
  String? purpose;
  String status;
  DateTime? createAt;
  RoomModel? room;
  UserModel? user;

  /// Human-readable purpose for the UI. Backend tags fixed study-plan
  /// occurrences with internal markers like `__sp_fixed:1` in `purpose`;
  /// map the known one to a friendly label and hide any other `__`-prefixed
  /// marker so raw internals never reach the user.
  /// ponytail: prefix match; extend the switch when new markers appear.
  String? get displayPurpose {
    final p = purpose?.trim();
    if (p == null || p.isEmpty) return null;
    if (p.startsWith('__sp_fixed')) return 'ຄາບຮຽນປະຈຳ';
    if (p.startsWith('__')) return null;
    return p;
  }

  RoomBookingModel({
    required this.bookingId,
    required this.roomId,
    required this.userId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    this.purpose,
    required this.status,
    this.createAt,
    this.room,
    this.user,
  });

  factory RoomBookingModel.fromJson(Map<String, dynamic> json) {
    return RoomBookingModel(
      bookingId: json['booking_id'] as int? ?? 0,
      roomId: json['room_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      bookingDate: json['booking_date'] != null ? (DateTime.tryParse(json['booking_date'].toString()) ?? DateTime.now()) : DateTime.now(),
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      purpose: json['purpose'] as String?,
      status: json['status'] as String? ?? '',
      createAt: json['create_at'] != null ? DateTime.tryParse(json['create_at'].toString()) : null,
      room: json['room'] != null ? RoomModel.fromJson(json['room']) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'room_id': roomId,
      'user_id': userId,
      'booking_date': bookingDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'purpose': purpose,
      'status': status,
      'create_at': createAt?.toIso8601String(),
      'room': room?.toJson(),
      'user': user?.toJson(),
    };
  }
}
