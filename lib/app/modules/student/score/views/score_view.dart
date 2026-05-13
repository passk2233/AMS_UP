import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:get/get.dart';
import '../controllers/score_controller.dart';

class ScoreView extends GetView<ScoreController> {
  const ScoreView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ScoreController>()) {
      Get.put(ScoreController());
    }
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image (ໃຊ້ຮູບດຽວກັນກັບໜ້າ Home ເພື່ອໃຫ້ Theme ຄືກັນ)
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
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value.isNotEmpty) {
                return Center(child: Text(controller.errorMessage.value));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "ຄະແນນ (Score)",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    _buildProfileSummary(),

                    const SizedBox(height: 20),

                    _buildScoreStats(),

                    const SizedBox(height: 25),

                    _buildTermSelector(),

                    const SizedBox(height: 20),

                    _buildScoreList(),

                    const SizedBox(height: 100),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- Widgets ສ່ວນຕ່າງໆ ---

  Widget _buildProfileSummary() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 35,
          backgroundImage: AssetImage(AssetImages.profile2),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.displayName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(controller.studentCode, style: const TextStyle(color: Colors.blueAccent)),
            Text(
              controller.currentUser.value?.student?.curriculum?.curriNameEng ??
                  controller.currentUser.value?.student?.curriculum?.curriNameLao ??
                  '-',
              style: const TextStyle(color: Colors.green, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreStats() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF4A68FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem("GPA", controller.gpa.toStringAsFixed(2), "/4.00", Icons.bar_chart),
          _statItem("Credits", controller.earnedCredits.toString(), "", Icons.credit_card),
          _statItem("Courses", controller.enrollments.length.toString(), "", Icons.grid_view),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value, String total, IconData icon) {
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
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: total,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTermSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Current Semester Scores",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Obx(
            () => Row(
              children: List.generate(8, (index) {
                return _termButton(
                  "Term ${index + 1}",
                  controller.selectedTermIndex.value == index,
                  // ເຊັກວ່າແມ່ນ Index ທີ່ເລືອກບໍ່
                  index,
                );
              }),
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _termButton(String label, bool isSelected, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: OutlinedButton(
        onPressed: () {
          controller.changeTerm(index); // ສັ່ງປ່ຽນຄ່າໃນ Controller ເວລາຖືກກົດ
        },
        style: OutlinedButton.styleFrom(
          // ປ່ຽນສີຕາມຄ່າ isSelected
          backgroundColor: isSelected ? const Color(0xFF4A68FF) : Colors.white,
          side: BorderSide(
            color: isSelected ? const Color(0xFF4A68FF) : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: isSelected ? 4 : 0, // ເພີ່ມເງົາໜ້ອຍໜຶ່ງເວລາເລືອກ
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreList() {
    final items = controller.enrollments;
    if (items.isEmpty) {
      return const Center(child: Text('No scores found.'));
    }

    return Column(
      children: items.map((e) {
        final sub = e.studyPlan?.subject;
        final teacher = e.studyPlan?.teacher;
        final code = sub?.subjectCode ?? '-';
        final credit = sub?.credit ?? 0;
        final title = sub?.nameEng ?? sub?.nameLao ?? '-';
        final teacherName = teacher?.nameEng ?? teacher?.nameLao ?? '-';
        final grade = e.grade ?? '-';
        final color = grade == 'A'
            ? Colors.blue
            : (grade == 'B+' || grade == 'B')
                ? Colors.green
                : Colors.orange;

        return _scoreCard(
          code,
          '$credit Credits',
          title,
          teacherName,
          grade,
          color,
        );
      }).toList(),
    );
  }

  Widget _scoreCard(
    String code,
    String credits,
    String title,
    String teacher,
    String grade,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$code  ~ $credits",
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  teacher,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "EXCELLENT",
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
