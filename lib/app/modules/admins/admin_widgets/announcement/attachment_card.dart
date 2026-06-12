import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/media_url.dart';
import '../../../../widgets/widget.dart';
import '../../announcement/controllers/announcement_controller.dart';
import 'announcement_form_blocks.dart';

/// Attachment section — an externally-hosted image URL (with live preview) and
/// an uploadable file. The photo is referenced by URL only (no upload); the
/// file is staged here and uploaded at send time by the controller.
class AttachmentCard extends StatelessWidget {
  /// Source of reactive attachment state.
  final AnnouncementController controller;

  const AttachmentCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnnSectionCard(
      icon: Icons.attachment_rounded,
      title: 'ໄຟລ໌ແນບ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final count = controller.pickedFiles.length;
            return AnnFieldLabel(
              count == 0
                  ? 'ໄຟລ໌ (PDF, ຮູບ, ເອກະສານ)'
                  : 'ໄຟລ໌ແນບ ($count/${AnnouncementController.maxUploadFiles})',
            );
          }),
          const SizedBox(height: 6),
          Obx(() {
            final files = controller.pickedFiles;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < files.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PickedFileRow(
                      file: files[i],
                      onRemove: () => controller.removePickedFileAt(i),
                    ),
                  ),
                if (files.length < AnnouncementController.maxUploadFiles)
                  _PickFileButton(
                    onTap: controller.pickAttachment,
                    label: files.isEmpty ? 'ເລືອກໄຟລ໌ແນບ' : 'ເພີ່ມໄຟລ໌',
                  ),
              ],
            );
          }),
          const SizedBox(height: 6),
          Text(
            'ຮອງຮັບ PDF, Word, Excel, PowerPoint, ຮູບ — ສູງສຸດ 10 MB/ໄຟລ໌, '
            '${AnnouncementController.maxUploadFiles} ໄຟລ໌',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width "pick / add files" button.
class _PickFileButton extends StatelessWidget {
  /// Tap handler — opens the multi-select system file picker.
  final VoidCallback onTap;

  /// Button caption (e.g. "ເລືອກໄຟລ໌ແນບ" first, "ເພີ່ມໄຟລ໌" afterwards).
  final String label;

  const _PickFileButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.laoBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.laoBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.upload_file_rounded,
              size: 20,
              color: AppColors.laoBlue,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.laoBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Staged-file row — icon, name, size, and a remove action.
class _PickedFileRow extends StatelessWidget {
  /// The picked-but-not-yet-uploaded file.
  final PlatformFile file;

  /// Removes this staged file.
  final VoidCallback onRemove;

  const _PickedFileRow({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isImage = isImagePath(file.name);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.borderApproved.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderApproved.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.borderApproved.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
              size: 20,
              color: AppColors.borderApproved,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatBytes(file.size),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: Colors.grey.shade600,
            ),
            tooltip: 'ລຶບ',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Human-readable byte size (B / KB / MB) for the staged file.
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
