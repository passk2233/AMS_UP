import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../announcement/controllers/announcement_controller.dart';

/// Title bar with back button (closes history) and a live row counter.
class HistoryTopBar extends StatelessWidget {
  /// Source of reactive state.
  final AnnouncementController controller;

  const HistoryTopBar({super.key, required this.controller});

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
class HistorySearchBar extends StatelessWidget {
  /// Source of reactive search state.
  final AnnouncementController controller;

  const HistorySearchBar({super.key, required this.controller});

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
