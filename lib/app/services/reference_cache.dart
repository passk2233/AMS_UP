import 'package:get/get.dart';

import '../modules/data/data_exporter.dart';

/// In-memory, TTL-bounded cache for the rarely-changing reference data the
/// evaluation screens load repeatedly — study plans (per filter) and student
/// group roster sizes.
///
/// Registered permanent ([to]) so it outlives controller/route rebuilds: a
/// `lazyPut` controller recreated on navigation reuses the cached lists instead
/// of re-downloading. The data is also cached server-side; this just stops the
/// client re-asking within the window.
///
/// ponytail: process-local, single TTL, no eviction (a handful of keys). Call
/// [invalidate] after a mutation or semester switch if you need it fresher than
/// the TTL.
class ReferenceCache extends GetxService {
  ReferenceCache({AcademicProvider? academic, PeopleProvider? people})
      : _academic = academic ?? AcademicProvider(),
        _people = people ?? PeopleProvider();

  final AcademicProvider _academic;
  final PeopleProvider _people;

  /// How long a cached entry stays fresh. Study plans / rosters are stable
  /// within a semester, so minutes is plenty and still picks up edits soon.
  static const Duration ttl = Duration(minutes: 5);

  /// Lazily-registered permanent singleton. Controllers call
  /// `ReferenceCache.to.studyPlans(...)` without touching any binding.
  static ReferenceCache get to => Get.isRegistered<ReferenceCache>()
      ? Get.find<ReferenceCache>()
      : Get.put(ReferenceCache(), permanent: true);

  final Map<String, _Entry<List<StudyPlanModel>>> _plans = {};
  final Map<int, _Entry<int>> _groupSizes = {};

  /// Cached GET `/study-plans` for the given filters. Refetches only when the
  /// entry is missing or older than [ttl].
  Future<List<StudyPlanModel>> studyPlans({
    int? teacherId,
    int? semesterId,
    int? studentGroupId,
    int limit = 500,
  }) async {
    final key = 't=$teacherId;s=$semesterId;g=$studentGroupId;l=$limit';
    final hit = _plans[key];
    if (hit != null && hit.fresh) return hit.value;
    final value = await _academic.fetchStudyPlans(
      teacherId: teacherId,
      semesterId: semesterId,
      studentGroupId: studentGroupId,
      limit: limit,
    );
    _plans[key] = _Entry(value);
    return value;
  }

  /// Cached roster size for a student group (GET `/students?std_group_id=`).
  Future<int> groupSize(int groupId) async {
    final hit = _groupSizes[groupId];
    if (hit != null && hit.fresh) return hit.value;
    final roster =
        await _people.fetchStudents(studentGroupId: groupId, limit: 500);
    _groupSizes[groupId] = _Entry(roster.length);
    return roster.length;
  }

  /// Drop everything (e.g. after a semester switch or a data edit).
  void invalidate() {
    _plans.clear();
    _groupSizes.clear();
  }
}

class _Entry<T> {
  _Entry(this.value) : at = DateTime.now();
  final T value;
  final DateTime at;
  bool get fresh => DateTime.now().difference(at) < ReferenceCache.ttl;
}
