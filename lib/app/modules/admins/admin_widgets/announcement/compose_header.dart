import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';

/// Top header row — title (with icon) on the left, history shortcut on the
/// right.
class ComposeHeader extends StatelessWidget {
  /// Tap callback for the history shortcut.
  final VoidCallback onHistory;

  const ComposeHeader({super.key, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.laoBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.laoBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'ສົ່ງການແຈ້ງເຕືອນ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          _HistoryShortcut(onTap: onHistory),
        ],
      ),
    );
  }
}

/// Indigo pill that opens the announcement history page.
class _HistoryShortcut extends StatelessWidget {
  /// Tap handler.
  final VoidCallback onTap;

  const _HistoryShortcut({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.laoBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, color: AppColors.laoBlue, size: 16),
            SizedBox(width: 4),
            Text(
              'ປະຫວັດ',
              style: TextStyle(
                fontSize: 12,
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
