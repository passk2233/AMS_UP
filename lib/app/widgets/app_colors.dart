import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary palette ──────────────────────────────────────────────────
  static const Color primary = Color(0xff40b4cd);
  static const Color primaryDark = Color(0xFF3A3BBF);
  static const Color laoBlue = Color(0xFF4C4DDC);
  static const Color approveBlue = Color(0xFF4C4DDC); // alias for laoBlue

  // ── Accent / action colors ───────────────────────────────────────────
  static const Color accentYellow = Color(0xFFF5C842);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color rejectRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF27AE60);

  // ── Stats / feature accent ───────────────────────────────────────────
  static const Color statsBlue = Color(0xFF4A68FF);
  static const Color bookingBlue = Color(0xFF4A80F0);

  // ── Status border colors ─────────────────────────────────────────────
  static const Color borderPending = Color(0xFFF59E0B);
  static const Color borderApproved = Color(0xFF10B981);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);

  // ── Surface / background ─────────────────────────────────────────────
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF5F7FA);
  static const Color inputFill = Color(0xFFF5F7FA);

  // ── Design tokens (spacing & radius) ─────────────────────────────────
  static const double cardRadius = 14.0;
  static const double buttonRadius = 12.0;
  static const double chipRadius = 20.0;
  static const double minTouchTarget = 48.0;
}
