import 'package:get/get.dart';

import '../modules/admins/admin_navigator_bar/bindings/admin_shell_binding.dart';
import '../modules/admins/admin_navigator_bar/views/admin_shell_view.dart';
import '../modules/admins/announcement/bindings/announcement_binding.dart';
import '../modules/admins/announcement/views/announcement_view.dart';
import '../modules/admins/approve/bindings/approve_binding.dart';
import '../modules/admins/approve/views/approve_view.dart';
import '../modules/admins/evalutions/bindings/evalutions_binding.dart';
import '../modules/admins/evalutions/views/evalutions_view.dart';
import '../modules/profiles/bindings/profiles_binding.dart';
import '../modules/profiles/views/profiles_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/booking/bindings/booking_binding.dart';
import '../modules/booking/views/booking_view.dart';
import '../modules/teachers/feedbacks/bindings/feedbacks_binding.dart';
import '../modules/teachers/feedbacks/views/feedbacks_view.dart';
import '../modules/teachers/schedules/bindings/schedules_binding.dart';
import '../modules/teachers/schedules/views/schedules_view.dart';
import '../modules/students/student_home/bindings/student_home_binding.dart';
import '../modules/students/student_home/views/student_home_view.dart';
import '../modules/teachers/teacher_navigator_bar/bindings/teacher_shell_binding.dart';
import '../modules/teachers/teacher_navigator_bar/views/teacher_shell_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.AUTH;

  static final routes = [
    GetPage(
      name: _Paths.AUTH,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.ADMIN_HOME,
      page: () => const AdminShellView(),
      binding: AdminShellBinding(),
    ),
    GetPage(
      name: _Paths.STUDENT_HOME,
      page: () => const StudentHomeView(),
      binding: StudentHomeBinding(),
    ),
    GetPage(
      name: _Paths.TEACHER_HOME,
      page: () => const TeacherShellView(),
      binding: TeacherShellBinding(),
    ),
    GetPage(
      name: _Paths.ANNOUNCEMENT,
      page: () => const AnnouncementView(),
      binding: AnnouncementBinding(),
    ),
    GetPage(
      name: _Paths.APPROVE,
      page: () => const ApproveView(),
      binding: ApproveBinding(),
    ),
    GetPage(
      name: _Paths.EVALUTION,
      page: () => const EvalutionView(),
      binding: EvalutionBinding(),
    ),
    GetPage(
      name: _Paths.PROFILES,
      page: () => const ProfilesView(),
      binding: ProfilesBinding(),
      children: [
        GetPage(
          name: _Paths.PROFILES,
          page: () => const ProfilesView(),
          binding: ProfilesBinding(),
        ),
      ],
    ),
    GetPage(
      name: _Paths.SCHEDULES,
      page: () => const SchedulesView(),
      binding: SchedulesBinding(),
    ),
    GetPage(
      name: _Paths.BOOKING,
      page: () => const BookingView(),
      binding: BookingBinding(),
    ),
    GetPage(
      name: _Paths.FEEDBACKS,
      page: () => const FeedbacksView(),
      binding: FeedbacksBinding(),
    ),
  ];
}
