import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/student/Booking_student/bindings/booking_student_binding.dart';
import '../modules/student/Booking_student/views/booking_student_view.dart';
import '../modules/student/faculty_feedback/bindings/faculty_feedback_binding.dart';
import '../modules/student/faculty_feedback/views/evaluation_form_view.dart';
import '../modules/student/faculty_feedback/views/faculty_feedback_view.dart';
import '../modules/student/profile_student/bindings/profile_student_binding.dart';
import '../modules/student/profile_student/views/profile_student_view.dart';
import '../modules/student/schedule_student/bindings/schedule_student_binding.dart';
import '../modules/student/schedule_student/views/schedule_student_view.dart';
import '../modules/student/score/bindings/score_binding.dart';
import '../modules/student/score/views/score_view.dart';
import '../modules/student/student_home/bindings/home_student_binding.dart';
import '../modules/student/student_home/views/student_home_view.dart';
import '../modules/student/student_noti/bindings/student_noti_binding.dart';
import '../modules/student/student_noti/views/student_noti_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME_STUDENT;

  static final routes = [
    GetPage(
      name: _Paths.AUTH,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.HOME_STUDENT,
      page: () => const HomeStudentView(),
      binding: HomeStudentBinding(),
    ),
    GetPage(
      name: _Paths.SCORE,
      page: () => const ScoreView(),
      binding: ScoreBinding(),
    ),
    GetPage(
      name: _Paths.SCHEDULE_STUDENT,
      page: () => const ScheduleStudentView(),
      binding: ScheduleStudentBinding(),
    ),
    GetPage(
      name: _Paths.BOOKING_STUDENT,
      page: () => const BookingStudentView(),
      binding: BookingStudentBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE_STUDENT,
      page: () => const ProfileStudentView(),
      binding: ProfileStudentBinding(),
    ),
    GetPage(
      name: _Paths.FACULTY_FEEDBACK,
      page: () => const FacultyFeedbackView(),
      binding: FacultyFeedbackBinding(),
    ),
    GetPage(
      name: Routes.EVALUATION_FORM, // ชื่อต้องตรงกัน
      page: () => const EvaluationFormView(),
      binding: FacultyFeedbackBinding(), // หรือ Binding ที่คุณสร้างไว้
    ),
    GetPage(
      name: _Paths.STUDENT_NOTI,
      page: () => const StudentNotiView(),
      binding: StudentNotiBinding(),
    ),
  ];
}
