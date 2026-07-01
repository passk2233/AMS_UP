import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/services/reference_cache.dart';

/// Fake providers that count network calls and never touch the real Dio
/// (a fresh Dio is handed to super so ApiClient is never read).
class _FakeAcademic extends AcademicProvider {
  _FakeAcademic() : super(dio: Dio());
  int calls = 0;

  @override
  Future<List<StudyPlanModel>> fetchStudyPlans({
    int? teacherId,
    int? semesterId,
    int? studentGroupId,
    int limit = 500,
  }) async {
    calls++;
    return const [];
  }
}

class _FakePeople extends PeopleProvider {
  _FakePeople() : super(dio: Dio());
  int calls = 0;

  @override
  Future<List<StudentModel>> fetchStudents({
    int? studentGroupId,
    Map<String, dynamic>? filters,
    int limit = 500,
  }) async {
    calls++;
    return const [];
  }
}

void main() {
  test('cached reads hit the provider once; invalidate forces a refetch', () async {
    final academic = _FakeAcademic();
    final people = _FakePeople();
    final cache = ReferenceCache(academic: academic, people: people);

    // Same filter twice → one network call (second served from cache).
    await cache.studyPlans(teacherId: 7);
    await cache.studyPlans(teacherId: 7);
    expect(academic.calls, 1);

    // A different filter is a distinct key → another call.
    await cache.studyPlans(teacherId: 8);
    expect(academic.calls, 2);

    // Group sizes cache the same way.
    await cache.groupSize(19);
    await cache.groupSize(19);
    expect(people.calls, 1);

    // invalidate() clears everything → next read refetches.
    cache.invalidate();
    await cache.studyPlans(teacherId: 7);
    expect(academic.calls, 3);
  });
}
