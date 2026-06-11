import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../teacher_navigator_bar/teacher_bottom_nav_controller.dart';

/// Four-card quick-action row that jumps to the correct tab.
class TeacherQuickActionRow extends StatelessWidget {
  /// Bottom-nav controller (tap targets call
  /// [TeacherBottomNavController.changeTab]).
  final TeacherBottomNavController nav;

  const TeacherQuickActionRow({super.key, required this.nav});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.calendar_month_rounded,
            label: 'ຕາຕະລາງ',
            color: AppColors.statsBlue,
            onTap: () => nav.changeTab(TeacherTab.schedule),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.meeting_room_rounded,
            label: 'ຈອງຫ້ອງ',
            color: AppColors.borderApproved,
            onTap: () => nav.changeTab(TeacherTab.booking),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.bar_chart_rounded,
            label: 'ປະເມີນ',
            color: AppColors.borderPending,
            onTap: () => nav.changeTab(TeacherTab.evaluation),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.person_rounded,
            label: 'ໂປຣໄຟລ໌',
            color: AppColors.primary,
            onTap: () => nav.changeTab(TeacherTab.profile),
          ),
        ),
      ],
    );
  }
}

/// One tile in the quick-action row.
class _QuickAction extends StatelessWidget {
  /// Glyph rendered inside the colored bubble.
  final IconData icon;

  /// Caption.
  final String label;

  /// Tint applied to the icon bubble.
  final Color color;

  /// Tap handler.
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
