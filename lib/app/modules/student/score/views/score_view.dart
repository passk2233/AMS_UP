import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:get/get.dart';
import '../controllers/score_controller.dart';

class ScoreView extends GetView<ScoreController> {
  const ScoreView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ScoreController());
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Header Title
                  const Text(
                    "ຄະແນນ (Score)",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Profile Summary
                  _buildProfileSummary(),

                  const SizedBox(height: 20),

                  // Blue Stat Cards (GPA, Credits, Terms)
                  _buildScoreStats(),

                  const SizedBox(height: 25),

                  // Tab Selection (Terms)
                  _buildTermSelector(),

                  const SizedBox(height: 20),

                  // List of Subject Scores
                  _buildScoreList(),

                  const SizedBox(height: 100), // ເພື່ອບໍ່ໃຫ້ Bottom Bar ບັງ
                ],
              ),
            ),
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
          children: const [
            Text(
              "Souksakhone SAYYAVONG",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text("225Q006922", style: TextStyle(color: Colors.blueAccent)),
            Text(
              "Computer Science • Junior",
              style: TextStyle(color: Colors.green, fontSize: 13),
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
          _statItem("GPA", "3.69", "/4.00", Icons.bar_chart),
          _statItem("Credits", "36", "/160", Icons.credit_card),
          _statItem("Terms", "7", "/8", Icons.grid_view),
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
    return Column(
      children: [
        _scoreCard(
          "115LS101",
          "3 Credits",
          "Database System 2",
          "ຣສ ຫາ ບຸນທັນ",
          "A",
          Colors.blue,
        ),
        _scoreCard(
          "225WT111",
          "3 Credits",
          "Web Programming",
          "ຣສ ແສງລັດສະໝີ ຈັນທະມານີວົງ",
          "B",
          Colors.orange,
        ),
        _scoreCard(
          "224T665L",
          "2 Credits",
          "ການເປັນຜູ້ປະກອບການ",
          "ອຈ ເກສອນ ແບບສະຖານ",
          "B+",
          Colors.green,
        ),
      ],
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
