/// 8-point spacing grid per design.txt §2.1.
///
/// Use these tokens (not raw numbers) for all margins, padding, and gaps so
/// the whole app maintains a single vertical rhythm. Within a group use
/// [xs]/[s]; between distinct sections use [xl]/[xxl].
class AppSpacing {
  AppSpacing._();

  /// 4 — micro gap, only inside a tightly-related row.
  static const double xs = 4;

  /// 8 — default gap inside a card / between label and field.
  static const double s = 8;

  /// 16 — default gap between siblings in a group.
  static const double m = 16;

  /// 24 — gap between distinct content blocks.
  static const double l = 24;

  /// 32 — gap between sections.
  static const double xl = 32;

  /// 48 — gap before a major content shift / hero break.
  static const double xxl = 48;

  /// Standard screen-edge horizontal margin (design.txt §2.1 says pick
  /// 16 *or* 24 and stay consistent — we pick 20 for an 8-pt-grid-friendly
  /// breathing room that's already in use across most existing views).
  static const double screenPadding = 20;

  /// Sticky bottom CTA spacing so the button doesn't kiss the safe-area.
  static const double bottomCtaInset = 16;
}
