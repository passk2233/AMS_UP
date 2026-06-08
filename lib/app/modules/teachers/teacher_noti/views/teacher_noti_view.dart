import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/notification_file_model.dart';
import '../../../student/student_noti/views/booking_detail.dart';
import '../../../student/student_noti/views/grade_noti.dart';
import '../controllers/teacher_noti_controller.dart';

/// Teacher notification center.
///
/// Displays the user's notifications filtered by category (all / academic /
/// room booking) and renders an urgent-styled card for `Urgent` entries.
/// Tapping any item optimistically marks it read and routes to the relevant
/// detail screen.
class TeacherNotiView extends GetView<TeacherNotiController> {
  const TeacherNotiView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TeacherNotiController>()) {
      Get.put(TeacherNotiController());
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 20),
          onPressed: Get.back,
        ),
        title: const Text(
          'ສູນແຈ້ງເຕືອນ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _NotiFilterRow(controller: controller),
          Expanded(child: _NotiBody(controller: controller)),
        ],
      ),
    );
  }
}

/// Category filter chips (all / academic / booking) bound to
/// [TeacherNotiController.selectedFilterIndex].
class _NotiFilterRow extends StatelessWidget {
  /// Source of reactive selection state.
  final TeacherNotiController controller;

  const _NotiFilterRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppFilterChipRow(
        items: const [
          AppFilterChip(label: 'ທັງໝົດ'),
          AppFilterChip(label: 'ການສຶກສາ'),
          AppFilterChip(label: 'ຈອງຫ້ອງ'),
        ],
        selectedIndex: controller.selectedFilterIndex.value,
        onSelected: (i) => controller.selectedFilterIndex.value = i,
      ),
    );
  }
}

/// Loading / error / empty / list switch for the notification body.
class _NotiBody extends StatelessWidget {
  /// Source of reactive state.
  final TeacherNotiController controller;

  const _NotiBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const AppLoading.notifications();
      if (controller.errorMessage.value.isNotEmpty) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.fetchNotifications,
        );
      }
      final list = controller.filteredNotifications;
      if (list.isEmpty) {
        return const AppEmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'ບໍ່ມີການແຈ້ງເຕືອນ',
        );
      }
      return _NotiList(items: list, controller: controller);
    });
  }
}

/// Scrolling list of notification rows.
class _NotiList extends StatelessWidget {
  /// View-model maps from [TeacherNotiController.filteredNotifications].
  final List<Map<String, dynamic>> items;

  /// Used for the `markAsRead` mutation on tap.
  final TeacherNotiController controller;

  const _NotiList({required this.items, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: items.length,
      itemBuilder: (context, index) => _NotificationListItem(
        item: items[index],
        controller: controller,
      ),
    );
  }
}

/// Picks the right card for a single notification (urgent vs normal) and
/// wires the tap handler.
class _NotificationListItem extends StatelessWidget {
  /// View-model map for this notification.
  final Map<String, dynamic> item;

  /// Used for `markAsRead`.
  final TeacherNotiController controller;

  const _NotificationListItem({
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final id = item['id'] as int?;
    final unread = item['unread'] == true;

    if (item['type'] == 'Urgent') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ແຈ້ງເຕືອນດ່ວນ',
              style: TextStyle(
                color: AppColors.rejectRed,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            _UrgentNotificationCard(
              title: item['title'] as String,
              sub: item['sub'] as String,
              status: item['status'] as String,
              time: item['time'] as String,
              unread: unread,
              onTap: () {
                if (id != null) controller.markAsRead(id);
                Get.to(() => const GradeNotiView());
              },
            ),
          ],
        ),
      );
    }

    return _RecentNotificationCard(
      icon: item['category'] == 'Academic'
          ? Icons.stars_outlined
          : Icons.assignment_turned_in_outlined,
      iconColor: item['category'] == 'Academic'
          ? AppColors.statsBlue
          : AppColors.borderApproved,
      title: item['title'] as String,
      desc: item['desc'] as String,
      time: item['time'] as String,
      unread: unread,
      files: item['files'] as List<NotificationFileModel>?,
      onTap: () {
        if (id != null) controller.markAsRead(id);
        if (item['title'] == 'Grade Released') {
          Get.to(() => const GradeNotiView());
        } else if (item['title'] == 'Booking Confirmed') {
          Get.to(() => const BookingDetailView());
        }
      },
    );
  }
}

/// 8×8 red dot rendered next to the title of an unread notification.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 6),
      child: SizedBox(
        width: 8,
        height: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.rejectRed,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Red-tinted urgent notification card with title, subtitle, status pill,
/// and a timestamp.
class _UrgentNotificationCard extends StatelessWidget {
  /// Headline text.
  final String title;

  /// Body text.
  final String sub;

  /// Status word ("Urgent") rendered under the body.
  final String status;

  /// Right-aligned timestamp.
  final String time;

  /// When true, prepends an [_UnreadDot] before the title.
  final bool unread;

  /// Tap handler.
  final VoidCallback? onTap;

  const _UrgentNotificationCard({
    required this.title,
    required this.sub,
    required this.status,
    required this.time,
    this.unread = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.rejectRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
            border:
                Border.all(color: AppColors.rejectRed.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.rejectRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.rejectRed,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NotiTitleRow(
                      title: title,
                      time: time,
                      unread: unread,
                      timeColor: AppColors.rejectRed,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      status,
                      style: const TextStyle(
                        color: AppColors.rejectRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White-surface notification row with a circular tinted icon and a body
/// description.
class _RecentNotificationCard extends StatelessWidget {
  /// Leading glyph.
  final IconData icon;

  /// Tint for the icon + its bubble.
  final Color iconColor;

  /// Headline.
  final String title;

  /// Body description.
  final String desc;

  /// Right-aligned timestamp.
  final String time;

  /// When true, prepends an [_UnreadDot] before the title.
  final bool unread;

  /// Optional uploaded attachments.
  final List<NotificationFileModel>? files;

  /// Tap handler.
  final VoidCallback? onTap;

  const _RecentNotificationCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
    required this.time,
    this.unread = false,
    this.files,
    this.onTap,
  });

  bool get _hasAttachment => files?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotiTitleRow(title: title, time: time, unread: unread),
                const SizedBox(height: 5),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (_hasAttachment) ...[
                  const SizedBox(height: 10),
                  NotificationAttachments(
                    files: files ?? const [],
                    imageHeight: 120,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Title row shared by both notification cards — optional unread dot, the
/// title text, and a right-aligned timestamp.
class _NotiTitleRow extends StatelessWidget {
  /// Headline text.
  final String title;

  /// Right-aligned timestamp.
  final String time;

  /// When true, prepends an [_UnreadDot].
  final bool unread;

  /// Tint applied to the timestamp text.
  final Color timeColor;

  const _NotiTitleRow({
    required this.title,
    required this.time,
    required this.unread,
    this.timeColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              if (unread) const _UnreadDot(),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(time, style: TextStyle(color: timeColor, fontSize: 12)),
      ],
    );
  }
}
