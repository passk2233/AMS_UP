import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widget.dart';
import 'admin_app_bar_controllers.dart';

/// Gradient app bar used across every admin screen.
///
/// Renders a [_SemesterChip] on the left and a [_NotificationBubble] on the
/// right. State is owned by [AdminAppBarControllers] via GetX — the bar
/// itself is purely declarative.
///
/// The controller is resolved lazily and inserted permanently if absent so
/// the same instance survives tab switches between admin pages.
class AdminAppBar extends StatelessWidget {
  const AdminAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Side effect — ensure the controller is registered before any child
    // descendant calls Get.find. The returned instance is unused here.
    if (!Get.isRegistered<AdminAppBarControllers>()) {
      Get.put(AdminAppBarControllers(), permanent: true);
    }

    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.laoBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            // 8% black — the soft-shadow cap. (Was 0x40 = 25%, a hard shadow.)
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: _AdminAppBarBody(),
        ),
      ),
    );
  }
}

/// Body of [AdminAppBar] — split out so the outer gradient + safe area stay
/// trivially `const`.
class _AdminAppBarBody extends StatelessWidget {
  const _AdminAppBarBody();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminAppBarControllers>();
    return Row(
      children: [
        Expanded(child: _SemesterChip(controller: controller)),
        const _NotificationBubble(),
      ],
    );
  }
}

/// Pill on the left side of the app bar showing the active semester. While
/// the controller is loading it falls back to a small spinner pill.
class _SemesterChip extends StatelessWidget {
  /// Source of the reactive semester string + loading flag.
  final AdminAppBarControllers controller;

  const _SemesterChip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.semesterLoading.value) return const _SemesterLoadingChip();
      return _SemesterReadyChip(label: controller.semester.value);
    });
  }
}

/// Spinner pill rendered while the active semester is being fetched.
class _SemesterLoadingChip extends StatelessWidget {
  const _SemesterLoadingChip();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppColors.chipRadius),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'ກຳລັງໂຫຼດ...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolved semester pill rendered once the controller has data.
class _SemesterReadyChip extends StatelessWidget {
  /// Display label (typically `<code> (<year>)`).
  final String label;

  const _SemesterReadyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppColors.chipRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular notification-bell button with a live unread badge. Taps route
/// to `/admin-noti` via GetX, then refresh the count on return so rows read
/// there clear the dot immediately.
///
/// The count comes from the shared [notiBadge] (the per-user `/user-noti`
/// inbox) — the same source the admin notification screen marks read — so the
/// badge stays in sync instead of lingering after a read.
class _NotificationBubble extends StatelessWidget {
  const _NotificationBubble();

  @override
  Widget build(BuildContext context) {
    final badge = notiBadge;
    return Obx(() {
      final count = badge.unreadCount.value;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            await Get.toNamed('/admin-noti');
            await badge.fetchUnread();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Badge(
              isLabelVisible: count > 0,
              label: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppColors.rejectRed,
              offset: const Offset(6, -6),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      );
    });
  }
}
