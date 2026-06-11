import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/data/models/notification_file_model.dart';
import '../modules/data/models/notification_model.dart';
import '../modules/student/student_noti/views/notification_detail.dart';
import 'app_colors.dart';
import 'app_shell.dart';
import 'notification_attachments.dart';

/// Picks the right card for a single notification (urgent vs normal) and
/// wires the tap handler.
///
/// Shared by the admin / teacher / student notification centers. [item] is
/// the view-model map produced by each role's noti controller; [onMarkRead]
/// receives the notification id so the caller can optimistically mark it
/// read before routing to [NotificationDetailView].
class NotificationListItem extends StatelessWidget {
  /// View-model map for this notification.
  final Map<String, dynamic> item;

  /// Optimistic mark-as-read mutation.
  final void Function(int id) onMarkRead;

  const NotificationListItem({
    super.key,
    required this.item,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final id = item['id'] as int?;
    final unread = item['unread'] == true;

    void openDetail() {
      if (id != null) onMarkRead(id);
      Get.to(() => NotificationDetailView(
            notification: item['model'] as NotificationModel,
            receivedAt: item['timestamp'] as DateTime?,
          ));
    }

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
            UrgentNotificationCard(
              title: item['title'] as String,
              sub: item['sub'] as String,
              status: item['status'] as String,
              time: item['time'] as String,
              unread: unread,
              onTap: openDetail,
            ),
          ],
        ),
      );
    }

    return RecentNotificationCard(
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
      onTap: openDetail,
    );
  }
}

/// Red-tinted urgent notification card with title, subtitle, status pill,
/// and a timestamp.
class UrgentNotificationCard extends StatelessWidget {
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

  const UrgentNotificationCard({
    super.key,
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
class RecentNotificationCard extends StatelessWidget {
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

  const RecentNotificationCard({
    super.key,
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
