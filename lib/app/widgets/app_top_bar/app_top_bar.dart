import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_colors.dart';
import '../noti_bell.dart';
import 'semester_controller.dart';

/// Gradient top bar shared across every role (admin / teacher / student).
///
/// Renders a [_SemesterChip] on the left and a [_NotificationBubble] on the
/// right. The semester is owned by the shared [SemesterController]; the unread
/// badge is owned by the shared [notiBadge]. The bar itself is purely
/// declarative — drop a `const AppTopBar(notiRoute: ...)` at the top of any
/// role's Scaffold body.
///
/// [notiRoute] is the one role-specific input: each role passes its own
/// notification center (e.g. `/admin-noti`, `/teacher-noti`, `/student-noti`)
/// so the bell routes to the right inbox while the rest of the bar stays
/// identical everywhere.
class AppTopBar extends StatelessWidget {
  /// Named route of this role's notification center, opened when the bell is
  /// tapped (e.g. `/student-noti`).
  final String notiRoute;

  const AppTopBar({super.key, required this.notiRoute});

  @override
  Widget build(BuildContext context) {
    // Side effect — ensure the shared semester controller is registered before
    // the chip below reads it. The returned instance is unused here.
    semesterController;

    return DecoratedBox(
      decoration: const BoxDecoration(
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Expanded(child: _SemesterChip()),
              _NotificationBubble(notiRoute: notiRoute),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill on the left side of the bar showing the active semester. While the
/// shared controller is loading it falls back to a small spinner pill.
class _SemesterChip extends StatelessWidget {
  const _SemesterChip();

  @override
  Widget build(BuildContext context) {
    final controller = semesterController;
    return Obx(() => controller.semesterLoading.value
        ? _loading()
        : _ready(controller.semester.value));
  }

  /// Spinner pill rendered while the active semester is being fetched.
  Widget _loading() {
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

  /// Resolved semester pill rendered once the controller has data.
  Widget _ready(String label) {
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

/// Circular notification-bell button with a live unread badge. Taps route to
/// [notiRoute] (the role's notification center) via GetX, then refresh the
/// count on return so rows read there clear the dot immediately.
///
/// The count comes from the shared [notiBadge] (the per-user `/user-noti`
/// inbox) — the same source every notification screen marks read — so the
/// badge stays in sync instead of lingering after a read.
class _NotificationBubble extends StatelessWidget {
  /// Named route opened on tap.
  final String notiRoute;

  const _NotificationBubble({required this.notiRoute});

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
            await Get.toNamed(notiRoute);
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
