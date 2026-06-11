/// Whole-table booking aggregates from `GET /room-bookings/stats` — the
/// admin dashboard's stat cards. Server-side SQL counts, so the numbers stay
/// correct after the table outgrows one fetched page.
class BookingStatsModel {
  /// Booking counts keyed by lowercase status (`pending`, `approved`, ...).
  final Map<String, int> byStatus;
  final int total;

  /// Distinct rooms with an approved booking on the requested date.
  final int roomsInUse;
  final int totalRooms;

  BookingStatsModel({
    required this.byStatus,
    required this.total,
    required this.roomsInUse,
    required this.totalRooms,
  });

  int get pending => byStatus['pending'] ?? 0;
  int get approved => byStatus['approved'] ?? 0;

  /// Percentage of rooms in use, rounded; 0 when no rooms exist.
  int get roomInUsePercent =>
      totalRooms <= 0 ? 0 : ((roomsInUse / totalRooms) * 100).round();

  factory BookingStatsModel.fromJson(Map<String, dynamic> json) {
    final raw = json['by_status'];
    final byStatus = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        byStatus[k.toString().toLowerCase()] = (v as num?)?.toInt() ?? 0;
      });
    }
    return BookingStatsModel(
      byStatus: byStatus,
      total: (json['total'] as num?)?.toInt() ?? 0,
      roomsInUse: (json['rooms_in_use'] as num?)?.toInt() ?? 0,
      totalRooms: (json['total_rooms'] as num?)?.toInt() ?? 0,
    );
  }
}
