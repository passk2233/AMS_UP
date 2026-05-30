import 'package:get/get.dart';

import '../controllers/booking_controller.dart';

/// GetX binding for [BookingView] — lazily registers
/// [BookingController] on first navigation.
class BookingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingController>(BookingController.new);
  }
}
