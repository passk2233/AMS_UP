import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utilities/assets.dart';
import '../utilities/media_url.dart';
import 'app_colors.dart';

/// Circular profile photo for a teacher or student.
///
/// Loads [photo] — a stored `/uploads/...` path or an absolute URL — via
/// [resolveMediaUrl] and renders it cover-fit inside a circle. Whenever the
/// photo is missing, blank, or fails to load, it falls back to the bundled
/// [AssetImages.profilePlaceholder] so the avatar is never blank.
class AppAvatar extends StatelessWidget {
  /// Stored photo path/URL from the teacher/student record. Null/blank shows
  /// the placeholder.
  final String? photo;

  /// Circle radius; the rendered diameter is `radius * 2`.
  final double radius;

  /// Fill shown behind the image while it loads (and through any transparency).
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    required this.photo,
    this.radius = 35,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final bg = backgroundColor ?? AppColors.primary.withValues(alpha: 0.1);
    final url = resolveMediaUrl(photo);
    // Decode-time cap (≈3× the largest sensible DPR) so a full-resolution
    // source — the placeholder asset is multi-megapixel — is never decoded at
    // native size just to fill a small circle.
    final cacheSize = (diameter * 3).round();

    return ClipOval(
      child: Container(
        width: diameter,
        height: diameter,
        color: bg,
        child: url == null
            ? _placeholder(diameter, cacheSize)
            : CachedNetworkImage(
                imageUrl: url,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                memCacheWidth: cacheSize,
                memCacheHeight: cacheSize,
                placeholder: (_, _) => Center(
                  child: SizedBox(
                    width: radius * 0.5,
                    height: radius * 0.5,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                // No path, broken link, or 404 → the bundled silhouette.
                errorWidget: (_, _, _) => _placeholder(diameter, cacheSize),
              ),
      ),
    );
  }

  Widget _placeholder(double diameter, int cacheSize) {
    return Image.asset(
      AssetImages.profilePlaceholder,
      width: diameter,
      height: diameter,
      fit: BoxFit.cover,
      cacheWidth: cacheSize,
      cacheHeight: cacheSize,
    );
  }
}
