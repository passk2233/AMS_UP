import 'package:get/get.dart';

import '../booking/controllers/booking_controller.dart';
import '../schedules/controllers/schedules_controller.dart';
import '../teacher_evaluation/controllers/teacher_evaluation_controller.dart';
import '../teacher_home/controllers/teacher_home_controller.dart';
import '../teacher_profile/controllers/teacher_profile_controller.dart';

/// Index of each top-level tab in the teacher shell.
abstract class TeacherTab {
  /// "ໜ້າຫຼັກ" — dashboard.
  static const int home = 0;

  /// "ຕາຕະລາງ" — teaching schedule.
  static const int schedule = 1;

  /// "ຈອງຫ້ອງ" — room booking flow.
  static const int booking = 2;

  /// "ປະເມີນ" — view own evaluation results.
  static const int evaluation = 3;

  /// "ໂປຣໄຟລ໌" — profile + sign-out.
  static const int profile = 4;
}

/// Reactive selection state for the teacher shell's bottom navigation.
///
/// Owns the selected tab index and routes tab refreshes to the matching
/// page controller. Registered as `permanent` so it survives re-entry into
/// the shell.
class TeacherBottomNavController extends GetxController {
  /// Currently selected tab index. See [TeacherTab] for the integer keys.
  final RxInt selectedIndex = 0.obs;

  /// Map of tab index → side-effect (typically a controller `refreshData`).
  late final Map<int, void Function()> _tabRefreshers = {
    TeacherTab.home: () => _refreshIfRegistered<TeacherHomeController>(),
    TeacherTab.schedule: () => _refreshIfRegistered<SchedulesController>(),
    TeacherTab.booking: () => _refreshIfRegistered<BookingController>(),
    TeacherTab.evaluation:
        () => _refreshIfRegistered<TeacherEvaluationController>(),
    TeacherTab.profile: () => _refreshIfRegistered<TeacherProfileController>(),
  };

  /// Switch to [index]; no-op when already on that tab.
  void changeTab(int index) {
    if (index == selectedIndex.value) return;
    selectedIndex.value = index;
    _tabRefreshers[index]?.call();
  }

  /// Programmatically reset the shell to the dashboard.
  void resetToHome() {
    selectedIndex.value = TeacherTab.home;
    _tabRefreshers[TeacherTab.home]?.call();
  }

  void _refreshIfRegistered<T>() {
    if (!Get.isRegistered<T>()) return;
    (Get.find<T>() as dynamic).refreshData();
  }
}
