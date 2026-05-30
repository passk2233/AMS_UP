import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Data holder describing a single destination in [AppBottomNav].
///
/// - [icon]: glyph rendered above the [label].
/// - [label]: short text shown under the icon (10pt).
/// - [badgeCount]: optional unread count — when > 0, a red Material [Badge]
///   is overlaid on the icon.
class AppNavItem {
  /// Glyph rendered for this destination.
  final IconData icon;

  /// Caption rendered under the glyph.
  final String label;

  /// Optional unread / pending count rendered as a corner badge.
  final int? badgeCount;

  const AppNavItem({
    required this.icon,
    required this.label,
    this.badgeCount,
  });
}

/// Shared bottom navigation bar used by all three roles (admin, teacher,
/// student). Renders a horizontal row of [_AppNavTile]s on a white surface
/// with a top shadow.
///
/// The widget is fully controlled — the parent owns the selection state and
/// emits the chosen index via [onTap]. This keeps the bar testable in
/// isolation and free of any GetX dependency.
///
/// ```dart
/// AppBottomNav(
///   items: const [
///     AppNavItem(icon: Icons.home, label: 'ໜ້າຫຼັກ'),
///     AppNavItem(icon: Icons.calendar_month, label: 'ຕາຕະລາງ'),
///   ],
///   selectedIndex: controller.selectedIndex.value,
///   onTap: controller.changeTab,
/// )
/// ```
class AppBottomNav extends StatelessWidget {
  /// Destinations to render — typically 3–5 entries per design guidance.
  final List<AppNavItem> items;

  /// Currently active index in [items]; tile at this position is highlighted.
  final int selectedIndex;

  /// Invoked with the tapped index when the user changes destination.
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
            children: [
              for (var i = 0; i < items.length; i++)
                _AppNavTile(
                  item: items[i],
                  isSelected: i == selectedIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single tappable destination inside [AppBottomNav].
///
/// Visual states:
/// - Selected: tinted background, brand-colored icon + label, bold caption.
/// - Idle: transparent background, gray icon + label.
class _AppNavTile extends StatelessWidget {
  /// Source data (icon, label, optional badge count).
  final AppNavItem item;

  /// Whether this tile represents the active destination.
  final bool isSelected;

  /// Tap handler.
  final VoidCallback onTap;

  const _AppNavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final idleColor = Colors.grey.shade400;
    final tint = isSelected ? activeColor : idleColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(
          minWidth: AppColors.minTouchTarget,
          minHeight: AppColors.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppColors.buttonRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BadgedIcon(item: item, color: tint),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: tint,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The destination glyph with an optional corner badge for unread counts.
class _BadgedIcon extends StatelessWidget {
  /// Source data — only [AppNavItem.icon] and [AppNavItem.badgeCount] are read.
  final AppNavItem item;

  /// Tint applied to the icon.
  final Color color;

  const _BadgedIcon({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(item.icon, color: color, size: 24);
    final count = item.badgeCount ?? 0;
    if (count <= 0) return icon;

    return Badge(
      label: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.rejectRed,
      offset: const Offset(6, -4),
      child: icon,
    );
  }
}
