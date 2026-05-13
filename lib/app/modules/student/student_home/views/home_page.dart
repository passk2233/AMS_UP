import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:frontend/app/modules/student/faculty_feedback/controllers/faculty_feedback_controller.dart';
import 'package:frontend/app/modules/student/score/controllers/score_controller.dart';
import 'package:frontend/app/modules/student/profile_student/controllers/profile_student_controller.dart';
import 'package:frontend/app/modules/student/schedule_student/controllers/schedule_student_controller.dart';
import 'package:frontend/app/modules/student/Booking_student/controllers/booking_student_controller.dart';
import 'package:frontend/app/routes/app_pages.dart';
import 'package:frontend/app/utilities/assets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Get.put(ProfileStudentController(), permanent: true);
    final score = Get.put(ScoreController(), permanent: true);
    final schedule = Get.put(ScheduleStudentController(), permanent: true);
    final booking = Get.put(BookingStudentController(), permanent: true);
    final faculty = Get.put(FacultyFeedbackController(), permanent: true);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage(AssetImages.login2), fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Obx(
              () => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _topHeader(),
                  const SizedBox(height: 12),
                  _profile(profile),
                  const SizedBox(height: 12),
                  _stats(score),
                  const SizedBox(height: 16),
                  _todaysClasses(schedule),
                  const SizedBox(height: 16),
                  _myBooking(booking),
                  const SizedBox(height: 16),
                  _facultySummary(faculty),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topHeader() {
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
        IconButton(onPressed: () => Get.toNamed(Routes.STUDENT_NOTI), icon: const Icon(Icons.notifications_none, size: 28)),
      ],
    );
  }

  Widget _profile(ProfileStudentController c) {
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
            Text(c.displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(c.studentCode, style: const TextStyle(color: Colors.blueAccent)),
            Text(c.program, style: const TextStyle(color: Colors.green, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _stats(ScoreController c) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF4A68FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem("GPA", c.gpa.toStringAsFixed(2), Icons.bar_chart),
          _statItem("Credits", c.earnedCredits.toString(), Icons.credit_card),
          _statItem("Courses", c.enrollments.length.toString(), Icons.grid_view),
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

  Widget _todaysClasses(ScheduleStudentController c) {
    final classes = c.filteredSchedules.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Classes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (classes.isEmpty) const Text('No classes found.'),
        ...classes.map((item) => _classCard(
              item['title']?.toString() ?? '-',
              item['subtitle']?.toString() ?? '-',
              item['time']?.toString() ?? '-',
              item['color'] as Color? ?? Colors.blue,
              item['instructor']?.toString() ?? '-',
            )),
      ],
    );
  }

  Widget _classCard(String title, String desc, String time, Color color, String teacher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc),
          const SizedBox(height: 4),
          Text(teacher, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _myBooking(BookingStudentController c) {
    final myLatest = c.allBookings.isEmpty ? null : c.allBookings.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("My booking", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (myLatest == null) const Text('No booking found.'),
        if (myLatest != null)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${myLatest.bookingDate.toLocal()}'.split(' ')[0], style: const TextStyle(color: Colors.blue, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${myLatest.startTime} - ${myLatest.endTime}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Text(myLatest.purpose ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(myLatest.room?.roomCode ?? '-', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(myLatest.status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _facultySummary(FacultyFeedbackController c) {
    final list = c.facultyList.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Faculty Feedback", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => Get.toNamed(Routes.FACULTY_FEEDBACK), child: const Text("See All")),
          ],
        ),
        if (list.isEmpty) const Text('No faculty found.'),
        ...list.map((f) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.blue[50], child: Text(f.initials)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(f.name), Text(f.course, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
                  Text(f.isSubmitted ? 'Submitted' : 'Pending', style: TextStyle(color: f.isSubmitted ? Colors.green : Colors.orange)),
                ],
              ),
            )),
      ],
    );
  }
}
