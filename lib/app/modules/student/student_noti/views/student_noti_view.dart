import 'package:flutter/material.dart';
import 'package:frontend/app/modules/student/student_noti/views/booking_detail.dart';
import 'package:frontend/app/modules/student/student_noti/views/grade_noti.dart';
import 'package:get/get.dart';
import '../controllers/student_noti_controller.dart';

class StudentNotiView extends GetView<StudentNotiController> {
  const StudentNotiView({super.key});

  @override
  Widget build(BuildContext context) {
    // ໃຊ້ Get.put ເພື່ອໂຫຼດ Controller ເຂົ້າ Memory
    Get.put(StudentNotiController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Alerts Center',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Filter Tabs
          _buildFilterTabs(),

          // 2. Notification List
          Expanded(
            child: Obx(() {
              final list = controller.filteredNotifications;

              if (list.isEmpty) {
                return const Center(child: Text("No notifications found"));
              }

              // ພາຍໃນ Obx ຂອງ Notification List
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: list.length, // ໃຊ້ຈຳນວນຕາມຂໍ້ມູນທີ່ມີແທ້ໆ
                itemBuilder: (context, index) {
                  // ຕ້ອງກວດເຊັກກ່ອນສະເໝີວ່າ index ບໍ່ເກີນຂະໜາດຂອງ list
                  if (index >= list.length) return const SizedBox.shrink();

                  final item = list[index];

                  // 1. ສໍາລັບ Urgent Card
                  if (item['type'] == 'Urgent') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "URGENT ALERTS",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => Get.to(
                              () => const GradeNotiView(),
                            ), // ລິ້ງໄປໜ້າ Grade
                            child: _buildUrgentCard(
                              item['title']!,
                              item['sub']!,
                              item['status']!,
                              item['time']!,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // 2. ສໍາລັບ Normal Card
                  return _buildRecentCard(
                    icon: item['category'] == 'Academic'
                        ? Icons.stars_outlined
                        : Icons.assignment_turned_in_outlined,
                    iconColor: item['category'] == 'Academic'
                        ? Colors.blue
                        : Colors.green,
                    title: item['title']!,
                    desc: item['desc']!,
                    time: item['time']!,
                    onTap: () {
                      // ກວດເຊັກ Title ໃຫ້ກົງກັບຂໍ້ມູນໃນ Controller ຂອງເຈົ້າ
                      if (item['title'] == "Grade Released") {
                        Get.to(() => const GradeNotiView()); // ໄປໜ້າ Grade
                      } else if (item['title'] == "Booking Confirmed") {
                        Get.to(
                          () => const BookingDetailView(),
                        ); // ໄປໜ້າ Booking
                      }
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ສ່ວນເລືອກ Filter
  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Obx(
        () => Row(
          children: [
            _filterItem("All", 0),
            _filterItem("Academic", 1),
            _filterItem("Room Booking", 2),
          ],
        ),
      ),
    );
  }

  Widget _filterItem(String label, int index) {
    bool isSelected = controller.selectedFilterIndex.value == index;
    return GestureDetector(
      onTap: () => controller.selectedFilterIndex.value = index,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A68FF) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? null
              : [const BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Card ແຈ້ງເຕືອນດ່ວນ (ສີແດງ)
  Widget _buildUrgentCard(
    String title,
    String sub,
    String status,
    String time,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.copy_all_outlined, color: Colors.redAccent),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  status,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card ແຈ້ງເຕືອນທົ່ວໄປ
  Widget _buildRecentCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String time,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
