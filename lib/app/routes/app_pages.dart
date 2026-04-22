import 'package:get/get.dart';

import '../modules/admins/home/bindings/home_binding.dart';
import '../modules/admins/home/views/home_view.dart';
import '../modules/admins/announcement/bindings/announcement_binding.dart';
import '../modules/admins/announcement/views/announcement_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/students/student_home/bindings/student_home_binding.dart';
import '../modules/students/student_home/views/student_home_view.dart';
import '../modules/teachers/teacher_home/bindings/teacher_home_binding.dart';
import '../modules/teachers/teacher_home/views/teacher_home_view.dart';

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
      page: () => const AdminHomeView(),
      binding: AdminHomeBinding(),
    ),
    GetPage(
      name: _Paths.STUDENT_HOME,
      page: () => const StudentHomeView(),
      binding: StudentHomeBinding(),
    ),
    GetPage(
      name: _Paths.TEACHER_HOME,
      page: () => const TeacherHomeView(),
      binding: TeacherHomeBinding(),
    ),
    GetPage(
      name: _Paths.ANNOUNCEMENT,
      page: () => const AnnouncementView(),
      binding: AnnouncementBinding(),
    ),
  ];
}
