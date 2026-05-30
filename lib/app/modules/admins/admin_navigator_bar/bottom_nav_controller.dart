import 'package:get/get.dart';

import '../../../widgets/admin_app_bar/admin_app_bar_controllers.dart';
import '../admin_profile/controllers/admin_profile_controller.dart';
import '../announcement/controllers/announcement_controller.dart';
import '../approve/controllers/approve_controller.dart';
import '../home/controllers/home_controller.dart';

/// Index of each top-level tab in the admin shell.
abstract class AdminTab {
  /// "ໜ້າຫຼັກ" — dashboard.
  static const int home = 0;

  /// "ການຢືນຢັນ" — booking approval queue.
  static const int approve = 1;

  /// "ການປະກາດ" — announcement composer + history.
  static const int announcement = 2;

  /// "ການປະເມີນ" — evaluation questions + results.
  static const int evaluation = 3;

  /// "ໂປຣໄຟລ໌" — admin profile + sign-out.
  static const int profile = 4;
}

/// Reactive selection state for the admin shell's bottom navigation.
///
/// Owns the currently selected tab index and routes tab refreshes to the
/// matching page controller. Registered as `permanent` so it survives
/// re-entry into the shell.
class BottomNavController extends GetxController {
  /// Currently selected tab index. See [AdminTab] for the integer keys.
  final RxInt selectedIndex = 0.obs;

  /// Map of tab index → side-effect that should run when the user enters
  /// that tab (typically a controller `refreshData`). The app-bar controller
  /// is refreshed unconditionally and is not part of this map.
  late final Map<int, void Function()> _tabRefreshers = {
    AdminTab.home: () => _refreshIfRegistered<AdminHomeController>(),
    AdminTab.approve: () => _refreshIfRegistered<ApproveController>(),
    AdminTab.announcement: () =>
        _refreshIfRegistered<AnnouncementController>(),
    AdminTab.profile: () => _refreshIfRegistered<AdminProfileController>(),
  };

  /// Switch to [index]; no-op when already on that tab.
  void changeTab(int index) {
    if (index == selectedIndex.value) return;
    selectedIndex.value = index;
    _refreshTab(index);
  }

  /// Programmatically reset the shell to the dashboard.
  void resetToHome() {
    selectedIndex.value = AdminTab.home;
    _refreshTab(AdminTab.home);
  }

  /// Programmatically jump to the approval queue.
  void gotoApprovePage() {
    selectedIndex.value = AdminTab.approve;
    _refreshTab(AdminTab.approve);
  }

  /// Programmatically jump to the announcement composer.
  void gotoNotificationPage() {
    selectedIndex.value = AdminTab.announcement;
    _refreshTab(AdminTab.announcement);
  }

  /// Programmatically jump to the evaluation tab.
  void gotoEvalutionPage() {
    selectedIndex.value = AdminTab.evaluation;
    _refreshTab(AdminTab.evaluation);
  }

  /// Programmatically jump to the profile tab.
  void gotoProfilesPage() {
    selectedIndex.value = AdminTab.profile;
    _refreshTab(AdminTab.profile);
  }

  void _refreshTab(int index) {
    _refreshIfRegistered<AdminAppBarControllers>();
    _tabRefreshers[index]?.call();
  }

  void _refreshIfRegistered<T>() {
    if (!Get.isRegistered<T>()) return;
    final ctrl = Get.find<T>();
    // Every refreshable controller in this shell exposes `refreshData()`.
    (ctrl as dynamic).refreshData();
  }
}
