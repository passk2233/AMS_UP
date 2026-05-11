import 'package:get/get.dart';

class StudentNotiController extends GetxController {
  var selectedFilterIndex = 0.obs;

  // ສ້າງ List ຂໍ້ມູນທັງໝົດ
  final allNotifications = [
    {
      "type": "Urgent",
      "category": "Academic",
      "title": "Classroom",
      "sub": "Database System 2",
      "status": "Cancel Class",
      "time": "5m ago",
    },
    {
      "type": "Normal",
      "category": "Room Booking",
      "title": "Booking Confirmed",
      "desc": "Room A301 has been booked for your study group on Jan 26.",
      "time": "Today, 09:15",
    },
    {
      "type": "Normal",
      "category": "Academic",
      "title": "Grade Released",
      "desc":
          "Final results for Database System 2 Assignment are now available.",
      "time": "Yesterday",
    },
    {
      "type": "Normal",
      "category": "Academic",
      "title": "Spring Registration",
      "desc": "Spring 2026 course registration is now open for all juniors.",
      "time": "2 day ago",
    },
  ].obs;

  // ຟັງຊັນກອງຂໍ້ມູນຕາມ Category
  List get filteredNotifications {
    if (selectedFilterIndex.value == 0) return allNotifications;

    String category = selectedFilterIndex.value == 1
        ? "Academic"
        : "Room Booking";
    return allNotifications
        .where((noti) => noti['category'] == category)
        .toList();
  }

  final count = 0.obs;
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;
}
