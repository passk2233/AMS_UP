import 'package:frontend/app/modules/data/data_exporter.dart';

/// A booking occurrence generated from a [StudyPlanModel].
///
/// Study plans are weekly. Each plan expands into one [FixedBooking] per
/// matching weekday between the active semester's start and end dates. Each
/// occurrence is persisted as a `room_booking` row with status `approved`;
/// when the teacher cancels, the same row flips to status `cancelled` and the
/// cancellation reason is stored in `purpose`.
class FixedBooking {
  final StudyPlanModel plan;
  final DateTime date;
  final bool cancelled;
  final int? bookingId;
  final String? cancelReason;

  FixedBooking({
    required this.plan,
    required this.date,
    this.cancelled = false,
    this.bookingId,
    this.cancelReason,
  });

  int get roomId => plan.roomId ?? 0;
  String get startTime => plan.startTime ?? '';
  String get endTime => plan.endTime ?? '';
  int get planId => plan.id;
  int get stdGroupId => plan.stdGroupId;
  int get teacherId => plan.teacherId;
}

/// Sentinel stored in `room_booking.purpose` for a persisted, non-cancelled
/// study-plan occurrence. Format: `__sp_fixed:<plan_id>`.
String fixedActivePurpose(int planId) => '__sp_fixed:$planId';

/// Returns the plan id encoded in an active fixed-booking marker, or null.
int? parseFixedActivePurpose(String? purpose) {
  if (purpose == null) return null;
  final m = RegExp(r'^__sp_fixed:(\d+)$').firstMatch(purpose.trim());
  if (m == null) return null;
  return int.tryParse(m.group(1) ?? '');
}

/// Sentinel stored in `room_booking.purpose` once the teacher cancels an
/// occurrence. Format: `__sp_cancel:<plan_id>|<reason>` (reason optional).
String fixedCancelPurpose(int planId, [String? reason]) {
  final r = (reason ?? '').trim();
  return r.isEmpty ? '__sp_cancel:$planId' : '__sp_cancel:$planId|$r';
}

/// Returns the plan id encoded in a fixed-cancel purpose marker, or null.
int? parseFixedCancelPurpose(String? purpose) {
  if (purpose == null) return null;
  final m =
      RegExp(r'^__sp_cancel:(\d+)(?:\|.*)?$').firstMatch(purpose.trim());
  if (m == null) return null;
  return int.tryParse(m.group(1) ?? '');
}

/// Returns the teacher-supplied reason text from a fixed-cancel purpose, or
/// null when no reason was stored.
String? parseFixedCancelReason(String? purpose) {
  if (purpose == null) return null;
  final m =
      RegExp(r'^__sp_cancel:\d+\|(.*)$').firstMatch(purpose.trim());
  if (m == null) return null;
  final r = (m.group(1) ?? '').trim();
  return r.isEmpty ? null : r;
}

int dayOfWeekToWeekday(String? raw) {
  if (raw == null || raw.trim().isEmpty) return -1;
  switch (raw.trim().toLowerCase()) {
    case 'monday':
    case 'mon':
    case '1':
      return DateTime.monday;
    case 'tuesday':
    case 'tue':
    case '2':
      return DateTime.tuesday;
    case 'wednesday':
    case 'wed':
    case '3':
      return DateTime.wednesday;
    case 'thursday':
    case 'thu':
    case '4':
      return DateTime.thursday;
    case 'friday':
    case 'fri':
    case '5':
      return DateTime.friday;
    case 'saturday':
    case 'sat':
    case '6':
      return DateTime.saturday;
    case 'sunday':
    case 'sun':
    case '0':
    case '7':
      return DateTime.sunday;
    default:
      return -1;
  }
}

int timeToMinutes(String? value) {
  if (value == null || value.trim().isEmpty) return 0;
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value.trim());
  if (m == null) return 0;
  return (int.tryParse(m.group(1) ?? '') ?? 0) * 60 +
      (int.tryParse(m.group(2) ?? '') ?? 0);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Generate weekly occurrences of [plan] between [start] and [end] (inclusive).
List<DateTime> expandPlanDates(
  StudyPlanModel plan,
  DateTime start,
  DateTime end,
) {
  final wd = dayOfWeekToWeekday(plan.dayOfWeek);
  if (wd < 0) return const [];
  final from = dateOnly(start);
  final to = dateOnly(end);
  if (from.isAfter(to)) return const [];

  int diff = (wd - from.weekday) % 7;
  if (diff < 0) diff += 7;
  DateTime cur = from.add(Duration(days: diff));
  final out = <DateTime>[];
  while (!cur.isAfter(to)) {
    out.add(cur);
    cur = cur.add(const Duration(days: 7));
  }
  return out;
}

/// True when [start1,end1] and [start2,end2] overlap. End-exclusive.
bool timeRangesOverlap(String start1, String end1, String start2, String end2) {
  final s1 = timeToMinutes(start1);
  final e1 = timeToMinutes(end1);
  final s2 = timeToMinutes(start2);
  final e2 = timeToMinutes(end2);
  if (e1 <= s1 || e2 <= s2) return false;
  return s1 < e2 && s2 < e1;
}

/// True when [date] + [startTime] is already in the past relative to now.
/// A same-day slot whose start time equals the current minute also counts as
/// past — booking the exact current minute is rejected.
bool isPastSlot(DateTime date, String startTime) {
  final today = dateOnly(DateTime.now());
  final d = dateOnly(date);
  if (d.isBefore(today)) return true;
  if (!sameDate(d, today)) return false;
  final now = DateTime.now();
  final nowMin = now.hour * 60 + now.minute;
  return timeToMinutes(startTime) <= nowMin;
}

/// True when [date] is already in the past (date-only comparison).
bool isPastDate(DateTime date) =>
    dateOnly(date).isBefore(dateOnly(DateTime.now()));
