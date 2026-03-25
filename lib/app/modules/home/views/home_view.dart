import 'package:flutter/material.dart';
import 'package:frontend/app/modules/home/controllers/home_controller.dart';
import 'package:get/get.dart';
// ຢ່າລືມ Import

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController()); // ຜູກ Controller

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart CEIT Dashboard'),
        backgroundColor: const Color(0xFF3B95B7),
      ),
      body: Obx(() {
        // ຖ້າກຳລັງໂຫຼດສິດຢູ່ ໃຫ້ໝຸນໆໄປກ່ອນ
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'ເມນູການໃຊ້ງານຂອງທ່ານ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 🟢 ເມນູສຳລັບ ນັກສຶກສາ (Student)
            if (controller.isStudent.value) ...[
              _buildMenuCard(
                icon: Icons.calendar_month,
                title: 'ຕາຕະລາງຮຽນ',
                color: Colors.blue,
                onTap: () { /* ໄປໜ້າຕາຕະລາງ */ },
              ),
              _buildMenuCard(
                icon: Icons.room_preferences,
                title: 'ຈອງຫ້ອງສຳລັບກິດຈະກຳ',
                color: Colors.lightBlue,
                onTap: () { /* ໄປໜ້າຈອງຫ້ອງ */ },
              ),
            ],

            // 🟠 ເມນູສຳລັບ ອາຈານ (Teacher)
            if (controller.isTeacher.value) ...[
              _buildMenuCard(
                icon: Icons.history_edu,
                title: 'ບັນທຶກການສອນ (Teaching Logs)',
                color: Colors.orange,
                onTap: () { /* ໄປໜ້າບັນທຶກການສອນ */ },
              ),
              _buildMenuCard(
                icon: Icons.door_front_door,
                title: 'ຮ້ອງຂໍຈອງຫ້ອງສອນ',
                color: Colors.deepOrange,
                onTap: () { /* ໄປໜ້າຮ້ອງຂໍຈອງຫ້ອງ */ },
              ),
            ],

            // 🔴 ເມນູສຳລັບ ຜູ້ເບິ່ງແຍງລະບົບ (Admin)
            if (controller.isAdmin.value) ...[
              const Divider(height: 40, thickness: 2),
              const Text(
                'Admin Panel',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                icon: Icons.fact_check,
                title: 'ອະນຸມັດການຈອງຫ້ອງ',
                color: Colors.red,
                onTap: () { /* ໄປໜ້າອະນຸມັດ */ },
              ),
              _buildMenuCard(
                icon: Icons.manage_accounts,
                title: 'ຈັດການສິດຜູ້ໃຊ້ງານ (Roles)',
                color: Colors.redAccent,
                onTap: () { /* ໄປໜ້າຈັດການສິດ */ },
              ),
            ],
          ],
        );
      }),
    );
  }

  // 🧱 Widget ສຳລັບສ້າງປຸ່ມເມນູງາມໆ
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}