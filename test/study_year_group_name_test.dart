// Guards studyYearGroupName: the legacy group name embeds the 4-digit intake
// year ("ປີ 2022"), but students must see their current study-year level
// ("ປີ 4"), computed against the Lao academic-year boundary (~September).
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/modules/student/profile_student/controllers/profile_student_controller.dart';

void main() {
  test('cohort year becomes study-year level (after Sept rollover)', () {
    // Academic year 2025/26 → a 2022 intake is in year 4.
    expect(
      studyYearGroupName('ນັກສຶກສາໄອທີ ປີ 2022 ຫ້ອງ 1', DateTime(2025, 10, 1)),
      'ນັກສຶກສາໄອທີ ປີ 4 ຫ້ອງ 1',
    );
  });

  test('before Sept rollover still counts as the prior academic year', () {
    // June 2026 is still academic year 2025/26 → year 4, not 5.
    expect(
      studyYearGroupName('ນັກສຶກສາໄອທີ ປີ 2022 ຫ້ອງ 1', DateTime(2026, 6, 29)),
      'ນັກສຶກສາໄອທີ ປີ 4 ຫ້ອງ 1',
    );
  });

  test('room number (ຫ້ອງ 1) is left untouched — only the 4-digit ປີ matches', () {
    final out =
        studyYearGroupName('ນັກສຶກສາໄອທີ ປີ 2024 ຫ້ອງ 1', DateTime(2026, 6, 1));
    expect(out, 'ນັກສຶກສາໄອທີ ປີ 2 ຫ້ອງ 1');
  });

  test('no 4-digit ປີ token → returned unchanged', () {
    expect(studyYearGroupName('ກຸ່ມພິເສດ ຫ້ອງ 1', DateTime(2026, 6, 1)),
        'ກຸ່ມພິເສດ ຫ້ອງ 1');
  });

  test('future/odd cohort (level < 1) → unchanged, no fabricated level', () {
    expect(
      studyYearGroupName('ນັກສຶກສາໄອທີ ປີ 2030 ຫ້ອງ 1', DateTime(2026, 6, 1)),
      'ນັກສຶກສາໄອທີ ປີ 2030 ຫ້ອງ 1',
    );
  });
}
