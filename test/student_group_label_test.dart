import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/modules/data/models/student_group_model.dart';

void main() {
  StudentGroupModel g(String name, int startYear) => StudentGroupModel(
        id: 1,
        stdGroupCode: 'X-1',
        stdGroupName: name,
        curriculumId: 1,
        startYear: startYear,
      );

  test('normal group: enrollment year becomes study year', () {
    expect(
      g('ນັກສຶກສາໄອທີ ປີ2024 ຫ້ອງ1', 2024).yearRoomLabel(2025),
      'ໄອທີ ປີ 2 ຫ້ອງ1',
    );
  });

  test('normal group caps at year 4', () {
    expect(
      g('ນັກສຶກສາຄອມພິວເຕີ ປີ 2018 ຫ້ອງ 2', 2018).yearRoomLabel(2025),
      'ຄອມພິວເຕີ ປີ 4 ຫ້ອງ 2',
    );
  });

  test('ຕໍ່ເນື່ອງ (continuing) group caps at year 2', () {
    expect(
      g('ນັກສຶກສາໄອທີຕໍ່ເນື່ອງ ປີ 2020 ຫ້ອງ 1', 2021).yearRoomLabel(2025),
      'ໄອທີຕໍ່ເນື່ອງ ປີ 2 ຫ້ອງ 1',
    );
  });

  test('missing start_year keeps the raw name', () {
    expect(
      g('ນັກສຶກສາໄອທີ ປີ 2024 ຫ້ອງ 1', 0).yearRoomLabel(2025),
      'ໄອທີ ປີ 2024 ຫ້ອງ 1',
    );
  });
}
