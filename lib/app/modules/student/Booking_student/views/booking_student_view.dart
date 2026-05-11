import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/booking_student_controller.dart';

class BookingStudentView extends GetView<BookingStudentController> {
  const BookingStudentView({super.key});

  @override
  Widget build(BuildContext context) {
    // ป้องกัน Error หากลืมฉีด Controller เข้ามาในระบบ
    if (!Get.isRegistered<BookingStudentController>()) {
      Get.put(BookingStudentController());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AssetImages.login2),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Title ตรงกลาง
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      'CEIT Room Booking',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                // 3. ส่วนแสดงเดือน และปุ่ม View Calendar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A80F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Obx(
                          () => Text(
                            DateFormat(
                              'MMMM yyyy',
                            ).format(controller.selectedDate.value),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'View Calendar',
                          style: TextStyle(
                            color: Color(0xFF4A80F0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. แถบปฏิทิน 7 วัน (พอดีหน้าจอ)
                _buildCalendarSection(),

                // 5. ปุ่มเลือกตึก
                _buildBuildingFilters(),

                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 15, bottom: 10),
                  child: Text(
                    'Available Rooms',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // 6. รายการห้อง
                Expanded(child: _buildRoomList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF4A80F0)),
            onPressed: () => controller.generateWeek(
              controller.selectedDate.value.subtract(const Duration(days: 7)),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // คำนวณความกว้าง: (พื้นที่ทั้งหมด - ช่องว่างรวม) / 7 วัน
                double bubbleWidth = (constraints.maxWidth - (6 * 4)) / 7;
                return Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: controller.currentWeek.map((date) {
                      bool isSelected =
                          date.day == controller.selectedDate.value.day &&
                          date.month == controller.selectedDate.value.month;
                      return GestureDetector(
                        onTap: () => controller.selectDate(date),
                        child: _DateBubble(
                          width: bubbleWidth,
                          day: DateFormat('EEE').format(date),
                          date: date.day.toString(),
                          isSelected: isSelected,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF4A80F0)),
            onPressed: () => controller.generateWeek(
              controller.selectedDate.value.add(const Duration(days: 7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingFilters() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: ['All Rooms', 'ตึก CEIT', 'ตึก A'].map((label) {
            bool isActive = controller.selectedBuilding.value == label;
            return GestureDetector(
              onTap: () => controller.changeBuilding(label),
              child: Container(
                margin: const EdgeInsets.only(right: 10, top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1A1C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoomList() {
    return Obx(
      () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.filteredRooms.length,
        itemBuilder: (context, index) {
          var room = controller.filteredRooms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.grey.shade100),
            ),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.meeting_room, color: Colors.grey),
                  ),
                  title: Text(
                    room['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Capacity: ${room['capacity']}\n${room['facilities']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (room['slots'] as List).map((slot) {
                      bool isBooked = slot['status'] == 'booked';
                      return Obx(() {
                        bool isSelected =
                            controller.selectedSlots[room['name']] ==
                            slot['time'];
                        return ChoiceChip(
                          label: Text(
                            slot['time'],
                            style: TextStyle(
                              fontSize: 11,
                              color: isBooked
                                  ? Colors.grey
                                  : (isSelected ? Colors.white : Colors.black),
                              decoration: isBooked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: isBooked
                              ? null
                              : (val) {
                                  controller.selectSlot(
                                    room['name'],
                                    slot['time'],
                                  );
                                  _showConfirmDialog(
                                    context,
                                    room['name'],
                                    slot['time'],
                                  );
                                },
                          selectedColor: const Color(0xFF4A80F0),
                          backgroundColor: isBooked
                              ? Colors.grey[100]
                              : Colors.white,
                        );
                      });
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String roomName, String time) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "ຕ້ອງການຈອງຫ້ອງ $roomName\nວັນທີ ${DateFormat('dd MMM').format(controller.selectedDate.value)}\nເວລາ $time",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Section",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: "ກະລຸນາກອກເຫດຜົນທີ່ຈອງ",
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: Colors.blue[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.bookSlot(roomName, time);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Confirm",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBubble extends StatelessWidget {
  final String day, date;
  final bool isSelected;
  final double width;

  const _DateBubble({
    required this.day,
    required this.date,
    required this.isSelected,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4A80F0) : const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blue.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blue.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
