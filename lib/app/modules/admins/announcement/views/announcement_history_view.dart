import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../admin_widgets/announcement/history_header.dart';
import '../../admin_widgets/announcement/history_list.dart';
import '../../admin_widgets/announcement/history_sort_filter_row.dart';
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
          HistoryTopBar(controller: controller),
          HistorySearchBar(controller: controller),
          HistorySortFilterRow(controller: controller),
          Expanded(child: HistoryList(controller: controller)),
        ],
      ),
    );
  }
}
