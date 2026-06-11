import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/notification_model.dart';
import '../../announcement/controllers/announcement_controller.dart';

/// Single history row — icon + title + relative time + message + type chip +
/// edit/resend/delete action buttons.
class HistoryTile extends StatelessWidget {
  /// The notification model rendered by this row.
  final NotificationModel noti;

  /// Source of mutations (edit / resend / delete callbacks).
  final AnnouncementController controller;

  const HistoryTile({super.key, required this.noti, required this.controller});

  bool get _hasAttachment => noti.files.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleRow(title: noti.title, createdAt: noti.createdAt),
          const SizedBox(height: 8),
          Text(
            noti.message,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (_hasAttachment) ...[
            const SizedBox(height: 10),
            NotificationAttachments(
              files: noti.files,
              imageHeight: 140,
            ),
          ],
          if (noti.type != null && noti.type!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _TypeTag(type: noti.type!),
          ],
          const Divider(height: 18),
          _ActionRow(noti: noti, controller: controller),
        ],
      ),
    );
  }
}

/// Title row inside [HistoryTile] — icon bubble + title + relative time.
class _TitleRow extends StatelessWidget {
  /// Notification title.
  final String title;

  /// Notification timestamp (may be `null`).
  final DateTime? createdAt;

  const _TitleRow({required this.title, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    final relative = _relativeTime(createdAt);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.laoBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.laoBlue,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (relative.isNotEmpty)
                Text(
                  relative,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _relativeTime(DateTime? createdAt) {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} ນາທີກ່ອນ';
    if (diff.inHours < 24) return '${diff.inHours} ຊົ່ວໂມງກ່ອນ';
    return '${diff.inDays} ວັນກ່ອນ';
  }
}

/// Small indigo type tag rendered under the message.
class _TypeTag extends StatelessWidget {
  /// Type label.
  final String type;

  const _TypeTag({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.laoBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.laoBlue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Right-aligned row of three [_HistoryActionButton]s — edit / resend /
/// delete.
class _ActionRow extends StatelessWidget {
  /// Target notification.
  final NotificationModel noti;

  /// Source of the three mutation callbacks.
  final AnnouncementController controller;

  const _ActionRow({required this.noti, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _HistoryActionButton(
          icon: Icons.edit_rounded,
          label: 'ແກ້ໄຂ',
          color: AppColors.laoBlue,
          onTap: () => controller.editNotification(noti),
        ),
        const SizedBox(width: 8),
        _HistoryActionButton(
          icon: Icons.replay_rounded,
          label: 'ສົ່ງຊ້ຳ',
          color: AppColors.borderApproved,
          onTap: () => controller.resendNotification(noti),
        ),
        const SizedBox(width: 8),
        _HistoryActionButton(
          icon: Icons.delete_outline_rounded,
          label: 'ລຶບ',
          color: AppColors.rejectRed,
          onTap: () => controller.deleteNotification(noti.notiId),
        ),
      ],
    );
  }
}

/// Color-tinted pill action button used in the row footer.
class _HistoryActionButton extends StatelessWidget {
  /// Glyph.
  final IconData icon;

  /// Caption.
  final String label;

  /// Tint applied to the glyph, text, and tinted background.
  final Color color;

  /// Tap handler.
  final VoidCallback onTap;

  const _HistoryActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
