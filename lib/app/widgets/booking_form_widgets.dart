import 'package:flutter/material.dart';

import 'app_colors.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "ມື້ນີ້" / "ມື້ອື່ນ" pill for today/tomorrow; null otherwise.
///
/// Shared by the teacher and student booking lists.
abstract class BookingDayBadge {
  static Widget? forDate(DateTime d) {
    final today = _dateOnly(DateTime.now());
    final target = _dateOnly(d);
    String? label;
    Color? color;
    if (_sameDate(target, today)) {
      label = 'ມື້ນີ້';
      color = AppColors.primaryFill;
    } else if (_sameDate(target, today.add(const Duration(days: 1)))) {
      label = 'ມື້ອື່ນ';
      color = AppColors.bookingBlue;
    }
    if (label == null || color == null) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Horizontal preset chips that fill the purpose field on tap.
///
/// Shared by the teacher and student "create booking" sheets.
class BookingPurposeChips extends StatelessWidget {
  /// Preset captions.
  final List<String> presets;

  /// Target purpose text field controller.
  final TextEditingController controller;

  const BookingPurposeChips({
    super.key,
    required this.presets,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final label = presets[i];
          return ActionChip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            onPressed: () => controller.text = label,
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

/// Red inline warning row under the booking form fields.
class BookingInlineWarning extends StatelessWidget {
  /// Warning body.
  final String message;

  /// Tint (defaults to danger red).
  final Color color;

  const BookingInlineWarning({
    super.key,
    required this.message,
    this.color = AppColors.danger,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// 24-hour time picker that writes "HH:mm" back into [target].
Future<void> pickTime24h(
  BuildContext context,
  TextEditingController target,
) async {
  final raw = target.text.trim();
  final parts = raw.split(':');
  final initial = TimeOfDay(
    hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 8,
    minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
  );
  final picked = await showTimePicker(
    context: context,
    initialTime: initial,
    builder: (ctx, child) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
      child: child ?? const SizedBox.shrink(),
    ),
  );
  if (picked == null) return;
  final hh = picked.hour.toString().padLeft(2, '0');
  final mm = picked.minute.toString().padLeft(2, '0');
  target.text = '$hh:$mm';
}
