import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // <--- ต้องมีบรรทัดนี้เพื่อแก้ตัวแดงตรง DateFormat
import '../controllers/schedule_student_controller.dart';

class ScheduleStudentView extends GetView<ScheduleStudentController> {
  const ScheduleStudentView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ScheduleStudentController>()) {
      Get.put(ScheduleStudentController());
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Schedule',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        actions: [
          Obx(
            () => Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  controller.currentMonthYear,
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarStrip(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final list = controller.filteredSchedules;

              if (list.isEmpty) {
                return const Center(
                  child: Text(
                    'Today is free! No classes scheduled.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return _buildScheduleCard(
                    date: item['date'],
                    title: item['title'],
                    subtitle: item['subtitle'],
                    time: item['time'],
                    instructor: item['instructor'],
                    location: item['location'],
                    color: item['color'],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ปุ่มย้อนกลับ 1 สัปดาห์
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.blue),
            onPressed: () => controller.changeWeek(-7),
          ),

          // รายการวันที่ 7 วัน
          Expanded(
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: controller.currentWeek.map((date) {
                  bool isSelected =
                      date.day == controller.selectedDate.value.day &&
                      date.month == controller.selectedDate.value.month &&
                      date.year == controller.selectedDate.value.year;

                  return GestureDetector(
                    onTap: () => controller.selectDate(date),
                    child: _buildDateItem(
                      DateFormat('EEE').format(date),
                      date.day.toString(),
                      isSelected,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ปุ่มไปข้างหน้า 1 สัปดาห์
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.blue),
            onPressed: () => controller.changeWeek(7),
          ),
        ],
      ),
    );
  }

  Widget _buildDateItem(String day, String date, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blue,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    required DateTime date,
    required String title,
    required String subtitle,
    required String time,
    required String instructor,
    required String location,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _showDetailSchedule(
        // เมื่อกดจะเรียกฟังก์ชันนี้
        date: date,
        title: title,
        subtitle: subtitle,
        time: time,
        instructor: instructor,
        location: location,
        color: color,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(instructor, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showDetailSchedule({
  required DateTime date,
  required String title,
  required String subtitle,
  required String time,
  required String instructor,
  required String location,
  required Color color,
}) {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // เส้นขีดด้านบน (Handle)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // หัวข้อและปุ่มปิด
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Schedule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ],
            ),

            // ส่วนแสดงชื่อวิชาและเวลา (พื้นหลังสีฟ้าอ่อน)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              DateFormat('EEE, MMM d').format(date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              time,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // รายละเอียดต่างๆ
            _buildDetailField("Section", subtitle),
            _buildDetailField("Location", location),
            _buildDetailField("Teacher", instructor),
            _buildDetailField("Date", DateFormat('yyyy-MM-dd').format(date)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
    isScrollControlled: true, // เพื่อให้เลื่อนได้ถ้าข้อมูลยาว
  );
}

// Helper สำหรับสร้างช่องข้อมูล
Widget _buildDetailField(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
