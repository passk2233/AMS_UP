import 'package:flutter/material.dart';
import 'package:frontend/app/modules/student/faculty_feedback/controllers/faculty_feedback_controller.dart';
import 'package:frontend/app/routes/app_pages.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

final facultyController = Get.put(FacultyFeedbackController());
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          // 2. Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildTopHeader(),

                  const SizedBox(height: 15),
                  _buildProfileInfo(),

                  const SizedBox(height: 25),
                  _buildStatCards(),

                  const SizedBox(height: 25),
                  _buildTodaysClassesSection(),

                  const SizedBox(height: 25),
                  _buildMyBookingSection(),

                  const SizedBox(height: 25),
                  _buildFacultyFeedbackSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. ส่วนหัวและรายการ Today's Classes
  Widget _buildTodaysClassesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Classes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Monday, Jan 26",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        _buildClassCard(
          "Database System 2",
          "Using Sub-queries to Solve Queries",
          "9:00 AM-11:00 AM",
          Colors.blue,
          "ຮສ ທາ ບຸນທັນ",
        ),
        _buildClassCard(
          "Web Programming",
          "PHP + MySQL",
          "13:00 PM-15:00 PM",
          Colors.purple,
          "ຮສ ແສງລັດສະໝີ ຈັນທະມານີວົງ",
        ),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            "——— END OF TODAY'S SCHEDULE ———",
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ),
      ],
    );
  }

  // 2. Card รายวิชา
  Widget _buildClassCard(
    String title,
    String desc,
    String time,
    Color color,
    String teacher,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              Text(
                " $teacher",
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. ส่วนหัวและ Card การจอง (My Booking)
  Widget _buildMyBookingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "My booking",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.green[50]?.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tue, 26 January 2026",
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                  Text(
                    "9:00 AM-11:00 AM",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ເຮັດກິດຈະກຳຂອງກຸ່ມ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  Text(
                    " A301",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const Divider(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 18,
                  ),
                  Text(
                    " CONFIRMED",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Spring 2026",
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            Text(
              "Welcome back",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            Get.toNamed(Routes.STUDENT_NOTI);
          },
          icon: const Icon(Icons.notifications_none, size: 28),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 35,
          backgroundImage: AssetImage(AssetImages.login1),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Souksakhone SAYYAVONG",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Text(
              "225Q006922",
              style: TextStyle(color: Colors.blueAccent),
            ),
            const Text(
              "Computer Science • Junior",
              style: TextStyle(color: Colors.green, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF4A68FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem("GPA", "3.69", Icons.bar_chart),
          _statItem("Credits", "36", Icons.credit_card),
          _statItem("Courses", "6", Icons.grid_view),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(icon, color: Colors.white70, size: 14),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFacultyFeedbackSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Faculty Feedback", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => Get.toNamed(Routes.FACULTY_FEEDBACK),
            child: const Text("See All"),
          ),
        ],
      ),
      // ใช้ Obx เพื่อให้ List อัปเดตตาม Controller อัตโนมัติ
      Obx(() => Column(
        children: facultyController.facultyList.map((faculty) {
          return _feedbackCard(
            faculty.initials, 
            faculty.name, 
            faculty.course, 
            faculty.isSubmitted
          );
        }).toList(),
      )),
    ],
  );
}

  Widget _feedbackCard(String code, String name, String sub, bool done) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: Text(code, style: const TextStyle(color: Colors.blue)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: done
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        Text(
                          " Feedback Submitted",
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue,
                      elevation: 0,
                    ),
                    child: const Text("Evaluate Now"),
                  ),
          ),
        ],
      ),
    );
  }
}
