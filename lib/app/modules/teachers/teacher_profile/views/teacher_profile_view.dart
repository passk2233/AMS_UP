import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../profiles/controllers/profiles_controller.dart';

class TeacherProfileView extends GetView<ProfilesController> {
  const TeacherProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // If controller is not registered, put it
    if (!Get.isRegistered<ProfilesController>()) {
      Get.put(ProfilesController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
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

              _buildSectionTitle("ACCOUNT INFORMATION"),
              _buildInfoCard([
                _infoTile(
                    Icons.badge_outlined, "User ID", '${controller.user.value?.id ?? '-'}'),
                _infoTile(Icons.account_circle_outlined, "Username",
                    controller.user.value?.username ?? '-'),
                _infoTile(Icons.email_outlined, "Email",
                    controller.user.value?.email ?? '-'),
                _infoTile(
                  Icons.verified_user_outlined,
                  "Status",
                  controller.accountStatus,
                  valueColor: controller.user.value?.active == 1
                      ? Colors.green
                      : Colors.red,
                ),
              ]),

              const SizedBox(height: 20),

              _buildSectionTitle("ROLES & PERMISSIONS"),
              _buildRolesSection(),

              const SizedBox(height: 20),

              _buildSectionTitle("ACTIVITY"),
              _buildInfoCard([
                _infoTile(Icons.calendar_today_outlined, "Member Since",
                    controller.memberSince),
                _infoTile(
                  Icons.update_outlined,
                  "Last Updated",
                  controller.user.value?.updatedAt != null
                      ? '${controller.user.value!.updatedAt!.day}/${controller.user.value!.updatedAt!.month}/${controller.user.value!.updatedAt!.year}'
                      : '-',
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

  // --- Widgets ---

  Widget _buildProfileHeader() {
    final user = controller.user.value;
    String displayName = user?.username ?? '-';
    String email = user?.email ?? '-';
    List<String> roles = user?.roles ?? [];

    // Try to get teacher name
    if (user?.teacher != null) {
      final t = user!.teacher!;
      final name = '${t.nameLao} ${t.surnameLao}'.trim();
      if (name.isNotEmpty) displayName = name;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.blue[100],
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  email,
                  style: const TextStyle(
                      color: Colors.blueAccent, fontSize: 13),
                ),
                if (roles.isNotEmpty)
                  Text(
                    roles.join(', '),
                    style: const TextStyle(
                        color: Colors.green, fontSize: 13),
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

  Widget _buildRolesSection() {
    final roles = controller.user.value?.roles;
    if (roles == null || roles.isEmpty) {
      return _buildInfoCard([
        _infoTile(Icons.person_outline, "Role", "No roles assigned"),
      ]);
    }
    return _buildInfoCard(
      roles.map((r) {
        final info = _getRoleInfo(r);
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: info.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, color: info.color, size: 20),
          ),
          title: Text(
            r,
            style: TextStyle(
              color: info.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            info.desc,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          trailing: Icon(Icons.check_circle_rounded,
              color: info.color, size: 18),
        );
      }).toList(),
    );
  }

  _RoleInfo _getRoleInfo(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return _RoleInfo(Icons.shield_rounded, Colors.indigo,
            'Full system access');
      case 'teacher':
        return _RoleInfo(Icons.school_rounded, Colors.green,
            'Teaching & evaluation management');
      case 'student':
        return _RoleInfo(Icons.menu_book_rounded, Colors.orange,
            'Learning data access');
      default:
        return _RoleInfo(
            Icons.person_rounded, Colors.grey, 'General role');
    }
  }

  // Info tile (non-tappable)
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

  // Action tile (tappable)
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
        // Navigate to settings page
      },
    );
  }

  Widget _buildSignOutButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed:
              controller.isLoggingOut.value ? null : controller.logout,
          icon: controller.isLoggingOut.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.red),
                )
              : const Icon(Icons.logout, color: Colors.red),
          label: Text(
            controller.isLoggingOut.value ? 'Signing out...' : 'Sign Out',
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleInfo {
  final IconData icon;
  final Color color;
  final String desc;
  const _RoleInfo(this.icon, this.color, this.desc);
}
