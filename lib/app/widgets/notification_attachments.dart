import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modules/data/models/notification_file_model.dart';
import '../utilities/media_url.dart';
import 'app_colors.dart';
import 'app_dialogs.dart';

/// Renders a notification's uploaded [files] — images shown inline, other
/// types as a tappable row that opens the file in an external viewer.
///
/// Each [NotificationFileModel.path] is a server-relative `/uploads/...` path;
/// [resolveMediaUrl] turns it into a loadable URL. Renders nothing when
/// [files] is empty, so it is safe to drop into any notification card
/// unconditionally.
class NotificationAttachments extends StatelessWidget {
  /// Uploaded attachments to render.
  final List<NotificationFileModel> files;

  /// Max height of an inline image preview.
  final double imageHeight;

  const NotificationAttachments({
    super.key,
    required this.files,
    this.imageHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < files.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _AttachmentEntry(file: files[i], imageHeight: imageHeight),
        ],
      ],
    );
  }
}

/// One uploaded attachment — an inline image for image types, a tappable file
/// row otherwise.
class _AttachmentEntry extends StatelessWidget {
  final NotificationFileModel file;
  final double imageHeight;

  const _AttachmentEntry({required this.file, required this.imageHeight});

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(file.path);
    if (url == null) return const SizedBox.shrink();
    if (isImagePath(file.name) || isImagePath(file.path)) {
      return _AttachmentImage(url: url, height: imageHeight);
    }
    final name = file.name.isNotEmpty ? file.name : fileNameFromPath(file.path);
    return _AttachmentFileRow(url: url, name: name);
  }
}

/// Inline, rounded image preview. Tapping opens the full image externally;
/// includes loading and error fallbacks so it never shows a blank box.
class _AttachmentImage extends StatelessWidget {
  final String url;
  final double height;

  const _AttachmentImage({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openUrl(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: url,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            height: height,
            alignment: Alignment.center,
            color: AppColors.scaffoldBg,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.laoBlue,
              ),
            ),
          ),
          errorWidget: (_, _, _) => Container(
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  'ໂຫຼດຮູບບໍ່ໄດ້',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tappable attachment row — icon + file name + an "open externally" affordance.
class _AttachmentFileRow extends StatelessWidget {
  final String url;
  final String name;

  const _AttachmentFileRow({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final image = isImagePath(name);
    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.laoBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.laoBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.laoBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                image ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                size: 20,
                color: AppColors.laoBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name.isEmpty ? 'ໄຟລ໌ແນບ' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: AppColors.laoBlue,
            ),
          ],
        ),
      ),
    );
  }
}

/// Open [url] in an external viewer (browser / system handler). Surfaces a
/// dialog on failure rather than silently doing nothing.
Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // fall through to the error dialog
    }
  }
  AppDialogs.showError(
    title: 'ເປີດໄຟລ໌ບໍ່ໄດ້',
    message: 'ບໍ່ສາມາດເປີດໄຟລ໌ນີ້ໄດ້.',
  );
}
