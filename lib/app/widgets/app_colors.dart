import 'package:flutter/material.dart';

/// Centralized design tokens for color and shape.
///
/// All UI surfaces must reference these tokens instead of literal colors or
/// radii so the palette can be swapped in one place. The class is
/// non-instantiable; access tokens via `AppColors.primary`, etc.
///
/// Token groups:
/// - Brand: [primary], [primaryDark], [laoBlue]
/// - Status: [accentGreen], [rejectRed], [borderPending], [borderApproved]
/// - Surface: [cardBg], [scaffoldBg], [inputFill]
/// - Text: [textPrimary], [textSecondary]
/// - Shape: [cardRadius], [buttonRadius], [chipRadius], [minTouchTarget]
class AppColors {
  AppColors._();

  // ── Primary palette ──────────────────────────────────────────────────
  /// Brand teal — primary action color.
  static const Color primary = Color(0xff40b4cd);

  /// Deeper navy variant used in app-bar gradients.
  static const Color primaryDark = Color(0xFF3A3BBF);

  /// Indigo accent used for in-progress / informational states.
  static const Color laoBlue = Color(0xFF4C4DDC);

  /// Alias of [laoBlue] kept for the admin booking-approve view.
  static const Color approveBlue = Color(0xFF4C4DDC);

  // ── Accent / action colors ───────────────────────────────────────────
  /// Highlight yellow used on hero banners.
  static const Color accentYellow = Color(0xFFF5C842);

  /// Generic success green.
  static const Color accentGreen = Color(0xFF4CAF50);

  /// Destructive / reject red.
  static const Color rejectRed = Color(0xFFE53935);

  /// Confirmation green for completed flows.
  static const Color successGreen = Color(0xFF27AE60);

  // ── Stats / feature accent ───────────────────────────────────────────
  /// Stats card / dashboard banner blue.
  static const Color statsBlue = Color(0xFF4A68FF);

  /// Booking-flow blue used on student booking surfaces.
  static const Color bookingBlue = Color(0xFF4A80F0);

  // ── Status border colors ─────────────────────────────────────────────
  /// Left-border color on a "pending" card.
  static const Color borderPending = Color(0xFFF59E0B);

  /// Left-border color on an "approved" card.
  static const Color borderApproved = Color(0xFF10B981);

  // ── Text ─────────────────────────────────────────────────────────────
  /// Near-black body text (never pure #000 on pure #FFF).
  static const Color textPrimary = Color(0xFF1A1A2E);

  /// Medium gray used for captions and secondary labels.
  static const Color textSecondary = Color(0xFF6B7280);

  // ── Surface / background ─────────────────────────────────────────────
  /// White surface used by [AppSurfaceCard].
  static const Color cardBg = Color(0xFFFFFFFF);

  /// App-wide very-light-gray scaffold background.
  static const Color scaffoldBg = Color(0xFFF5F7FA);

  /// Fill for text-field inputs.
  static const Color inputFill = Color(0xFFF5F7FA);

  // ── Design tokens (spacing & radius) ─────────────────────────────────
  /// Corner radius for cards and dialogs.
  static const double cardRadius = 14;

  /// Corner radius for buttons and small surfaces.
  static const double buttonRadius = 12;

  /// Corner radius for chips and pills.
  static const double chipRadius = 20;

  /// Minimum tappable height/width (WCAG 2.1 AA / Material guidance).
  static const double minTouchTarget = 48;
}
