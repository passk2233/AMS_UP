import 'package:frontend/app/modules/data/data_exporter.dart';

/// One occurrence of a recurring [StudyPlanModel] slot on a concrete date.
///
/// Study plans are weekly; each plan expands into one [FixedBooking] per
/// matching weekday between the active semester's start and end dates —
/// purely client-side, via [expandPlanDates]. Nothing is written to
/// `room_booking`: the backend's conflict check already treats class slots
/// as occupied, and a single-date cancellation is a `class_cancellations`
/// row (carried here as [cancellationId] + [cancelReason]).
class FixedBooking {
  final StudyPlanModel plan;
  final DateTime date;
  final bool cancelled;

  /// `class_cancellations.id` backing [cancelled]; null for active
  /// occurrences. Needed to restore (DELETE) the cancellation.
  final int? cancellationId;
  final String? cancelReason;

  FixedBooking({
    required this.plan,
    required this.date,
    this.cancelled = false,
    this.cancellationId,
    this.cancelReason,
  });

  int get roomId => plan.roomId ?? 0;
  String get startTime => plan.startTime ?? '';
  String get endTime => plan.endTime ?? '';
  int get planId => plan.id;
  int get stdGroupId => plan.stdGroupId;
  int get teacherId => plan.teacherId;
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

/// `booking_date` wire format: RFC3339 at midnight UTC of the chosen calendar
/// day, e.g. `2026-05-18T00:00:00.000Z`.
///
/// Anchoring to UTC midnight of the picked day keeps the date stable across
/// timezones — calling `.toUtc()` on the picker's local-midnight DateTime
/// instead would shift it to the *previous* day for any timezone east of UTC.
String bookingDatePayload(DateTime d) {
  final dd = dateOnly(d);
  return DateTime.utc(dd.year, dd.month, dd.day).toIso8601String();
}

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
