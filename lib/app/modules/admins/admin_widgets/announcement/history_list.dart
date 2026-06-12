import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/notification_model.dart';
import '../../announcement/controllers/announcement_controller.dart';
import 'history_tile.dart';

/// Loading / error / empty / list switch + infinite-scroll pagination.
class HistoryList extends StatelessWidget {
  /// Source of reactive list state.
  final AnnouncementController controller;

  const HistoryList({super.key, required this.controller});

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
            return HistoryTile(
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

/// Internal sentinel inserted between day-grouped notifications by the list
/// builder. Carries the human-readable day label.
class _DateHeaderEntry {
  /// Caption for the day separator (e.g. "ມື້ນີ້").
  final String label;

  const _DateHeaderEntry(this.label);
}
