import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:get/get.dart';
import '../controllers/profile_student_controller.dart';

class ProfileStudentView extends GetView<ProfileStudentController> {
  const ProfileStudentView({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // 1. ส่วนหัว Profile (รูปภาพและชื่อ)
            _buildProfileHeader(),
            const SizedBox(height: 25),

            // 2. หมวดหมู่: Personal Information
            _buildSectionTitle("PERSONAL INFORMATION"),
            _buildInfoCard([
              _infoTile(Icons.transgender, "Gender", "Female"),
              _infoTile(Icons.cake_outlined, "Date of Birth", "17 Sep 2004"),
              _infoTile(Icons.flag_outlined, "Nationality", "Lao"),
              _infoTile(
                Icons.location_on_outlined,
                "Address",
                "Vientiane, Lao",
              ),
              _infoTile(
                Icons.email_outlined,
                "Email Address",
                "Souksakhone.sayyavong@gmail.com",
              ),
              _infoTile(
                Icons.phone_android_outlined,
                "Phone Number",
                "+856 20 7722 7896",
              ),
            ]),

            const SizedBox(height: 20),

            // 3. หมวดหมู่: Academic Information
            _buildSectionTitle("ACADEMIC INFORMATION"),
            _buildInfoCard([
              _infoTile(
                Icons.star_outline,
                "Current GPA",
                "3.68 / 4.0",
                valueColor: Colors.blueAccent,
              ),
            ]),

            const SizedBox(height: 20),

            // 4. หมวดหมู่: Account Settings (ปุ่มที่กดได้)
            _buildSectionTitle("ACCOUNT SETTINGS"),
            _buildInfoCard([
              _actionTile(Icons.vpn_key_outlined, "Change Password"),
              _actionTile(Icons.notifications_none, "Notifications"),
              _actionTile(Icons.security_outlined, "Privacy Policy"),
            ]),

            const SizedBox(height: 30),

            // 5. ปุ่ม Sign Out
            _buildSignOutButton(),

            const SizedBox(height: 10),
            const Text(
              "App version 2.0.1",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 100), // ระยะเผื่อ Bottom Bar
          ],
        ),
      ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Souksakhone SAYYAVONG",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "Student ID: 225Q006922",
                style: TextStyle(color: Colors.blueAccent, fontSize: 13),
              ),
              Text(
                "Computer Science • Junior",
                style: TextStyle(color: Colors.green, fontSize: 13),
              ),
            ],
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
        onPressed: () {},
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
