import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_colors.dart';
import 'teacher_bottom_nav_controller.dart';

class TeacherBottomNavBar extends StatelessWidget {
  const TeacherBottomNavBar({super.key});

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.dashboard_rounded, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'ຕາຕະລາງ'),
    _NavItem(icon: Icons.meeting_room_outlined, activeIcon: Icons.meeting_room_rounded, label: 'ຈອງຫ້ອງ'),
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'ການປະເມີນ'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'ໂປຣໄຟລ໌'),
  ];

  @override
  Widget build(BuildContext context) {
    final navCtrl = Get.isRegistered<TeacherBottomNavController>()
        ? Get.find<TeacherBottomNavController>()
        : Get.put(TeacherBottomNavController(), permanent: true);

    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            // Active dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSelected ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
