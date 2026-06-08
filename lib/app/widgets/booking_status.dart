import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Single source of truth for a booking status' color + Lao label.
///
/// Shared by the admin [BookingCard] and the student / teacher booking lists
/// so a booking never reads one color or word in one place and a different one
/// elsewhere. [status] is the backend enum string
/// (`pending` / `approved` / `rejected` / `cancelled`), matched
/// case-insensitively; anything unrecognized falls back to pending.
///
/// [color] comes from the closed status set only (amber pending, emerald
/// approved, red rejected, slate cancelled) — never a decorative hue.
/// [onColor] is the AA-safe foreground when [color] is used as a solid fill:
/// white on emerald/red/slate, dark ink on amber (white on amber is 2.15:1).
class BookingStatusStyle {
  /// Semantic color from the closed status vocabulary.
  final Color color;

  /// Legible foreground for text/icons placed on a solid [color] fill.
  final Color onColor;

  /// Lao label shown to users (the backend enum is never surfaced raw).
  final String labelLao;

  const BookingStatusStyle({
    required this.color,
    required this.onColor,
    required this.labelLao,
  });

  static BookingStatusStyle of(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const BookingStatusStyle(
          color: AppColors.success,
          onColor: Colors.white,
          labelLao: 'ອະນຸມັດແລ້ວ',
        );
      case 'rejected':
        return const BookingStatusStyle(
          color: AppColors.danger,
          onColor: Colors.white,
          labelLao: 'ປະຕິເສດ',
        );
      case 'cancelled':
      case 'canceled':
        return const BookingStatusStyle(
          color: AppColors.textSecondary,
          onColor: Colors.white,
          labelLao: 'ຍົກເລີກແລ້ວ',
        );
      case 'pending':
      default:
        return const BookingStatusStyle(
          color: AppColors.warning,
          onColor: AppColors.textPrimary,
          labelLao: 'ລໍຖ້າອະນຸມັດ',
        );
    }
  }
}
