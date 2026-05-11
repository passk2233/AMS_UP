import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_colors.dart';
import 'bottom_nav_controller.dart';

/// A premium, reusable bottom navigation bar for admin pages.
///
/// Usage: just place `const AdminBottomNavBar()` in any Scaffold's
/// `bottomNavigationBar` property. It will automatically find the
/// shared [BottomNavController] via GetX.
class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({super.key});

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.verified_outlined, label: 'ການຢືນຢັນ'),
    _NavItem(icon: Icons.notifications_outlined, label: 'ການປະກາດ'),
    _NavItem(icon: Icons.assignment_outlined, label: 'ການປະເມີນ'),
    _NavItem(icon: Icons.person_outline, label: 'ໂປຣໄຟລ໌'),
  ];

  @override
  Widget build(BuildContext context) {
    final navCtrl = Get.isRegistered<BottomNavController>()
        ? Get.find<BottomNavController>()
        : Get.put(BottomNavController(), permanent: true);

    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _items.length,
                (index) => _buildNavItem(
                  item: _items[index],
                  isSelected: navCtrl.selectedIndex.value == index,
                  onTap: () => navCtrl.changeTab(index),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem({
    required _NavItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal data holder for a bottom nav item.
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
