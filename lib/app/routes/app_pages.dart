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

  static const INITIAL = Routes.HOME_STUDENT;

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
