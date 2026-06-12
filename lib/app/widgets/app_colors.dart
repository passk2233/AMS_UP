import 'package:flutter/material.dart';

/// Centralized design tokens for color and shape.
///
/// All UI surfaces must reference these tokens instead of literal colors or
/// radii so the palette can be swapped in one place. The class is
/// non-instantiable; access tokens via `AppColors.primary`, etc.
///
/// ## Palette system (post-consolidation)
///
/// The palette is **teal-led with one support blue** and a closed status set:
/// - Brand:   [primary] (Faculty Teal accent) + [primaryFill] (darker on-fill
///   teal for white-on-fill controls). [identityNavy] is launch/icon only.
/// - Support: [info] (Info Blue) — the single secondary accent for
///   admin-context surfaces, info / in-progress state, notifications, data-viz.
/// - Status:  [success] (emerald), [warning] (amber), [danger] (red).
/// - Accent:  [accentYellow] (highlight gold, used sparingly on banners).
/// - Text:    [textPrimary], [textSecondary]
/// - Surface: [cardBg], [scaffoldBg], [inputFill]
/// - Shape:   [cardRadius], [buttonRadius], [chipRadius], [minTouchTarget]
///
/// The former four blues (`laoBlue` / `approveBlue` / `statsBlue` /
/// `bookingBlue`) and three greens (`borderApproved` / `successGreen` /
/// `accentGreen`) collapsed into [info] and [success]. Those names are kept as
/// deprecated aliases at the bottom of this class so existing call sites keep
/// compiling; prefer the canonical names in new code.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────
  /// Faculty Teal — the bright brand accent: focus, active nav, links, selected
  /// states, icon tints, and brand moments. If something means "act" or "you
  /// are here", it is this teal. White text does NOT sit directly on this tone
  /// (2.43:1) — for solid teal fills carrying white text use [primaryFill].
  static const Color primary = Color(0xff40b4cd);

  /// Faculty Teal (on-fill) — the darker teal used as the BACKGROUND of filled
  /// controls that carry white text/icons: primary buttons, FABs, filled
  /// confirm buttons, and the info toast. White-on clears AA at 4.70:1 where
  /// the bright [primary] gives only 2.43:1. Same hue as [primary]; reach for
  /// it only when white meets a solid teal fill, never for accents/borders.
  static const Color primaryFill = Color(0xff1f7e93);

  /// Identity Navy — the launch / app-icon color (see `pubspec.yaml`
  /// adaptive icon + native splash). Identity moments only; never an in-app
  /// body or surface color (that would tip toward the rejected "banking" look).
  static const Color identityNavy = Color(0xff14385d);

  // ── Secondary accent ─────────────────────────────────────────────────
  /// Info Blue — the single support blue. Admin-context accents (announcements,
  /// evaluations), info / in-progress state, notification highlights, and the
  /// data-viz mid band. Verified AA: white-on and on-white both 6.2:1.
  static const Color info = Color(0xff3257cc);

  // ── Status (closed semantic set) ─────────────────────────────────────
  /// Approved / success emerald. Carries white text and reads as legible green
  /// text/icon on white (AA 5.3:1). Darker than the former bright #10B981,
  /// which failed contrast (2.5:1) under white labels.
  static const Color success = Color(0xff067a59);

  /// Pending / warning amber. Pair with dark text on filled surfaces.
  static const Color warning = Color(0xfff59e0b);

  /// Rejected / destructive red. Reject buttons, field errors, delete actions,
  /// nav badges. Darkened from the former bright #E53935 (only 3.99:1) so it
  /// clears AA both as red text on white and as white text on a red fill
  /// (5.4:1) — the same reasoning that darkened [success]. The old value made
  /// small red text/labels and the white-on-red badge fail contrast.
  static const Color danger = Color(0xffc62828);

  /// Highlight gold — sparing use on hero banners / highlight chips only.
  /// Never as text on a white surface (fails contrast).
  static const Color accentYellow = Color(0xfff5c842);

  // ── Text ─────────────────────────────────────────────────────────────
  /// Near-black body text (never pure #000 on pure #FFF).
  static const Color textPrimary = Color(0xFF1A1A2E);

  /// Medium gray used for captions and secondary labels. Holds 4.5:1 on white
  /// and on [scaffoldBg]; do not lighten it further.
  static const Color textSecondary = Color(0xFF6B7280);

  // ── Surface / background ─────────────────────────────────────────────
  /// White surface used by `AppSurfaceCard`.
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

  // ── Legacy aliases ───────────────────────────────────────────────────
  // Kept so the existing call sites stay valid; every alias resolves to a
  // canonical token above. Prefer the canonical names in new code.

  /// @deprecated Use [info].
  static const Color laoBlue = info;

  /// @deprecated Use [info].
  static const Color approveBlue = info;

  /// @deprecated Use [info].
  static const Color statsBlue = info;

  /// @deprecated Use [info].
  static const Color bookingBlue = info;

  /// @deprecated Use [success].
  static const Color borderApproved = success;

  /// @deprecated Use [success].
  static const Color successGreen = success;

  /// @deprecated Use [success].
  static const Color accentGreen = success;

  /// @deprecated Use [warning].
  static const Color borderPending = warning;

  /// @deprecated Use [danger].
  static const Color rejectRed = danger;
}
