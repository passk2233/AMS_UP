import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:get/get.dart';
import '../controllers/profile_student_controller.dart';

class ProfileStudentView extends GetView<ProfileStudentController> {
  const ProfileStudentView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfileStudentController>()) {
      Get.put(ProfileStudentController());
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // สีพื้นหลังเทาอ่อนตามแบบ
      appBar: AppBar(
        leading: const Icon(
          Icons.arrow_back_ios,
          size: 20,
          color: Colors.black,
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
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
              _buildProfileHeader(),
              const SizedBox(height: 25),

              _buildSectionTitle("PERSONAL INFORMATION"),
              _buildInfoCard([
                _infoTile(Icons.transgender, "Gender", controller.gender),
                _infoTile(
                  Icons.cake_outlined,
                  "Date of Birth",
                  controller.dob == null
                      ? '-'
                      : '${controller.dob!.day}/${controller.dob!.month}/${controller.dob!.year}',
                ),
                _infoTile(Icons.flag_outlined, "Nationality", controller.nationality),
                _infoTile(Icons.location_on_outlined, "Address", controller.address),
                _infoTile(Icons.email_outlined, "Email Address", controller.email),
                _infoTile(Icons.phone_android_outlined, "Phone Number", controller.phone),
              ]),

              const SizedBox(height: 20),

              _buildSectionTitle("ACADEMIC INFORMATION"),
              _buildInfoCard([
                _infoTile(
                  Icons.school_outlined,
                  "Program",
                  controller.program,
                  valueColor: Colors.blueAccent,
                ),
              ]),

              const SizedBox(height: 20),

              _buildSectionTitle("ACCOUNT SETTINGS"),
              _buildInfoCard([
                _actionTile(Icons.vpn_key_outlined, "Change Password"),
                _actionTile(Icons.notifications_none, "Notifications"),
                _actionTile(Icons.security_outlined, "Privacy Policy"),
              ]),

              const SizedBox(height: 30),

              _buildSignOutButton(),

              const SizedBox(height: 10),
              const Text(
                "App version 2.0.1",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }

  // --- Widgets ย่อย ---

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundImage: AssetImage(AssetImages.profile2), // รูปของคุณ
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.displayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Student ID: ${controller.studentCode}",
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 13),
                ),
                Text(
                  controller.program,
                  style: const TextStyle(color: Colors.green, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  // แถวแสดงข้อมูล (กดไม่ได้)
  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blueAccent, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: valueColor ?? Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // แถวปุ่มตั้งค่า (กดได้)
  Widget _actionTile(IconData icon, String label) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: () {
        // ใส่ฟังก์ชันไปหน้าตั้งค่าที่นี่
      },
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: controller.logout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          "Sign Out",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
