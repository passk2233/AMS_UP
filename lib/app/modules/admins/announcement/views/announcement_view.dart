import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';
import '../../admin_widgets/announcement/attachment_card.dart';
import '../../admin_widgets/announcement/compose_card.dart';
import '../../admin_widgets/announcement/compose_header.dart';
import '../../admin_widgets/announcement/target_audience_card.dart';
import '../controllers/announcement_controller.dart';
import 'announcement_history_view.dart';

/// Announcement composer (the "Announcements" admin tab).
///
/// Toggles between the compose form and the [AnnouncementHistoryView] based
/// on [AnnouncementController.showHistory]. All form state lives in the
/// controller; this view is composition only.
class AnnouncementView extends GetView<AnnouncementController> {
  const AnnouncementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => controller.showHistory.value
            ? const AnnouncementHistoryView()
            : _ComposePage(controller: controller),
      ),
    );
  }
}

/// Composer page with header + compose card + target-audience card + send
/// button.
class _ComposePage extends StatelessWidget {
  /// Source of reactive state.
  final AnnouncementController controller;

  const _ComposePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AssetImages.dashboardBg),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          const AdminAppBar(),
          ComposeHeader(onHistory: controller.openHistory),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                children: [
                  ComposeCard(controller: controller),
                  const SizedBox(height: 14),
                  AttachmentCard(controller: controller),
                  const SizedBox(height: 14),
                  TargetAudienceCard(controller: controller),
                  const SizedBox(height: 14),
                  SendAnnouncementButton(controller: controller),
                  const SizedBox(height: AppSpacing.l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
