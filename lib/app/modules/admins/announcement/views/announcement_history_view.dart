import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';
import '../../../data/models/notification_model.dart';
import '../controllers/announcement_controller.dart';

/// Full-screen history page for sent announcements.
///
/// Provides search, sort, type-filter, infinite scroll, and per-row edit /
/// resend / delete actions. State and mutations live in
/// [AnnouncementController]; this view is composition only.
class AnnouncementHistoryView extends StatelessWidget {
  const AnnouncementHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AnnouncementController>();
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AssetImages.dashboardBg),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          _HistoryTopBar(controller: controller),
          _HistorySearchBar(controller: controller),
          _HistorySortFilterRow(controller: controller),
          Expanded(child: _HistoryList(controller: controller)),
        ],
      ),
    );
  }
}

/// Title bar with back button (closes history) and a live row counter.
class _HistoryTopBar extends StatelessWidget {
  /// Source of reactive state.
  final AnnouncementController controller;

  const _HistoryTopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 48, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.closeHistory,
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'ປະຫວັດການແຈ້ງເຕືອນ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Obx(
            () => Text(
              '${controller.filteredNotifications.length} ລາຍການ',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps the shared [AppSearchBar] and binds it to the history search state.
class _HistorySearchBar extends StatelessWidget {
  /// Source of reactive search state.
  final AnnouncementController controller;

  const _HistorySearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 4),
      child: Obx(
        () => AppSearchBar(
          hint: 'ຄົ້ນຫາ...',
          controller: controller.searchHistoryCtrl,
          onChanged: controller.onHistorySearchChanged,
          currentQuery: controller.historySearch.value,
          onClear: () {
            controller.searchHistoryCtrl.clear();
            controller.onHistorySearchChanged('');
          },
        ),
      ),
    );
  }
}

/// Scrolling row of sort chips followed by a vertical divider and type
/// filter chips.
class _HistorySortFilterRow extends StatelessWidget {
  /// Source of reactive sort / filter state.
  final AnnouncementController controller;

  const _HistorySortFilterRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: [
              _SortChip(
                label: 'ໃໝ່ສຸດ',
                mode: AnnouncementSortMode.newest,
                controller: controller,
              ),
              const SizedBox(width: 6),
              _SortChip(
                label: 'ເກົ່າສຸດ',
                mode: AnnouncementSortMode.oldest,
                controller: controller,
              ),
              const SizedBox(width: 6),
              _SortChip(
                label: 'ຫົວຂໍ້ A-Z',
                mode: AnnouncementSortMode.titleAZ,
                controller: controller,
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              const SizedBox(width: 12),
              _TypeFilterChip(
                label: 'ທັງໝົດ',
                typeValue: '',
                controller: controller,
              ),
              const SizedBox(width: 6),
              for (final t in controller.uniqueTypes.take(4))
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _TypeFilterChip(
                    label: t.length > 15 ? '${t.substring(0, 15)}…' : t,
                    typeValue: t,
                    controller: controller,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sort chip with a leading icon. Tints indigo when its [mode] is active.
class _SortChip extends StatelessWidget {
  /// Caption.
  final String label;

  /// Sort mode this chip selects.
  final int mode;

  /// Source of reactive sort state.
  final AnnouncementController controller;

  const _SortChip({
    required this.label,
    required this.mode,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final selected = controller.historySortMode.value == mode;
    return GestureDetector(
      onTap: () => controller.setHistorySortMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.laoBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.laoBlue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort_rounded,
              size: 14,
              color: selected ? Colors.white : Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Type filter chip. Tints green when its [typeValue] is active.
class _TypeFilterChip extends StatelessWidget {
  /// Caption.
  final String label;

  /// Type value this chip selects; empty string means "all".
  final String typeValue;

  /// Source of reactive filter state.
  final AnnouncementController controller;

  const _TypeFilterChip({
    required this.label,
    required this.typeValue,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final selected = controller.historyFilterType.value == typeValue;
    return GestureDetector(
      onTap: () => controller.setHistoryFilterType(typeValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.borderApproved.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.borderApproved : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.borderApproved
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Loading / error / empty / list switch + infinite-scroll pagination.
class _HistoryList extends StatelessWidget {
  /// Source of reactive list state.
  final AnnouncementController controller;

  const _HistoryList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const AppLoading.historyList();
      if (controller.historyError.value.isNotEmpty) {
        return AppErrorState(
          message: controller.historyError.value,
          onRetry: controller.refreshData,
        );
      }
      if (controller.filteredNotifications.isEmpty) {
        return const AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'ບໍ່ພົບຜົນລັບ',
          subtitle: 'ລອງປ່ຽນຄຳຄົ້ນຫາ ຫຼື ຕົວກອງອື່ນ',
        );
      }

      final grouped = _groupByDay(controller.filteredNotifications);
      return NotificationListener<ScrollNotification>(
        onNotification: (sn) {
          if (sn.metrics.pixels >= sn.metrics.maxScrollExtent - 200) {
            controller.loadMoreNotifications();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          itemCount: grouped.length + 1,
          itemBuilder: (_, i) {
            if (i == grouped.length) {
              return _HistoryListFooter(controller: controller);
            }
            final item = grouped[i];
            if (item is _DateHeaderEntry) {
              return _HistoryDateHeader(label: item.label);
            }
            return _HistoryTile(
              noti: item as NotificationModel,
              controller: controller,
            );
          },
        ),
      );
    });
  }

  /// Insert a [_DateHeaderEntry] before each new day's group of notifications.
  /// Items without a `createdAt` are bucketed under a separate header.
  List<Object> _groupByDay(List<NotificationModel> items) {
    final out = <Object>[];
    String? lastKey;
    for (final n in items) {
      final created = n.createdAt;
      final key = _dayKey(created);
      if (key != lastKey) {
        out.add(_DateHeaderEntry(_dayLabel(created)));
        lastKey = key;
      }
      out.add(n);
    }
    return out;
  }

  String _dayKey(DateTime? dt) {
    if (dt == null) return 'unknown';
    final local = dt.toLocal();
    return '${local.year}-${local.month}-${local.day}';
  }

  String _dayLabel(DateTime? dt) {
    if (dt == null) return 'ບໍ່ມີວັນທີ';
    final now = DateTime.now();
    final local = dt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'ມື້ນີ້';
    if (diff == 1) return 'ມື້ວານ';
    if (diff < 7) return '$diff ວັນກ່ອນ';
    return '${local.day}/${local.month}/${local.year}';
  }
}

/// Pagination footer — spinner while loading more, "end of list" hint when
/// exhausted, blank otherwise.
class _HistoryListFooter extends StatelessWidget {
  /// Source of reactive pagination state.
  final AnnouncementController controller;

  const _HistoryListFooter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingMore.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.laoBlue,
              ),
            ),
          ),
        );
      }
      if (!controller.hasMore.value &&
          controller.filteredNotifications.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              'ສິ້ນສຸດລາຍການ',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}

/// Day separator inside the history list.
class _HistoryDateHeader extends StatelessWidget {
  /// Caption — typically "ມື້ນີ້" / "ມື້ວານ" / "N ວັນກ່ອນ" / a literal date.
  final String label;

  const _HistoryDateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Single history row — icon + title + relative time + message + type chip +
/// edit/resend/delete action buttons.
class _HistoryTile extends StatelessWidget {
  /// The notification model rendered by this row.
  final NotificationModel noti;

  /// Source of mutations (edit / resend / delete callbacks).
  final AnnouncementController controller;

  const _HistoryTile({required this.noti, required this.controller});

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

/// Title row inside [_HistoryTile] — icon bubble + title + relative time.
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

/// Right-aligned row of three [_HistoryActionButton]s — edit / resend / delete.
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

/// Internal sentinel inserted between day-grouped notifications by the list
/// builder. Carries the human-readable day label.
class _DateHeaderEntry {
  /// Caption for the day separator (e.g. "ມື້ນີ້").
  final String label;

  const _DateHeaderEntry(this.label);
}
