import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:frontend/app/modules/data/models/notification_model.dart';
import 'package:frontend/app/widgets/widget.dart';

/// Full-screen reader for a single notification — the "posted notice" detail.
///
/// Shared by all three role inboxes (student / teacher / admin); they hand it
/// the [NotificationModel] already loaded in the list, so there is no fetch
/// and therefore no loading/error state for the notice itself. Attachment
/// loading, broken images, and file-open failures are handled inside
/// [NotificationAttachments].
///
/// The screen renders the notification as one white "notice sheet" floating on
/// the mist-gray board: a type/urgency badge, the full title, when it was
/// posted, the complete (selectable) message, and any photo/file attachments
/// at a detail-sized preview.
class NotificationDetailView extends StatelessWidget {
  /// The notification to display in full.
  final NotificationModel notification;

  /// When the signed-in user received this notice (the inbox row's timestamp).
  /// Falls back to [NotificationModel.createdAt] when null.
  final DateTime? receivedAt;

  const NotificationDetailView({
    super.key,
    required this.notification,
    this.receivedAt,
  });

  /// Effective timestamp: the inbox row's time, else the notification's own.
  DateTime? get _postedAt => receivedAt ?? notification.createdAt;

  String get _title {
    final t = notification.title.trim();
    return t.isEmpty ? 'ແຈ້ງເຕືອນ' : t;
  }

  @override
  Widget build(BuildContext context) {
    final files = notification.files;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 20),
          onPressed: Get.back,
        ),
        title: const Text(
          'ລາຍລະອຽດແຈ້ງເຕືອນ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.m,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: AppSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeBadge(kind: _NotiKind.of(notification.type)),
                const SizedBox(height: AppSpacing.m),
                Text(
                  _title,
                  style: AppTypography.title.copyWith(height: 1.25),
                ),
                const SizedBox(height: AppSpacing.s),
                _PostedMeta(postedAt: _postedAt),
                const _NoticeFold(),
                _MessageBody(message: notification.message),
                if (files.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.l),
                  _AttachmentsHeader(count: files.length),
                  const SizedBox(height: AppSpacing.s + 4),
                  NotificationAttachments(files: files, imageHeight: 200),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The three notification flavors the inbox distinguishes, derived from the
/// freeform backend `type` exactly the way the list controllers derive their
/// category — so the badge here matches the card the user tapped.
enum _NotiKind {
  urgent,
  booking,
  academic;

  static _NotiKind of(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t == 'urgent') return _NotiKind.urgent;
    if (t.contains('booking')) return _NotiKind.booking;
    return _NotiKind.academic;
  }

  Color get color => switch (this) {
        _NotiKind.urgent => AppColors.danger,
        _NotiKind.booking => AppColors.success,
        _NotiKind.academic => AppColors.info,
      };

  // Icons mirror the inbox cards the user tapped (urgent card warns; the
  // recent card uses stars for academic and a turned-in slip for booking) so
  // the detail reads as the same notice, expanded.
  IconData get icon => switch (this) {
        _NotiKind.urgent => Icons.warning_amber_rounded,
        _NotiKind.booking => Icons.assignment_turned_in_outlined,
        _NotiKind.academic => Icons.stars_outlined,
      };

  String get label => switch (this) {
        _NotiKind.urgent => 'ດ່ວນ',
        _NotiKind.booking => 'ຈອງຫ້ອງ',
        _NotiKind.academic => 'ການສຶກສາ',
      };
}

/// Tinted pill naming the notification's flavor — icon + label in the flavor
/// color over a 10% tint of the same hue (the app's standard tag treatment,
/// AA-safe for all three status colors on white).
class _TypeBadge extends StatelessWidget {
  final _NotiKind kind;

  const _TypeBadge({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: kind.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppColors.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kind.icon, size: 16, color: kind.color),
          const SizedBox(width: 6),
          Text(
            kind.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kind.color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Posted on" line: clock glyph + absolute date/time, with a relative hint
/// ("2 ຊົ່ວໂມງກ່ອນ") appended for recent notices.
class _PostedMeta extends StatelessWidget {
  final DateTime? postedAt;

  const _PostedMeta({required this.postedAt});

  @override
  Widget build(BuildContext context) {
    final text = _format(postedAt);
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.schedule_rounded,
              size: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTypography.caption)),
      ],
    );
  }

  /// Absolute timestamp plus, when recent, a Lao relative suffix.
  static String _format(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final abs = DateFormat('dd/MM/yyyy · HH:mm').format(local);
    final rel = _relative(local);
    return rel.isEmpty ? abs : '$abs · $rel';
  }

  static String _relative(DateTime local) {
    final diff = DateTime.now().difference(local);
    if (diff.isNegative) return '';
    if (diff.inMinutes < 1) return 'ຫາກໍ່ນີ້';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ນາທີກ່ອນ';
    if (diff.inHours < 24) return '${diff.inHours} ຊົ່ວໂມງກ່ອນ';
    if (diff.inDays < 7) return '${diff.inDays} ວັນກ່ອນ';
    return '';
  }
}

/// The hairline "fold" between the notice header and its body.
class _NoticeFold extends StatelessWidget {
  const _NoticeFold();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppSpacing.l + AppSpacing.l,
      thickness: 1,
      color: Colors.grey.shade200,
    );
  }
}

/// The full notice text, selectable so users can copy details (room codes,
/// dates, links). Falls back to a muted placeholder when the body is empty so
/// the sheet never shows a blank gap.
class _MessageBody extends StatelessWidget {
  final String message;

  const _MessageBody({required this.message});

  @override
  Widget build(BuildContext context) {
    final body = message.trim();
    if (body.isEmpty) {
      return Text(
        'ບໍ່ມີເນື້ອຫາເພີ່ມເຕີມ.',
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return SelectableText(
      body,
      style: AppTypography.body.copyWith(height: 1.6),
    );
  }
}

/// Section label above the attachment list: paperclip + "ໄຟລ໌ແນບ" + count.
class _AttachmentsHeader extends StatelessWidget {
  final int count;

  const _AttachmentsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.attach_file_rounded,
            size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('ໄຟລ໌ແນບ', style: AppTypography.label),
        const SizedBox(width: 6),
        Text('($count)', style: AppTypography.caption),
      ],
    );
  }
}
