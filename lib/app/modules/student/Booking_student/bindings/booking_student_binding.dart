import 'package:get/get.dart';

import '../controllers/booking_student_controller.dart';

class BookingStudentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingStudentController>(
      () => BookingStudentController(),
    );
  }
}
