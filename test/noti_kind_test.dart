import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/modules/data/models/notification_model.dart';
import 'package:frontend/app/widgets/noti_cards.dart';

NotificationModel _noti({String? type, String title = ''}) =>
    NotificationModel(notiId: 1, title: title, message: '', type: type, isRead: 0);

void main() {
  test('notiKindOf classifies booking / eval / plain notifications', () {
    // Backend booking notis carry type "Room Booking".
    expect(notiKindOf(_noti(type: 'Room Booking')), 'booking');
    // Booking decision title without the type label.
    expect(notiKindOf(_noti(title: 'ການຈອງຫ້ອງໄດ້ຮັບການອະນຸມັດ')), 'booking');
    // Eval announcements mention ປະເມີນ in the title.
    expect(notiKindOf(_noti(title: 'ເປີດການປະເມີນອາຈານ ພາກຮຽນ 2/2025')), 'eval');
    // Plain announcement → no linked page.
    expect(notiKindOf(_noti(type: 'ທັງໝົດ', title: 'ປິດພັກຊົດເຊີຍ')), null);
    expect(notiKindOf(_noti()), null);
  });
}
