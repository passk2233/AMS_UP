import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../announcement/controllers/announcement_controller.dart';
import 'announcement_form_blocks.dart';

/// Card containing the title + message fields.
class ComposeCard extends StatelessWidget {
  /// Source of reactive state.
  final AnnouncementController controller;

  const ComposeCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnnSectionCard(
      icon: Icons.edit_note_rounded,
      title: 'ຂຽນຂໍ້ຄວາມ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnnFieldLabel('ຫົວຂໍ້'),
          const SizedBox(height: 6),
          AnnFilledTextField(
            controller: controller.titleCtrl,
            hint: 'ຕົວຢ່າງ: ແຈ້ງປ່ຽນຕາຕະລາງສອບເສັງ',
          ),
          const SizedBox(height: 14),
          const AnnFieldLabel('ເນື້ອຫາ'),
          const SizedBox(height: 6),
          AnnFilledTextField(
            controller: controller.messageCtrl,
            hint: 'ພິມລາຍລະອຽດການແຈ້ງເຕືອນ...',
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}

/// Primary "Send announcement" button.
class SendAnnouncementButton extends StatelessWidget {
  /// Source of reactive sending state.
  final AnnouncementController controller;

  const SendAnnouncementButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final uploading = controller.isUploading.value;
      final sending = controller.isSending.value;
      return AppPrimaryButton(
        label: uploading
            ? 'ກຳລັງອັບໂຫຼດໄຟລ໌...'
            : (sending ? 'ກຳລັງສົ່ງ...' : 'ສົ່ງການແຈ້ງເຕືອນ'),
        icon: Icons.send_rounded,
        isLoading: sending || uploading,
        onPressed: controller.sendNotification,
        backgroundColor: AppColors.laoBlue,
      );
    });
  }
}
