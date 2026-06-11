// Unit tests for the pure schedule math in fixed_booking.dart — the helpers
// every booking flow leans on for overlap detection, weekly plan expansion,
// and the booking_date wire format. These guard against double-booking and
// the classic timezone-shift bug, so they get pinned here.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/modules/teachers/booking/controllers/fixed_booking.dart';

/// Minimal weekly plan slot: only the fields the helpers read.
StudyPlanModel _plan({String? day, String? start, String? end}) {
  return StudyPlanModel(
    id: 1,
    semasterId: 1,
    subjectId: 1,
    stdGroupId: 1,
    teacherId: 1,
    roomId: 1,
    dayOfWeek: day,
    startTime: start,
    endTime: end,
  );
}

void main() {
  group('timeToMinutes', () {
    test('parses single- and double-digit hours', () {
      expect(timeToMinutes('8:00'), 480);
      expect(timeToMinutes('08:30'), 510);
      expect(timeToMinutes('23:59'), 1439);
    });

    test('tolerates trailing seconds and whitespace', () {
      expect(timeToMinutes(' 09:15 '), 555);
      expect(timeToMinutes('09:15:00'), 555);
    });

    test('falls back to 0 on null/empty/garbage', () {
      expect(timeToMinutes(null), 0);
      expect(timeToMinutes(''), 0);
      expect(timeToMinutes('noon'), 0);
    });
  });

  group('timeRangesOverlap', () {
    test('detects a plain overlap', () {
      expect(timeRangesOverlap('09:00', '10:30', '10:00', '11:00'), isTrue);
      expect(timeRangesOverlap('10:00', '11:00', '09:00', '10:30'), isTrue);
    });

    test('containment counts as overlap', () {
      expect(timeRangesOverlap('13:00', '15:00', '13:30', '14:00'), isTrue);
    });

    test('touching slots are NOT overlap (half-open intervals)', () {
      expect(timeRangesOverlap('09:00', '10:00', '10:00', '11:00'), isFalse);
      expect(timeRangesOverlap('10:00', '11:00', '09:00', '10:00'), isFalse);
    });

    test('single-digit hours compare numerically, not lexically', () {
      // Lexically '8:00' > '10:00'; minute arithmetic must get this right.
      expect(timeRangesOverlap('8:00', '9:00', '10:00', '11:00'), isFalse);
      expect(timeRangesOverlap('8:00', '9:00', '8:30', '10:00'), isTrue);
    });

    test('degenerate ranges (end <= start) never overlap', () {
      expect(timeRangesOverlap('10:00', '10:00', '09:00', '11:00'), isFalse);
      expect(timeRangesOverlap('11:00', '10:00', '09:00', '12:00'), isFalse);
    });
  });

  group('dayOfWeekToWeekday', () {
    test('maps full names, abbreviations and digits', () {
      expect(dayOfWeekToWeekday('monday'), DateTime.monday);
      expect(dayOfWeekToWeekday('Mon'), DateTime.monday);
      expect(dayOfWeekToWeekday('1'), DateTime.monday);
      expect(dayOfWeekToWeekday('FRIDAY'), DateTime.friday);
    });

    test('sunday accepts both 0 and 7', () {
      expect(dayOfWeekToWeekday('sunday'), DateTime.sunday);
      expect(dayOfWeekToWeekday('0'), DateTime.sunday);
      expect(dayOfWeekToWeekday('7'), DateTime.sunday);
    });

    test('returns -1 for null/empty/unknown', () {
      expect(dayOfWeekToWeekday(null), -1);
      expect(dayOfWeekToWeekday(''), -1);
      expect(dayOfWeekToWeekday('someday'), -1);
    });
  });

  group('expandPlanDates', () {
    // 2026-06-01 is a Monday; 2026-06-30 is a Tuesday.
    final semStart = DateTime(2026, 6, 1);
    final semEnd = DateTime(2026, 6, 30);

    test('weekly Mondays across the window, inclusive of a start that hits',
        () {
      final dates = expandPlanDates(
          _plan(day: 'monday', start: '08:00', end: '10:00'),
          semStart,
          semEnd);
      expect(dates, [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 8),
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 22),
        DateTime(2026, 6, 29),
      ]);
    });

    test('first occurrence lands on the first matching weekday after start',
        () {
      final dates = expandPlanDates(
          _plan(day: 'wednesday', start: '08:00', end: '10:00'),
          semStart,
          semEnd);
      expect(dates.first, DateTime(2026, 6, 3));
      expect(dates.length, 4);
    });

    test('end date itself is included when it matches', () {
      final dates = expandPlanDates(
          _plan(day: 'tuesday', start: '08:00', end: '10:00'),
          semStart,
          semEnd);
      expect(dates.last, DateTime(2026, 6, 30));
    });

    test('empty for a plan without a weekday or an inverted window', () {
      expect(expandPlanDates(_plan(day: null), semStart, semEnd), isEmpty);
      expect(expandPlanDates(_plan(day: 'monday'), semEnd, semStart), isEmpty);
    });
  });

  group('bookingDatePayload', () {
    test('is UTC midnight of the picked calendar day', () {
      // A local-midnight DateTime (what showDatePicker returns) must keep
      // its calendar day — `.toUtc()` would shift it back a day east of UTC.
      expect(
        bookingDatePayload(DateTime(2026, 6, 12)),
        '2026-06-12T00:00:00.000Z',
      );
    });

    test('drops any time-of-day component', () {
      expect(
        bookingDatePayload(DateTime(2026, 6, 12, 23, 45)),
        '2026-06-12T00:00:00.000Z',
      );
    });
  });

  group('sameDate / dateOnly', () {
    test('sameDate compares calendar components only', () {
      expect(
        sameDate(DateTime(2026, 6, 12, 8), DateTime(2026, 6, 12, 22)),
        isTrue,
      );
      expect(sameDate(DateTime(2026, 6, 12), DateTime(2026, 6, 13)), isFalse);
    });

    test('dateOnly strips the time of day', () {
      expect(dateOnly(DateTime(2026, 6, 12, 17, 30)), DateTime(2026, 6, 12));
    });
  });

  group('isPastSlot / isPastDate', () {
    // Same-minute "now" edges are untestable without clock injection, so
    // these stick to whole-day offsets, which are deterministic.
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    test('yesterday is past, tomorrow is not', () {
      expect(isPastSlot(yesterday, '08:00'), isTrue);
      expect(isPastSlot(tomorrow, '08:00'), isFalse);
      expect(isPastDate(yesterday), isTrue);
      expect(isPastDate(tomorrow), isFalse);
    });

    test('today at 00:00 already started', () {
      expect(isPastSlot(DateTime.now(), '00:00'), isTrue);
    });
  });
}
