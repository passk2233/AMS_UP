// Guards the booking purpose sanitizer: backend internal markers like
// `__sp_fixed:1` must never reach the UI raw (see room_booking_model.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/modules/data/data_exporter.dart';

RoomBookingModel _b(String? purpose) => RoomBookingModel(
      bookingId: 1,
      roomId: 1,
      userId: 1,
      bookingDate: DateTime(2026, 7, 13),
      startTime: '08:00',
      endTime: '11:40',
      purpose: purpose,
      status: 'approved',
    );

void main() {
  test('fixed-class marker maps to a friendly label', () {
    expect(_b('__sp_fixed:1').displayPurpose, 'ຄາບຮຽນປະຈຳ');
  });

  test('unknown internal marker is hidden', () {
    expect(_b('__whatever:9').displayPurpose, isNull);
  });

  test('real purpose passes through, blanks become null', () {
    expect(_b('ກອງປະຊຸມ').displayPurpose, 'ກອງປະຊຸມ');
    expect(_b('   ').displayPurpose, isNull);
    expect(_b(null).displayPurpose, isNull);
  });
}
