import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import 'package:frontend/app/modules/admins/admin_widgets/announcement/target_audience_card.dart';
import 'package:frontend/app/modules/admins/announcement/controllers/announcement_controller.dart';
import 'package:frontend/app/modules/data/models/notification_model.dart';
import 'package:frontend/app/modules/data/models/student_group_model.dart';
import 'package:frontend/app/modules/data/providers/notification_provider.dart';
import 'package:frontend/app/modules/data/providers/people_provider.dart';
import 'package:frontend/app/modules/data/providers/reference_provider.dart';

StudentGroupModel _group(int id, String name) => StudentGroupModel(
      id: id,
      stdGroupCode: 'G-$id',
      stdGroupName: name,
      curriculumId: 1,
      startYear: 2024,
    );

class _FakeReference extends ReferenceProvider {
  _FakeReference() : super(dio: Dio());

  @override
  Future<List<StudentGroupModel>> fetchStudentGroups({int limit = 100}) async =>
      [_group(1, 'IT-1'), _group(2, 'IT-2')];
}

class _FakeNoti extends NotificationProvider {
  _FakeNoti() : super(dio: Dio());

  @override
  Future<List<NotificationModel>> fetchHistory({
    int page = 1,
    int limit = 20,
  }) async =>
      [];

  @override
  Future<int?> estimateReach(Map<String, dynamic> query) async => 42;
}

class _FakePeople extends PeopleProvider {
  _FakePeople() : super(dio: Dio());
}

void main() {
  testWidgets('group chip highlights immediately on tap (no page revisit)',
      (tester) async {
    Get.testMode = true;
    final controller = Get.put(AnnouncementController(
      notification: _FakeNoti(),
      people: _FakePeople(),
      reference: _FakeReference(),
    ));
    controller.selectedAudience.value = AnnouncementAudience.students;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TargetAudienceCard(controller: controller),
        ),
      ),
    ));
    await tester.pump(); // flush fetchStudentGroups future

    // "ທັງໝົດ" also appears in the audience row, so scope text lookups to the
    // group FilterChips.
    Finder chipText(String label) => find.descendant(
          of: find.byType(FilterChip),
          matching: find.text(label),
        );
    FilterChip chipFor(String label) => tester.widget<FilterChip>(
          find.ancestor(of: chipText(label), matching: find.byType(FilterChip)),
        );

    expect(chipFor('IT-1').selected, isFalse);
    expect(chipFor('ທັງໝົດ').selected, isTrue);

    await tester.tap(chipText('IT-1'));
    await tester.pump(); // one frame — must already be highlighted

    expect(chipFor('IT-1').selected, isTrue);
    expect(chipFor('ທັງໝົດ').selected, isFalse);
    expect(controller.selectedStudentGroups.map((g) => g.id), [1]);

    // Second group joins the selection (multi-select).
    await tester.tap(chipText('IT-2'));
    await tester.pump();
    expect(chipFor('IT-2').selected, isTrue);
    expect(controller.selectedStudentGroups.map((g) => g.id), [1, 2]);

    // "All" clears the selection immediately.
    await tester.tap(chipText('ທັງໝົດ'));
    await tester.pump();
    expect(chipFor('IT-1').selected, isFalse);
    expect(controller.selectedStudentGroups, isEmpty);

    // Let the debounced reach-estimate timer fire so no timers leak.
    await tester.pump(const Duration(milliseconds: 500));
    Get.delete<AnnouncementController>();
  });
}
